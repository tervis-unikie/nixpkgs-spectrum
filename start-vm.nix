with import ./. {};

let
  kernel' = linux_cros;

  kernel = with lib.kernel;
    kernel'.override { structuredExtraConfig = {
                         VIRTIO_PCI = yes;
                         VIRTIO_BLK = yes;
                         VIRTIO_WL = yes;
                         VIRTIO_NET = yes;
                         DEVTMPFS_MOUNT = yes;
                         SQUASHFS = yes;

                         # VOP is needed to work around a Kconfig bug:
                         # https://lore.kernel.org/lkml/87wob4tf9b.fsf@alyssa.is/
                         VOP = yes;
                         VOP_BUS = yes;
                         HW_RANDOM = yes;
                         HW_RANDOM_VIRTIO = yes;

                         NET_9P = yes;
                         "9P_FS" = yes;
                       }; };

  login = writeScript "login" ''
    #! ${execline}/bin/execlineb -s0
    unexport !
    ${busybox}/bin/login -p -f root $@
  '';

  makeServicesDir = services: with lib;
    let
      services' = {

        ".s6-svscan" = {
          finish = writeScript "init-stage3" ''
            #! ${execline}/bin/execlineb -P
            foreground { s6-nuke -th }
            s6-sleep -m -- 2000
            foreground { s6-nuke -k }
            wait { }
            s6-linux-init-hpr -fr
          '';
        } // services.".s6-svscan" or {};
      } // services;

    in
      runCommandNoCC "services" {} ''
        mkdir $out
        ${concatStrings (mapAttrsToList (name: attrs: ''
          mkdir $out/${name}
          ${concatStrings (mapAttrsToList (key: value: ''
            cp ${value} $out/${name}/${key}
          '') attrs)}
        '') services')}
      '';

  makeStage1 = { run ? null, tapFD }: writeScript "init-stage1" ''
    #! ${execline}/bin/execlineb -P
    export PATH ${lib.makeBinPath
      [ s6-linux-init s6-portable-utils s6-linux-utils s6 execline busybox sway-unwrapped ]}
    ${s6}/bin/s6-setsid -qb --
    umask 022
    if { s6-mount -t tmpfs -o mode=0755 tmpfs /run }
    if { s6-hiercopy /etc/service /run/service }
    emptyenv -p

    background {
      s6-setsid --
      if { s6-mkdir -p /run/user/0 /dev/pts /dev/shm }
      if { install -o user -g user -d /run/user/1000 }
      if { s6-mount -t devpts -o gid=4,mode=620 none /dev/pts }
      if { s6-mount -t tmpfs none /dev/shm }
      if { s6-mount -t proc none /proc }
      if { s6-ln -s ${mesa.drivers} /run/opengl-driver }

      if { ip addr add 10.0.10${toString tapFD}.2/24 dev eth0 }
      if { ip link set eth0 up }
      ${lib.optionalString (run != null) "if {"}
          ip route add default via 10.0.10${toString tapFD}.1
      ${lib.optionalString (run != null) ''
        }
        export XDG_RUNTIME_DIR /run/user/0
        foreground { ${run} }
        importas -i ? ?
        if { s6-echo STATUS: $? }
        s6-svscanctl -6 /run/service
      ''}
    }

    unexport !
    cd /run/service
    s6-svscan
  '';

  passwd = writeText "passwd" ''
    root:x:0:0:System administrator:/:/bin/sh
    user:x:1000:1000:User:/:/bin/sh
  '';

  group = writeText "group" ''
    root:x:0:root
    user:x:1000:user
  '';

  makeRootfs = { services, run ? null, tapFD }: runCommand "rootfs" {} ''
    mkdir $out
    cd $out
    mkdir bin sbin dev etc proc run tmp
    ln -s ${dash}/bin/dash bin/sh
    ln -s ${makeStage1 { inherit run tapFD; }} sbin/init
    cp ${passwd} etc/passwd
    cp ${group} etc/group
    touch etc/login.defs
    cp -r ${makeServicesDir services} etc/service
  '';

  makeRootSquashfs = rootfs: runCommand "root-squashfs" {} ''
    cd ${rootfs}
    (
        grep -v ^${rootfs} ${writeReferencesToFile rootfs}
        printf "%s\n" *
    ) \
        | xargs tar -cP --owner root:0 --group root:0 --hard-dereference \
        | ${squashfs-tools-ng}/bin/tar2sqfs -c gzip -X level=1 $out
  '';

  makeVM =
    { name, services ? {}, run ? null, wayland ? false, tapFD ? null }:
    let
      rootfs = makeRootfs { inherit run services tapFD; };
    in writeShellScript name ''
      exec ${crosvm}/bin/crosvm run \
          ${lib.optionalString wayland
              "--wayland-sock $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"} \
          ${lib.optionalString (tapFD != null) "--tap-fd ${toString tapFD}"} \
          -p init=/sbin/init \
          --root ${makeRootSquashfs rootfs} \
          ${kernel}/bzImage
    '';

  fsVM = makeVM {
    name = "fs-vm";
    tapFD = 3;

    services.unpfs.run = writeScript "unpfs-run" ''
      #! ${execline}/bin/execlineb -P
      ${unpfs}/bin/unpfs tcp!0.0.0.0!564 /
    '';
  };

  swayConfig = writeText "sway-config" ''
    xwayland disable
    exec ${westonLite}/bin/weston-terminal --shell /bin/sh
  '';

  waylandVM = makeVM {
    name = "wayland-vm";
    services.getty.run = writeScript "getty-run" ''
      #! ${execline}/bin/execlineb -P
      ${busybox}/bin/getty -i -n -l ${login} 38400 ttyS0
    '';
    run = ''
      background {
        if { s6-mkdir /run/mnt }
        loopwhilex
        if -n { s6-mount -t 9p 10.0.103.2 /run/mnt }
        s6-sleep 1
      }

      if { chown user /dev/wl0 }

      ${s6}/bin/s6-applyuidgid -u 1000 -g 1000
      env XDG_RUNTIME_DIR=/run/user/1000

      ${sommelier}/bin/sommelier
      ${sway-unwrapped}/bin/sway -Vc ${swayConfig}
    '';
    wayland = true;
    tapFD = 4;
  };

in

writeScript "crosvm" ''
  #! ${execline}/bin/execlineb -P

  importas -i xdg_runtime_dir XDG_RUNTIME_DIR
  importas -i wayland_display WAYLAND_DISPLAY

  sudo

  importas -i uid SUDO_UID
  importas -i gid SUDO_GID

  ${mktuntap}/bin/mktuntap -pvB 3
  importas -iu tap_name_3 TUNTAP_NAME

  ${mktuntap}/bin/mktuntap -pvB 4
  importas -iu tap_name_4 TUNTAP_NAME

  if { ip addr add 10.0.103.1/24 dev $tap_name_3 }
  if { ip addr add 10.0.104.1/24 dev $tap_name_4 }
  if { ip link set $tap_name_3 up }
  if { ip link set $tap_name_4 up }

  ${s6}/bin/s6-applyuidgid -u $uid -g $gid

  export XDG_RUNTIME_DIR $xdg_runtime_dir
  export WAYLAND_DISPLAY $wayland_display

  background { ${fsVM} }
  ${waylandVM}
''
