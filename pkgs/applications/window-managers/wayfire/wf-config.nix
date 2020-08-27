{ stdenv, lib, fetchurl, meson, ninja, pkg-config, glm, libevdev, libxml2 }:

stdenv.mkDerivation rec {
  pname = "wf-config";
  version = "0.5.0";

  src = fetchurl {
    url = "https://github.com/WayfireWM/wf-config/releases/download/0.5.0/wf-config-0.5.0.tar.xz";
    sha256 = "0xbvfy31pl6mj0nac921gqksyh6jb8ccap30p94lw6r6fb17wz57";
  };

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ libevdev libxml2 ];
  propagatedBuildInputs = [ glm ];

  meta = with lib; {
    homepage = "https://github.com/WayfireWM/wf-config";
    description = "Library for managing configuration files, written for Wayfire";
    license = licenses.mit;
    maintainers = with maintainers; [ qyliss wucke13 ];
    platforms = platforms.unix;
  };
}
