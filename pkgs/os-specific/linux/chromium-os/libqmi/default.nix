{ libqmi, lib, fetchFromGitiles, upstreamInfo
, autoreconfHook, autoconf-archive, gtk-doc, docbook-xsl-nons
}:

libqmi.overrideAttrs (
  { configureFlags ? [], nativeBuildInputs ? [], passthru ? {}, meta ? {}, ... }:
  {
    pname = "libqmi-unstable";
    version = "2019-12-16";

    src = fetchFromGitiles upstreamInfo.components."src/third_party/libqmi";

    nativeBuildInputs = nativeBuildInputs ++
      [ autoreconfHook autoconf-archive gtk-doc docbook-xsl-nons ];

    configureFlags = configureFlags ++ [ "--enable-gtk-doc" ];

    passthru = passthru // {
      updateScript = ../update.py;
    };

    meta = with lib; meta // {
      maintainers = with maintainers; [ qyliss ];
    };
  }
)
