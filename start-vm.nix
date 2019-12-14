with import ./. {};

let
  makeSquashfs = (callPackage nixos/lib/make-squashfs.nix {}).override;

  kernel' = linux_cros;

  kernel = with import lib/kernel.nix { inherit lib; inherit (kernel') version; };
    kernel'.override { structuredExtraConfig = {
                         VIRTIO_PCI = yes;
                         VIRTIO_BLK = yes;
                         VIRTIO_WL = yes;
                         SQUASHFS = yes;
                         DEVTMPFS_MOUNT = yes;
                       }; };

  login = writeScript "login" ''
    #! ${execline}/bin/execlineb -s0
    unexport !
    ${busybox}/bin/login -p -f root $@
  '';

  services = {
    getty.run = writeScript "getty-run" ''
      #! ${execline}/bin/execlineb -P
      ${busybox}/bin/getty -i -n -l ${login} 38400 ttyS0
    '';

    ".s6-svscan".finish = writeScript "init-stage3" ''
      #! ${execline}/bin/execlineb -P
      foreground { s6-nuke -th }
      s6-sleep -m -- 2000
      foreground { s6-nuke -k }
      wait { }
      s6-linux-init-hpr -fr
    '';
  };

  servicesDir = with lib; runCommandNoCC "services" {} ''
    mkdir $out
    ${concatStrings (mapAttrsToList (name: attrs: ''
      mkdir $out/${name}
      ${concatStrings (mapAttrsToList (key: value: ''
        cp ${value} $out/${name}/${key}
      '') attrs)}
    '') services)}
  '';

  stage1 = writeScript "init-stage1" ''
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
      export XDG_RUNTIME_DIR /run/user/0
      foreground { ${sommelier}/bin/sommelier ${hello-wayland}/bin/hello-wayland }
      importas -i ? ?
      if { s6-echo STATUS: $? }
      s6-svscanctl -6 /run/service
    }

    unexport !
    cd /run/service
    s6-svscan
  '';

  passwd = writeText "passwd" ''
    root:x:0:0:System administrator:/:/bin/sh
  '';

  rootfs = runCommand "rootfs" {} ''
    mkdir $out
    cd $out
    mkdir bin sbin dev etc proc run tmp
    ln -s ${dash}/bin/dash bin/sh
    ln -s ${stage1} sbin/init
    cp ${passwd} etc/passwd
    touch etc/login.defs
    cp -r ${servicesDir} etc/service
  '';

  root-squashfs = runCommand "root-squashfs" {} ''
    cd ${rootfs}
    (
        grep -v ^${rootfs} ${writeReferencesToFile rootfs}
        printf "%s\n" *
    ) \
        | xargs tar -cP --owner root:0 --group root:0 --hard-dereference \
        | ${squashfs-tools-ng}/bin/tar2sqfs $out
  '';

in

writeShellScript "crosvm" ''
  set -x
  exec ${crosvm}/bin/crosvm run --wayland-sock=$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY -p init=/sbin/init --root=${root-squashfs} ${kernel}/bzImage
''
