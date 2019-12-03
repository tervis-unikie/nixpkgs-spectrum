{ common-mk, stdenv, lib, fetchFromGitiles, upstreamInfo
, glib, libevent, gmock, modp_b64, chromiumos-overlay
}:

let
  versionData = upstreamInfo.components."aosp/platform/external/libchrome";
in

common-mk rec {
  platformSubdir = "libchrome";
  inherit (versionData) version;

  src = fetchFromGitiles { inherit (versionData) name url rev sha256; };

  NIX_CFLAGS_COMPILE = [
    "-Wno-error=attributes"
    "-Wno-error=dangling-else"
    "-Wno-error=implicit-fallthrough"
    "-Wno-error=unused-function"
  ];

  buildInputs = [ glib libevent gmock modp_b64 ];

  patches = [
    ./0001-Don-t-leak-source-absolute-paths-to-subprocesses.patch
    "${chromiumos-overlay}/chromeos-base/libchrome/files/libchrome-462023-Introduce-ValueReferenceAdapter-for-gracef.patch"
    "${chromiumos-overlay}/chromeos-base/libchrome/files/libchrome-462023-libchrome-add-alias-from-base-Location-base-GetProgr.patch"
  ];

  postPatch = ''
    substituteInPlace libchrome/BUILD.gn \
        --replace '/usr/include/base-''${libbase_ver}' \
                  "$out/include/base-\''${libbase_ver}"
  '' + (if stdenv.cc.isClang then ''
    substituteInPlace libchrome/BUILD.gn \
        --replace '"-Xclang-only=-Wno-char-subscripts",' ""
  '' else ''
    substituteInPlace libchrome/BUILD.gn \
        --replace "-Xclang-only=" "" \
        --replace '"-Wno-deprecated-register",' ""
  '');

  installPhase = ''
    mkdir -p $out/lib/pkgconfig
    install lib/libbase*-$version.so $out/lib
    install obj/libchrome/libchrome*-$version.pc $out/lib/pkgconfig

    pushd ../../libchrome
    mkdir -p $out/include/base-$version
    find . -name '*.h' -print0 \
        | xargs -0 tar -c \
        | tar -C $out/include/base-$version -x
    popd
  '';

  meta = with lib; {
    description = "Chromium project utility library";
    license = licenses.bsd3;
    maintainers = with maintainers; [ qyliss ];
    platform = platforms.all;
  };
}
