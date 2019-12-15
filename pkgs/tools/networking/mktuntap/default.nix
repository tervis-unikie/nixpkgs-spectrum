{ stdenv, lib, fetchgit }:

stdenv.mkDerivation {
  pname = "mktuntap-unstable";
  version = "2019-12-15";

  src = fetchgit {
    url = "https://spectrum-os.org/git/mktuntap";
    rev = "d37b0ea1f794a4d195323b16484ecc4f04cc4306";
    sha256 = "17ygj3z91llkav5bclrd6cizqhrhpdjgfyyqhdxg8wwpcx8gs7xd";
  };

  installFlags = [ "prefix=$(out)" ];

  meta = with lib; {
    description = "Utility program for creating TAP and TUN devices";
    homepage = "https://spectrum-os.org/git/mktaptun";
    maintainers = with maintainers; [ qyliss ];
    license = licenses.gpl2;
    platform = platforms.linux;
  };
}
