{ stdenv, lib, fetchFromGitiles, upstreamInfo, gn, pkgconfig, python3, ninja
# , libchrome
}:

{ platformSubdir

# Mandatory, unlike in mkDerivation, because Google doesn't provide
# install tasks and just does that in their ebuilds.
, installPhase

# src allows an out-of-tree (i.e., out-of-platform2) package to be
# built with common-mk.  patches will be applied to `src` -- to patch
# platform2 itself use platform2Patches.
, src ? null, platform2Patches ? []

# gnArgs allows structured data (attribute sets) to be serialized and
# passed to gn, unlike gnFlags provided by gn's setupHook, which is a
# flat list of strings.
, gnArgs ? {}, gnFlags ? [], use ? {}

, postUnpack ? "", prePatch ? "", postPatch ? ""
, nativeBuildInputs ? []
, meta ? {}
, ... } @ args:

let
  platform2 = fetchFromGitiles upstreamInfo.components."src/platform2";

  attrsToGnList = lib.mapAttrsToList (name: value: "${name}=${toGn value}");

  toGn = value:
    if lib.isAttrs value then
      "{${lib.concatStringsSep " " (attrsToGnList value)}}"
    else
      builtins.toJSON value;
in

stdenv.mkDerivation ({
  pname = lib.last (lib.splitString "/" platformSubdir);
  inherit (upstreamInfo) version;

  srcs = [ platform2 ] ++ lib.optional (src != null) src;
  sourceRoot = "platform2";

  postUnpack = lib.optionalString (src != null) ''
    ln -s ../${src.name} $sourceRoot/${platformSubdir}
    chmod -R +w ${src.name}
  '' + postUnpack;

  prePatch = ''
    pushd ${platformSubdir}
  '' + prePatch;

  postPatch = ''
    popd
    ${lib.concatMapStrings (patch: ''
      echo applying patch ${patch}
      patch -p1 < ${patch} 
    '') ([
      ./0001-common-mk-don-t-leak-source-absolute-paths.patch
      ./0002-common-mk-.gn-don-t-hardcode-env-path.patch
      ./0003-Revert-common-mk-Suppress-Wrange-loop-analysis-warni.patch
    ] ++ platform2Patches)}

    patchShebangs common-mk
  '' + (lib.optionalString (!stdenv.cc.isClang) ''
    substituteInPlace common-mk/BUILD.gn \
        --replace '"-Wno-c99-designator",' ""
  '') + postPatch;

  nativeBuildInputs = [ gn pkgconfig python3 ninja ] ++ nativeBuildInputs;

  gnFlags = (attrsToGnList ({
    ar = "ar";
    cc = "cc";
    cxx = "c++";
    # libbase_ver = libchrome.version;
    libdir = placeholder "out";
    pkg_config = "pkg-config";
    platform2_root = ".";
    platform_subdir = platformSubdir;
    use = {
      amd64 = stdenv.targetPlatform.isx86_64;
      arm = stdenv.targetPlatform.isAarch32 || stdenv.targetPlatform.isAarch64;
      asan = false;
      coverage = false;
      cros_host = false;
      crypto = false;
      dbus = false;
      device_mapper = false;
      fuzzer = false;
      mojo = false;
      profiling = false;
      tcmalloc = false;
      test = false;
      timers = false;
      udev = false;
    } // use;
  } // gnArgs)) ++ gnFlags;

  passthru.updateScript = ../update.py;

  meta = {
    homepage =
      if src == null then
        "${platform2.meta.homepage}/+/HEAD/${platformSubdir}"
      else
        src.meta.homepage;
    platform = lib.platforms.linux;
  } // lib.optionalAttrs (src == null) {
    license = lib.licenses.bsd3;
  } // meta;
} // (builtins.removeAttrs args [
  "src"
  "gnArgs" "gnFlags" "use"
  "postUnpack" "prePatch" "postPatch"
  "nativeBuildInputs"
  "meta"
]))
