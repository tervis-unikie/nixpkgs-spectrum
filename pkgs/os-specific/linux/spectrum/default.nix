{ newScope, linux_cros }:

let
  self = with self; {
    callPackage = newScope self;

    sys-vms = callPackage ./vm { };

    spectrum-vm = callPackage ./spectrum-vm { linux = linux_vm; };

    spectrum-testhost = callPackage ./testhost { };

    linux_vm = callPackage ./linux/vm.nix { linux = linux_cros; };

    makeRootfs = callPackage ./rootfs { };
  };
in
self
