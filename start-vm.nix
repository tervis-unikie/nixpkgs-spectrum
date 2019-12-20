with import ./. {};

let
  makeSquashfs = (callPackage nixos/lib/make-squashfs.nix {}).override;

  kernel' = linux_cros;

  kernel = with import lib/kernel.nix { inherit lib; inherit (kernel') version; };
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

        rngd = {
          run = writeScript "rngd-run" ''
            #! ${execline}/bin/execlineb -P
            ${rng-tools}/bin/rngd -f -x pkcs11,rdrand
          '';
        } // services.rngd or {};

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

  makeStage1 = { run ? null }: writeScript "init-stage1" ''
    #! ${execline}/bin/execlineb -P
    export PATH ${lib.makeBinPath
      [ s6-linux-init s6-portable-utils s6-linux-utils s6 execline busybox ]}
    ${s6}/bin/s6-setsid -qb --
    umask 022
    if { s6-mount -t tmpfs -o mode=0755 tmpfs /run }
    if { s6-hiercopy /etc/service /run/service }
    emptyenv -p

    background {
      s6-setsid --
      if { s6-mkdir -p /run/user/0 /dev/pts /dev/shm }
      if { s6-mount -t devpts -o gid=4,mode=620 none /dev/pts }
      if { s6-mount -t tmpfs none /dev/shm }
      if { s6-mount -t proc none /proc }

      if { ip addr add 10.0.100.2/24 dev eth0 }
      if { ip link set eth0 up }

      export XDG_RUNTIME_DIR /run/user/0
      ${lib.optionalString (run != null) ''
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
  '';

  makeRootfs = { services, run ? null }: runCommand "rootfs" {} ''
    mkdir $out
    cd $out
    mkdir bin sbin dev etc proc run tmp
    ln -s ${dash}/bin/dash bin/sh
    ln -s ${makeStage1 { inherit run; }} sbin/init
    cp ${passwd} etc/passwd
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
        | ${squashfs-tools-ng}/bin/tar2sqfs $out
  '';

  makeVM =
    { name, services ? {}, run ? null, wayland ? false, tapFD ? null }:
    let
      rootfs = makeRootfs { inherit run services; };
    in writeShellScript name ''
      exec ${crosvm}/bin/crosvm run \
          ${lib.optionalString wayland
              "--wayland-sock $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"} \
          ${lib.optionalString (tapFD != null) "--tap-fd ${toString tapFD}"} \
          -p init=/sbin/init \
          --root ${makeRootSquashfs rootfs} \
          ${kernel}/bzImage
    '';

  waylandVM = makeVM {
    name = "wayland-vm";
    services.getty.run = writeScript "getty-run" ''
      #! ${execline}/bin/execlineb -P
      ${busybox}/bin/getty -i -n -l ${login} 38400 ttyS0
    '';
    run = ''
      ${sommelier}/bin/sommelier
      ${westonLite}/bin/weston-terminal --shell /bin/sh
    '';
    wayland = true;
    tapFD = 3;
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

  importas -iu tap_name TUNTAP_NAME
  if { ip addr add 10.0.100.1/24 dev $tap_name }
  if { ip link set $tap_name up }

  ${s6}/bin/s6-applyuidgid -u $uid -g $gid

  export XDG_RUNTIME_DIR $xdg_runtime_dir
  export WAYLAND_DISPLAY $wayland_display
  ${waylandVM}
''
