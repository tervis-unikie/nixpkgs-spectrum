{ stdenv, lib, fetchFromGitHub, fetchpatch, meson, ninja, pkg-config
, glm, libevdev, libxml2
}:

stdenv.mkDerivation rec {
  pname = "wf-config";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "WayfireWM";
    repo = "wf-config";
    rev = version;
    sha256 = "0pb2v71x0dv9s96wi20d9bc9rlxzr85rba7vny6751j7frqr4xf7";
  };

  patches = [
    # Modify wf::config::build_configuration to allow plugins
    # installed outside of Wayfire's prefix.  Otherwise, we'd have to
    # build all Wayfire plugins in the wayfire derivation.  Remove if
    # <https://github.com/WayfireWM/wf-config/pull/25> is applied
    # upstream.
    (fetchpatch {
      url = "https://github.com/WayfireWM/wf-config/commit/36578282f774d71eb8ebcd2dfc9d923eb70ac637.patch";
      sha256 = "152744xgi9ha135r7qfyivdl5cgcp9kik224ncwqv9a480m7nwj6";
    })
  ];

  strictDeps = true;
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
