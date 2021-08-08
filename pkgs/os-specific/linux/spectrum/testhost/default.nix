{ lib, runCommandNoCC, writeScript, writeScriptBin, writeShellScript, writeText
, coreutils, cloud-hypervisor, crosvm, curl, execline, gnutar, gnused, iproute
, iptables, jq, kmod, mktuntap, rsync, s6, s6-rc, sys-vms, utillinux
}:

let
  inherit (lib) concatStrings escapeShellArg makeBinPath mapAttrsToList
    optionalString;

  compose2 = f: g: a: b: f (g a b);

  concatMapAttrs = compose2 concatStrings mapAttrsToList;

  makeServicesDir = { services }:
    runCommandNoCC "services" {} ''
      mkdir $out
      ${concatMapAttrs (name: attrs: ''
        mkdir $out/${name}
        ${concatMapAttrs (key: value: ''
          cp -r ${value} $out/${name}/${key}
        '') attrs}
      '') services}
    '';

  s6RcCompile = { fdhuser ? null }: source:
    runCommandNoCC "s6-rc-compile" {} ''
      ${s6-rc}/bin/s6-rc-compile \
        ${optionalString (fdhuser != null) "-h ${escapeShellArg fdhuser}"} \
        dest ${source}
      tar -C dest -cf $out .
    '';

  compiledRcServicesDir = s6RcCompile {} (makeServicesDir {
    services = {
      vm-app = {
        run = writeScript "app-run" ''
          #! ${execline}/bin/execlineb -S0
          # fdclose 0

          # Checking the return value of the bridge creation is
          # important, because if it fails due to the bridge already
          # existing that means something else could already be using
          # this bridge.
          if { ip link add name br0 type bridge }
          if { ip link set br0 up }

          # Calculate the MACs for our TAP and the router's TAP.
          # MAC address format, by octet:
          #
          #  0-3  Static OUI for Spectrum
          #    4  Most significant bit is used to differentiate
          #       routers from clients.  Other bits are reserved.
          #  5-6  Last two octets of client's IP (in 100.64.0.0/16).
          #
          backtick -E router_mac {
            pipeline { printf %.4x ${toString sys-vms.app.vmID} }
            sed s/^\\(..\\)\\(..\\)$/0A:B3:EC:80:\\1:\\2/
          }
          backtick -E client_mac {
            pipeline { printf %.4x ${toString sys-vms.app.vmID} }
            sed s/^\\(..\\)\\(..\\)$/0A:B3:EC:00:\\1:\\2/
          }

          # Create the net VM end, and attach it to the net VM.
          #
          # Use a hardcoded name for now because if we use a dynamic
          # one iproute2 has no way of telling us the name that was
          # chosen:
          # https://lore.kernel.org/netdev/20210406134240.wwumpnrzfjbttnmd@eve.qyliss.net/
          define other_tap_name vmtapnet
          # Try to delete the device in case the VM was powered off
          # (as the finish script wouldn't have been run in that
          # case.)  Since we check the return value of ip tuntap add,
          # in the case of a race condition between deleting the
          # device and creating it again, we'll just fail and try
          # again.
          foreground { ip link delete $other_tap_name }
          if { ip tuntap add name $other_tap_name mode tap }
          if { ip link set $other_tap_name master br0 }
          if { ip link set $other_tap_name up }
          if {
            pipeline {
              jq -n "$ARGS.named"
                --arg tap $other_tap_name
                --arg mac $router_mac
            }
            curl -iX PUT
              -H "Accept: application/json"
              -H "Content-Type: application/json"
              --data-binary @-
              --unix-socket ../vm-net/env/cloud-hypervisor.sock
              http://localhost/api/v1/vm.add-net
          }

          mktuntap -pvBi vmtap%d 6
          importas -iu tap_name TUNTAP_NAME
          if { ip link set $tap_name master br0 }
          if { ip link set $tap_name up }
          if { iptables -t nat -A POSTROUTING -o $tap_name -j MASQUERADE }

          ${crosvm}/bin/crosvm run -p init=/sbin/init -p notifyport=''${port}
            # --serial type=file,path=/tmp/app.log
            --cid 4
            --tap-fd 6,mac=''${client_mac}
            --root ${sys-vms.app.rootfs.squashfs} ${sys-vms.app.linux}/bzImage
        '';
        finish = writeScript "app-finish" ''
          #! ${execline}/bin/execlineb -S0
          # TODO: remove from vm-net
          foreground { ip link delete vmtapnet }
          ip link delete br0
        '';
        type = writeText "app-type" ''
          longrun
        '';
        dependencies = writeText "app-dependencies" ''
          vm-net
        '';
      };

      vm-net = {
        run = writeScript "net-run" ''
          #! ${execline}/bin/execlineb -S0
          # This is only necessary for when running s6 from a tty.
          # (i.e. when debugging or running the demo).
          redirfd -w 0 /dev/null

          define PCI_LOCATION 0000:00:19.0
          define PCI_PATH /sys/bus/pci/devices/''${PCI_LOCATION}

          # Unbind the network device from the driver it's already
          # attached to, if any.
          foreground {
            redirfd -w 1 ''${PCI_PATH}/driver/unbind
            printf "%s" $PCI_LOCATION
          }

          # Tell the VFIO driver it should support our device.  This
          # is allowed to fail because it might already know that, in
          # which case it'll return EEXIST.
          if { modprobe vfio-pci }
          backtick -E device_id {
            if { dd bs=2 skip=1 count=2 status=none if=''${PCI_PATH}/vendor }
            if { printf " " }
            dd bs=2 skip=1 count=2 status=none if=''${PCI_PATH}/device
          }
          foreground {
            redirfd -w 1 /sys/bus/pci/drivers/vfio-pci/new_id
            printf "%s" $device_id
          }

          # Bind the device to the VFIO driver.  This is allowed to
          # fail because the new_id operation we just tried will have
          # bound it automatically for us if it succeeded.  In such a
          # case, the kernel will return ENODEV (conistency!).
          foreground {
            redirfd -w 1 /sys/bus/pci/drivers/vfio-pci/bind
            printf "%s" $PCI_LOCATION
          }

          # Because we allow both new_id and bind to fail, we need to
          # manually make sure now that at least one of them succeeded
          # and the device is actually attached to the vfio-driver.
          if { test -e /sys/bus/pci/drivers/vfio-pci/''${PCI_LOCATION} }

          foreground { mkdir env }

          ${cloud-hypervisor}/bin/cloud-hypervisor
            --api-socket env/cloud-hypervisor.sock
            --console off
            # --serial tty
            --cmdline "console=ttyS0 panic=30 root=/dev/vda"
            --device path=''${PCI_PATH}
            --disk path=${sys-vms.net.rootfs.squashfs},readonly=on
            --kernel ${sys-vms.net.linux.dev}/vmlinux
        '';
        type = writeText "net-type" ''
          longrun
        '';
      };
    };
  });

  servicesDir = makeServicesDir {
    services = {
      ".s6-svscan" = {
        finish = writeShellScript ".s6-svscan-finish" "";
      };
    };
  };
in

writeScriptBin "spectrum-testhost" ''
  #! ${execline}/bin/execlineb -S0
  export PATH ${makeBinPath [
    coreutils curl execline gnused gnutar iproute iptables jq kmod mktuntap rsync
    s6 s6-rc
  ]}

  if { redirfd -w 1 /proc/sys/net/ipv4/ip_forward echo 1 }

  importas -iu runtime_dir XDG_RUNTIME_DIR
  backtick -E top { mktemp -dp $runtime_dir spectrum.XXXXXXXXXX }
  if { echo $top }
  if { rsync -r --chmod=Du+w ${servicesDir}/ ''${top}/service }
  background {
    if { mkdir -p ''${top}/s6-rc/compiled }
    if { tar -C ''${top}/s6-rc/compiled -xf ${compiledRcServicesDir} }
    s6-rc-init -c ''${top}/s6-rc/compiled -l ''${top}/s6-rc/live ''${top}/service
  }
  s6-svscan ''${top}/service
''
