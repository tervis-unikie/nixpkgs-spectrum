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

  init = writeShellScript "init" ''
    set -xe
    ${coreutils}/bin/mkdir /dev/pts /dev/shm
    ${utillinux}/bin/mount -t tmpfs none /tmp
    ${utillinux}/bin/mount -t devpts -o gid=4,mode=620 none /dev/pts
    ${utillinux}/bin/mount -t tmpfs none /dev/shm
    export XDG_RUNTIME_DIR=/tmp
    ${sommelier}/bin/sommelier ${hello-wayland}/bin/hello-wayland
  '';

  rootfs = runCommand "rootfs" {} ''
    mkdir dev bin tmp
    ln -s ${dash}/bin/sh bin
    (cat ${writeReferencesToFile init}; printf "%s\n" bin dev tmp) | xargs tar -cP --hard-dereference | ${squashfs-tools-ng}/bin/tar2sqfs $out
  '';

in

writeShellScript "crosvm" ''
  set -x
  exec ${crosvm}/bin/crosvm run --wayland-sock=/run/user/1000/wayland-0 -p init=${init} --root=${rootfs} ${kernel}/bzImage
''
