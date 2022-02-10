{ lib
, stdenv
, fetchpatch
, installShellFiles
, ninja
, pkg-config
, python3
, substituteAll
}:

python3.pkgs.buildPythonApplication rec {
  pname = "meson";
  version = "0.60.3";

  src = python3.pkgs.fetchPypi {
    inherit pname version;
    hash = "sha256-h8pfqTWKAYZFKTkr1k4CcVjrlK/KfHdmsYZu8n7MuY4=";
  };

  patches = [
    # Upstream insists on not allowing bindir and other dir options
    # outside of prefix for some reason:
    # https://github.com/mesonbuild/meson/issues/2561
    # We remove the check so multiple outputs can work sanely.
    ./allow-dirs-outside-of-prefix.patch

    # Meson is currently inspecting fewer variables than autoconf does, which
    # makes it harder for us to use setup hooks, etc.  Taken from
    # https://github.com/mesonbuild/meson/pull/6827
    ./more-env-vars.patch

    # Unlike libtool, vanilla Meson does not pass any information
    # about the path library will be installed to to g-ir-scanner,
    # breaking the GIR when path other than ${!outputLib}/lib is used.
    # We patch Meson to add a --fallback-library-path argument with
    # library install_dir to g-ir-scanner.
    ./gir-fallback-path.patch

    # In common distributions, RPATH is only needed for internal libraries so
    # meson removes everything else. With Nix, the locations of libraries
    # are not as predictable, therefore we need to keep them in the RPATH.
    # At the moment we are keeping the paths starting with /nix/store.
    # https://github.com/NixOS/nixpkgs/issues/31222#issuecomment-365811634
    (substituteAll {
      src = ./fix-rpath.patch;
      inherit (builtins) storeDir;
    })

    # When Meson removes build_rpath from DT_RUNPATH entry, it just writes
    # the shorter NUL-terminated new rpath over the old one to reduce
    # the risk of potentially breaking the ELF files.
    # But this can cause much bigger problem for Nix as it can produce
    # cut-in-half-by-\0 store path references.
    # Let’s just clear the whole rpath and hope for the best.
    ./clear-old-rpath.patch

    # Patch out default boost search paths to avoid impure builds on
    # unsandboxed non-NixOS builds, see:
    # https://github.com/NixOS/nixpkgs/issues/86131#issuecomment-711051774
    ./boost-Do-not-add-system-paths-on-nix.patch

    # Meson tries to update ld.so.cache which breaks when the target architecture
    # differs from the build host's.
    ./do-not-update-ldconfig-cache.patch
  ];

  cpuFamily = with stdenv.targetPlatform;
    /**/ if isAarch32 then "arm"
    else if isAarch64 then "aarch64"
    else if isx86_32  then "x86"
    else if isx86_64  then "x86_64"
    else parsed.cpu.family + builtins.toString parsed.cpu.bits;

  crossFile = if stdenv.hostPlatform == stdenv.targetPlatform then null else
    builtins.toFile "cross-file.conf" ''
      [properties]
      needs_exe_wrapper = true

      [host_machine]
      system = '${stdenv.targetPlatform.parsed.kernel.name}'
      cpu_family = '${cpuFamily}'
      cpu = '${stdenv.targetPlatform.parsed.cpu.name}'
      endian = ${if stdenv.targetPlatform.isLittleEndian then "'little'" else "'big'"}

      [binaries]
      llvm-config = 'llvm-config-native'
    '';

  setupHook = substituteAll {
    src = ./setup-hook.sh;
    crossFlags = lib.optionalString (crossFile != null) "--cross-file=${crossFile}";
  };

  # Meson included tests since 0.45, however they fail in Nixpkgs because they
  # require a typical building environment (including C compiler and stuff).
  # Just for the sake of documentation, the next lines are maintained here.
  doCheck = false;
  checkInputs = [ ninja pkg-config ];
  checkPhase = ''
    python ./run_project_tests.py
  '';

  postFixup = ''
    pushd $out/bin
    # undo shell wrapper as meson tools are called with python
    for i in *; do
      mv ".$i-wrapped" "$i"
    done
    popd

    # Do not propagate Python
    rm $out/nix-support/propagated-build-inputs
  '';

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --zsh data/shell-completions/zsh/_meson
    installShellCompletion --bash data/shell-completions/bash/meson
  '';

  meta = with lib; {
    homepage = "https://mesonbuild.com";
    description = "An open source, fast and friendly build system made in Python";
    longDescription = ''
      Meson is an open source build system meant to be both extremely fast, and,
      even more importantly, as user friendly as possible.

      The main design point of Meson is that every moment a developer spends
      writing or debugging build definitions is a second wasted. So is every
      second spent waiting for the build system to actually start compiling
      code.
    '';
    license = licenses.asl20;
    maintainers = with maintainers; [ jtojnar mbe AndersonTorres ];
    inherit (python3.meta) platforms;
  };
}
# TODO: a more Nixpkgs-tailoired test suite
