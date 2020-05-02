{ stdenv, lib, fetchFromGitHub, fetchpatch, meson, ninja, pkg-config, git
, cairo, libdrm, libexecinfo, libinput, libjpeg, libxkbcommon, wayland
, wayland-protocols, wf-config, wlroots
}:

stdenv.mkDerivation rec {
  pname = "wayfire";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "WayfireWM";
    repo = "wayfire";
    rev = version;
    sha256 = "01rfkb7m1b4d0a9ph9c9jzaa7q6xa91i2ygd3xcnkz35b35qcxn2";
  };

  patches = [
    # Fix gles32 support with Nixpkgs' LibGL's glesv2.pc.  Can be
    # removed if <https://github.com/WayfireWM/wayfire/pull/496> is
    # applied upstream.
    (fetchpatch {
      url = "https://github.com/WayfireWM/wayfire/commit/ca3c74d9f472e929bee45a89e40fe6351e9d0bf5.patch";
      sha256 = "0jl36z1n0vs4dzsxxp4n1wzlzcasm5hy12dpnr3c9gzwlvns3wk9";
    })

    # The following three patches add support for plugins installed
    # outside of Wayfire's prefix.  Without these, Wayfire plugins
    # would all have to be built in this derivation.  All three
    # patches can be removed if
    # <https://github.com/WayfireWM/wayfire/pull/497> is applied
    # upstream.
    (fetchpatch {
      url = "https://github.com/WayfireWM/wayfire/commit/b9a456c8304546bfb66a9474a47937180b2d2555.patch";
      sha256 = "1l6vsch5n8h6830bisnzdfjjrvp3q9hqml3hzb5d99lrmc3zcld8";
    })
    (fetchpatch {
      url = "https://github.com/WayfireWM/wayfire/commit/4bc39424688b8919311bc7ceee9eae2374e4d521.patch";
      excludes = [ "subprojects/wf-config" ];
      sha256 = "1cqhzbqlwlz0gv5239bx29yfjfmfv0lwyb3qx4wcnwxc3f70vr64";
    })
    (fetchpatch {
      url = "https://github.com/WayfireWM/wayfire/commit/39096c8b544d06addf88234a16a93f9a2aada07c.patch";
      sha256 = "0in6mcx045grbdxwzgckhyfvffq7xs5k1n3pij6fxh9ckjylpx5k";
    })
  ];

  strictDeps = true;
  nativeBuildInputs = [ meson ninja pkg-config wayland git ];
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
