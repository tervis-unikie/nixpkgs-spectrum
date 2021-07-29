{ modemmanager, lib, fetchFromGitiles, upstreamInfo
, autoreconfHook, autoconf-archive, gtk-doc, libqmi, libxslt
}:

(modemmanager.override { inherit libqmi; }).overrideAttrs (
  { pname, nativeBuildInputs ? [], passthru ? {}, meta ? {}, ... }:
  {
    pname = "${pname}-chromiumos-next-unstable";
    version = "2019-10-17";

    src = fetchFromGitiles
      upstreamInfo.components."src/third_party/modemmanager-next";

    nativeBuildInputs = nativeBuildInputs ++
      [ autoreconfHook autoconf-archive gtk-doc libxslt ];

    passthru = passthru // {
      updateScript = ../update.py;
    };

    meta = with lib; meta // {
      maintainers = with maintainers; [ qyliss ];
    };
  }
)
