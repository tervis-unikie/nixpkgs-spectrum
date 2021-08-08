{ runCommand, writeScript, writeText, makeRootfs
, busybox, execline, linux_vm, jq, iproute
}:

runCommand "vm-app" rec {
  linux = linux_vm;

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
        net
      '';
    };

    rcServices.net = {
      type = writeText "net-type" ''
        oneshot
      '';
      up = writeText "net-up" ''
        backtick -E LOCAL_IP {
          pipeline { ip -j link show eth0 }
          pipeline { jq -r ".[0].address | split(\":\") | .[4:6] | \"0x\" + .[]" }
          xargs printf "100.64.%d.%d"
        }

        if { ip address add ''${LOCAL_IP}/32 dev eth0 }
        if { ip link set eth0 up }
        if { ip route add 169.254.0.1 dev eth0 }
        ip route add default via 169.254.0.1 dev eth0
      '';
    };

    services.getty.run = writeScript "getty-run" ''
      #! ${execline}/bin/execlineb -P
      ${busybox}/bin/getty -i -n -l ${login} 38400 ttyS0
    '';

    path = [ iproute jq ];
  };

  inherit (rootfs) squashfs;
  vmID = 0;
} ''
  mkdir $out
  echo "$vmID" > $out/vm-id
  ln -s $linux/bzImage $out/kernel
  ln -s $squashfs $out/squashfs
''
