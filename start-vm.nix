with import ./. {};

let
  makeSquashfs = (callPackage nixos/lib/make-squashfs.nix {}).override;

  kernel' = linux_latest;

  kernel = with import lib/kernel.nix { inherit lib; inherit (kernel') version; };
    kernel'.override { structuredExtraConfig = {
                         VIRTIO_PCI = yes;
                         VIRTIO_BLK = yes;
                         SQUASHFS = yes;
                         DEVTMPFS_MOUNT = yes;
                       }; };

  init = "${hello}/bin/hello";

  rootfs = runCommand "rootfs" {} ''
    mkdir dev bin
    ln -s ${dash}/bin/sh bin
    (cat ${writeReferencesToFile init}; printf "%s\n" bin dev) | xargs tar -cP --hard-dereference | ${squashfs-tools-ng}/bin/tar2sqfs $out
  '';

in

writeShellScript "crosvm" ''
  set -x
  exec ${crosvm}/bin/crosvm run -p init=${init} --root=${rootfs} ${kernel}/bzImage
''
