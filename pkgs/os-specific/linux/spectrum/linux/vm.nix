{ lib, linux }:

with lib.kernel;

linux.override {
  structuredExtraConfig = {
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
    NET_9P_VIRTIO = yes;
    "9P_FS" = yes;
  };
}
