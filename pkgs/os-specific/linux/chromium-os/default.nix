{ lib, newScope, fetchFromGitiles, symlinkJoin
, kernelPatches, libqmi, linux_5_4, makeLinuxHeaders, modemmanager
}:

let
  self = with self; {
    callPackage = newScope self;

    upstreamInfo = lib.importJSON ./upstream-info.json;

    chromiumos-overlay = (fetchFromGitiles
      upstreamInfo.components."src/third_party/chromiumos-overlay") // {
        passthru.updateScript = ./update.py;
      };

    common-mk = callPackage ./common-mk { };

    crosvm = callPackage ./crosvm { };

    dbus-properties = callPackage ./dbus-properties { };

    dbus-interfaces = symlinkJoin {
      name = "dbus-interfaces";
      paths = [ dbus-properties self.modemmanager modemmanager-next ];
      passthru.updateScript = ./update.py;
    };

    libqmi = callPackage ./libqmi {
      inherit libqmi;
    };

    linux_5_4 = callPackage ../kernel/linux-cros.nix {
      kernelPatches = linux_5_4.kernelPatches ++ (with kernelPatches; [
        virtwl_multiple_sockets
      ]);
    };

    linux = self.linux_5_4;

    linuxHeaders = (makeLinuxHeaders {
      inherit (linux) version src patches;
    });

    minigbm = callPackage ./minigbm { };

    modemmanager = callPackage ./modem-manager {
      inherit modemmanager;
    };

    modemmanager-next = callPackage ./modem-manager/next.nix {
      inherit modemmanager;
    };

    modp_b64 = callPackage ./modp_b64 { };

    protofiles = callPackage ./protofiles { };

    sommelier = callPackage ./sommelier { };

    vm_protos = callPackage ./vm_protos { };
  };

in self // (with self; {
  inherit (upstreamInfo) version;
})
