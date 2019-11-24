{ common-mk, lib, fetchFromGitiles, upstreamInfo }:

common-mk {
  platformSubdir = "modp_b64";

  src = fetchFromGitiles upstreamInfo.components."aosp/platform/external/modp_b64";

  patches = [
    # We could just use the Makefile, but it's going to be removed in
    # the next release anyway so let's just get on the GN train early.
    ./0001-modp_b64-Fix-GN-build-and-add-fuzzers.patch
    ./0002-Use-regular-archives.patch
  ];

  installPhase = ''
    mkdir -p $out/lib
    install -m 0644 libmodp_b64.a $out/lib

    mkdir $out/include
    cp -r ../../modp_b64/modp_b64 $out/include
  '';

  meta = with lib; {
    description = "High performance base64 encoder/decoder";
    homepage = "https://github.com/client9/stringencoders";
    license = licenses.bsd3;
    maintainers = with maintainers; [ qyliss ];
    platform = platforms.all;
  };
}
