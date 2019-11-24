{ stdenv, lib, fetchFromGitiles, chromiumos-overlay, python2 }:

stdenv.mkDerivation rec {
  pname = "protofiles";
  version = "0.0.36";

  src = fetchFromGitiles {
    url = "https://chromium.googlesource.com/chromium/src/components/policy";
    rev = "72e354e16600a8999c85528147dcf762f31a4b78";
    sha256 = "11v7n8d0ma426ba3i6q82k0vj0m5l1hx49waffivplpn0c92bm94";
  };

  buildInputs = [ python2 ];

  installPhase = ''
    mkdir -p $out/include/proto $out/share/protofiles \
        $out/share/policy_resources $out/share/policy_tools

    install -m 0644 proto/*.proto $out/include/proto
    ln -s $out/include/proto/*.proto $out/share/protofiles
    install -m 0644 resources/policy_templates.json $out/share/policy_resources
    install -m 0644 ${chromiumos-overlay}/chromeos-base/protofiles/files/VERSION \
      $out/share/policy_resources

    install tools/generate_policy_source.py $out/share/policy_tools
  '';

  meta = with lib; {
    inherit (src.meta) homepage;
    license = licenses.bsd3;
    maintainers = with maintainers; [ qyliss ];
    platform = platforms.all;
  };
}
