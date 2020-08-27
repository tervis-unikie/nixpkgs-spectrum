{ stdenv, lib, fetchurl, meson, ninja, pkg-config
, cairo, libdrm, libexecinfo, libinput, libjpeg, libxkbcommon, wayland
, wayland-protocols, wf-config, wlroots
}:

stdenv.mkDerivation rec {
  pname = "wayfire";
  version = "0.5.0";

  src = fetchurl {
    url = "https://github.com/WayfireWM/wayfire/releases/download/${version}/wayfire-${version}.tar.xz";
    sha256 = "1zispx756b3jvmiwli2vp92vkfyzv3zdkffw0bmzgryh7balsq58";
  };

  strictDeps = true;
  nativeBuildInputs = [ meson ninja pkg-config wayland ];
  buildInputs = [
    cairo libdrm libexecinfo libinput libjpeg libxkbcommon wayland
    wayland-protocols wf-config wlroots
  ];

  mesonFlags = [ "--sysconfdir" "/etc" ];

  meta = with lib; {
    homepage = "https://wayfire.org/";
    description = "3D wayland compositor";
    license = licenses.mit;
    maintainers = with maintainers; [ qyliss wucke13 ];
    platforms = platforms.unix;
  };
}
