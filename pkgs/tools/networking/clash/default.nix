{ lib, fetchFromGitHub, buildGoModule, testers, clash }:

buildGoModule rec {
  pname = "clash";
  version = "1.10.6";

  src = fetchFromGitHub {
    owner = "Dreamacro";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-v9MUMgHIpHDUEmB5vXOIOkSriX+PCPtiiHHB4H5FeMw=";
  };

  vendorSha256 = "sha256-egbXCRmC862tctapMUWTcNej1g6a9wCt2JIC9DSEP6k=";

  # Do not build testing suit
  excludedPackages = [ "./test" ];

  CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/Dreamacro/clash/constant.Version=${version}"
  ];

  passthru.tests.version = testers.testVersion {
    package = clash;
    command = "clash -v";
  };

  meta = with lib; {
    description = "A rule-based tunnel in Go";
    homepage = "https://github.com/Dreamacro/clash";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ contrun Br1ght0ne ];
  };
}
