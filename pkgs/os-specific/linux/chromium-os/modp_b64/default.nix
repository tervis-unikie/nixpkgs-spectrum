{ common-mk, lib, fetchFromGitiles, upstreamInfo }:

common-mk {
  platformSubdir = "modp_b64";

  src = fetchFromGitiles upstreamInfo.components."src/third_party/modp_b64";

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
