{ newScope, linux_cros }:

let
  self = with self; {
    callPackage = newScope self;

    spectrum-vm = callPackage ./spectrum-vm { linux = linux_vm; };

    linux_vm = callPackage ./linux/vm.nix { linux = linux_cros; };

    rootfs = callPackage ./rootfs { };
  };
in
self
