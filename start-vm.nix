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

  stage1 = writeScript "stage1" ''
    #! ${execline}/bin/execlineb -P
    importas -i PATH PATH
    export PATH ${lib.makeBinPath
      [ s6-linux-init s6-portable-utils s6-linux-utils s6 execline coreutils ]}
    ${s6}/bin/s6-setsid -qb --
    umask 022
    if { s6-mount -t tmpfs -o mode=0755 tmpfs /run }
    if { s6-mkdir -p /run/service/.s6-svscan }
    if { cp ${stage3} /run/service/.s6-svscan/finish }
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
      if { echo STATUS: $? }
      s6-svscanctl -6 /run/service
    }

    unexport !
    cd /run/service
    s6-svscan
  '';

  stage3 = writeScript "stage3" ''
    #! ${execline}/bin/execlineb -S0
    foreground { s6-nuke -th }
    s6-sleep -m -- 2000
    foreground { s6-nuke -k }
    wait { }
    s6-linux-init-hpr -fr
  '';

  rootfs = runCommand "rootfs" {} ''
    mkdir bin dev proc run tmp
    ln -s ${dash}/bin/sh bin

    (cat ${writeReferencesToFile stage1}; printf "%s\n" bin dev proc run tmp) \
         | xargs tar -cP --owner root:0 --group root:0 --hard-dereference \
         | ${squashfs-tools-ng}/bin/tar2sqfs $out
  '';

in

writeShellScript "crosvm" ''
  set -x
  exec ${crosvm}/bin/crosvm run --wayland-sock=$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY -p init=${stage1} --root=${rootfs} ${kernel}/bzImage
''
