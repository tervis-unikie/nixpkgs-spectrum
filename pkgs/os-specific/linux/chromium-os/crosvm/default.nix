{ stdenv, lib, rustPlatform, fetchFromGitiles, upstreamInfo
, pkg-config, minigbm, minijail, wayland, wayland-protocols, dtc, libusb1
, libcap, linux
}:

let
  arch = with stdenv.hostPlatform;
    if isAarch64 then "arm"
    else if isx86_64 then "x86_64"
    else throw "no seccomp policy files available for host platform";

  getSrc = path: fetchFromGitiles upstreamInfo.components.${path};
  srcs = lib.genAttrs [
    "src/aosp/external/minijail"
    "src/platform/crosvm"
    "src/platform2"
    "src/third_party/adhd"
    "src/third_party/rust-vmm/vhost"
  ] getSrc;
in

  rustPlatform.buildRustPackage rec {
    pname = "crosvm";
    inherit (upstreamInfo) version;

    unpackPhase = ''
      runHook preUnpack

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (path: src: ''
        mkdir -p ${dirOf path}
        pushd ${dirOf path}
        unpackFile ${src}
        popd
      '') srcs)}

      chmod -R u+w -- "$sourceRoot"

      runHook postUnpack
    '';

    sourceRoot = "src/platform/crosvm";

    patches = [
      ./default-seccomp-policy-dir.diff
      ./VIRTIO_NET_F_MAC.patch
    ];

    cargoSha256 = "1yhxw19niqwipi1fbrskrpvhs915lrs8sdcpknmqd9izq67r3a06";

    nativeBuildInputs = [ pkg-config wayland ];

    buildInputs = [ dtc libcap libusb1 minigbm minijail wayland wayland-protocols ];

    postPatch = ''
      sed -i "s|/usr/share/policy/crosvm/|$out/share/policy/|g" \
             seccomp/*/*.policy
    '';

    preBuild = ''
      export DEFAULT_SECCOMP_POLICY_DIR=$out/share/policy
    '';

    postInstall = ''
      mkdir -p $out/share/policy/
      cp seccomp/${arch}/* $out/share/policy/
    '';

    CROSVM_CARGO_TEST_KERNEL_BINARY =
      lib.optionalString (stdenv.buildPlatform == stdenv.hostPlatform)
        "${linux}/${stdenv.hostPlatform.linux-kernel.target}";

    passthru = {
      inherit srcs;
      src = srcs.${sourceRoot};
      updateScript = ../update.py;
    };

    meta = with lib; {
      description = "A secure virtual machine monitor for KVM";
      homepage = "https://chromium.googlesource.com/chromiumos/platform/crosvm/";
      maintainers = with maintainers; [ qyliss ];
      license = licenses.bsd3;
      platforms = [ "aarch64-linux" "x86_64-linux" ];
    };
  }
