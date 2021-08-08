{ lib, makeRootfs, runCommand, writeScript, writeText
, busybox, connman, dbus, execline, iptables, iproute, jq, linux_vm, mdevd
}:

runCommand "vm-net" rec {
  linux = linux_vm.override {
    structuredExtraConfig = with lib.kernel; {
      E1000E = yes;
      IGB = yes;
      PACKET = yes;

      IP_NF_NAT = yes;
      IP_NF_IPTABLES = yes;
      IP_NF_TARGET_MASQUERADE = yes;
      NF_CONNTRACK = yes;
    };
  };

  login = writeScript "login" ''
    #! ${execline}/bin/execlineb -s0
    unexport !
    ${busybox}/bin/login -p -f root $@
  '';

  rootfs = makeRootfs {
    rcServices.ok-all = {
      type = writeText "ok-all-type" ''
        bundle
      '';
      contents = writeText "ok-all-contents" ''
        mdevd-coldplug
      '';
    };

    rcServices.mdevd = {
      type = writeText "mdevd-type" ''
        longrun
      '';
      run = writeScript "mdevd-run" ''
        #! ${execline}/bin/execlineb -P
        ${mdevd}/bin/mdevd -D3 -f ${writeText "mdevd.conf" ''
          $INTERFACE=.* 0:0 660 ! @${writeScript "interface" ''
            #! ${execline}/bin/execlineb -S0

            multisubstitute {
              importas -i DEVPATH DEVPATH
              importas -i INTERFACE INTERFACE
            }

            ifte

            {
              # This interface is connected to another VM.

              # Our IP is encoded in the NIC-specific portion of the
              # interface's MAC address.
              backtick -E CLIENT_IP {
                pipeline { ip -j link show $INTERFACE }
                pipeline { jq -r ".[0].address | split(\":\") | .[4:6] | \"0x\" + .[]" }
                xargs printf "100.64.%d.%d"
              }

              if { ip address add 169.254.0.1/32 dev $INTERFACE }
              if { ip link set $INTERFACE up }
              ip route add $CLIENT_IP dev $INTERFACE
            }

            {
              if { test $INTERFACE != lo }
              # This is a physical connection to a network device.
              if { iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE }
              s6-rc -u change connman
            }

            grep -iq ^0A:B3:EC: /sys/class/net/''${INTERFACE}/address
          ''}
        ''}
      '';
      notification-fd = writeText "mdevd-notification-fd" ''
        3
      '';
      dependencies = writeText "mdevd-dependencies" ''
        sysctl
      '';
    };

    rcServices.mdevd-coldplug = {
      type = writeText "mdevd-coldplug-type" ''
        oneshot
      '';
      up = writeText "mdevd-run" ''
        ${mdevd}/bin/mdevd-coldplug
      '';
      dependencies = writeText "mdevd-coldplug-dependencies" ''
        mdevd
      '';
    };

    rcServices.dbus = {
      type = writeText "dbus-daemon" ''
        longrun
      '';
      run = writeScript "dbus-daemon-run" ''
        #! ${execline}/bin/execlineb -S0
        foreground { mkdir /run/dbus }
        # Busybox cp doesn't have -n to avoid copying to paths that
        # already exist, but we can abuse -u for the same effect,
        # since every file in the store is from Jan 1 1970.
        foreground { cp -u ${dbus}/libexec/dbus-daemon-launch-helper /run }
        foreground { chgrp messagebus /run/dbus-daemon-launch-helper }
        foreground { chmod 4550 /run/dbus-daemon-launch-helper }
        ${dbus}/bin/dbus-daemon
          --nofork --nosyslog --nopidfile --config-file=/etc/dbus-1/system.conf
      '';
    };

    rcServices.connman = {
      type = writeText "connman-type" ''
        longrun
      '';
      run = writeScript "connman-run" ''
        #! ${execline}/bin/execlineb -S0
        backtick -E HARDWARE_INTERFACES {
          pipeline {
            find -L /sys/class/net -mindepth 2 -maxdepth 2 -name address -print0
          }

          # Filter out other VMs and the loopback device.
          pipeline { xargs -0 grep -iL ^\\(0A:B3:EC:\\|00:00:00:00:00:00$\\) }

          # Extract the interface names from the address file paths.
          awk -F/ "{if (NR > 1) printf \",\"; printf \"%s\", $5}"
        }

        ${connman}/bin/connmand -ni $HARDWARE_INTERFACES
      '';
      dependencies = writeText "connman-dependencies" ''
        dbus
      '';
    };

    rcServices.sysctl = {
      type = writeText "sysctl-type" ''
        oneshot
      '';
      up = writeText "sysctl-up" ''
        redirfd -w 1 /proc/sys/net/ipv4/ip_forward
        echo 1
      '';
    };

    services.getty.run = writeScript "getty-run" ''
      #! ${execline}/bin/execlineb -P
      ${busybox}/bin/getty -i -n -l ${login} 38400 ttyS0
    '';

    path = [ iproute iptables jq ];
  };

  inherit (rootfs) squashfs;
} ''
  mkdir $out
  ln -s $linux/bzImage $out/kernel
  ln -s $squashfs $out/squashfs
''
