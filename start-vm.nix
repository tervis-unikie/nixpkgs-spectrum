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
    ${utillinux}/bin/mount -t tmpfs none /tmp
    export XDG_RUNTIME_DIR=/tmp
    ${sommelier}/bin/sommelier ${coreutils}/bin/env WAYLAND_DEBUG=1 ${westonLite}/bin/weston-terminal
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
