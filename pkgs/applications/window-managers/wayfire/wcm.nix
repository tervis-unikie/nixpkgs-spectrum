{ stdenv, lib, fetchFromGitHub, fetchpatch, meson, ninja, pkg-config, wayland
, gnome3, libevdev, libxml2, wayfire, wayland-protocols, wf-config, wf-shell
}:

stdenv.mkDerivation rec {
  pname = "wcm";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "WayfireWM";
    repo = "wcm";
    rev = "v${version}";
    sha256 = "0irypa0814nmsmi9s8wxwfs507w41g41zjv8dkp0fdhg0429zxwa";
  };

  patches = [
    # The following three patches add support for loading Wayfire
    # plugin metadata from outside of Wayfire's prefix.  Remove if
    # <https://github.com/WayfireWM/wcm/pull/18> is applied upstream.
    (fetchpatch {
      url = "https://github.com/WayfireWM/wcm/commit/8930ce96f51175947c42a605a520adc7282138ef.patch";
      sha256 = "10s3jikm99msxx73k6ccam8jlpdvvy379mifks4zmpfbag9ammrl";
    })
    (fetchpatch {
      url = "https://github.com/WayfireWM/wcm/commit/07dfe16bf83ca3389ddfa8b1f90afee0a8c16135.patch";
      sha256 = "1hgqzqpf2anyhfb1bl4v3n2vwsw0w7far651p7aisn9vr6iqbmls";
    })
    (fetchpatch {
      url = "https://github.com/WayfireWM/wcm/commit/0864c3d842ca1dfe6b2d25013941a7679d867458.patch";
      sha256 = "1z4zjl9al09wgb39gyc4g2ib5kkzppq37zla6ncmhmglis4l8arn";
    })
  ];

  strictDeps = true;
  nativeBuildInputs = [ meson ninja pkg-config wayland ];
  buildInputs = [
    gnome3.gtk libevdev libxml2 wayfire wayland wayland-protocols wf-config
    wf-shell
  ];

  meta = with lib; {
    homepage = "https://github.com/WayfireWM/wcm";
    description = "Wayfire Config Manager";
    license = licenses.mit;
    maintainers = with maintainers; [ qyliss wucke13 ];
    platforms = platforms.unix;
  };
}
