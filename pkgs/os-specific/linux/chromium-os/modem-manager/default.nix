{ modemmanager, lib, fetchFromGitiles
, autoreconfHook, libtool, intltool, libxslt, dbus_glib, chromiumos-overlay
}:

modemmanager.overrideAttrs (
  { pname, nativeBuildInputs ? [], buildInputs ? [], postInstall ? "", meta ? {}
  , ... }:
  {
    pname = "${pname}-chromiumos-unstable";
    version = "2012-04-10";

    src = fetchFromGitiles {
      url = "https://chromium.googlesource.com/chromiumos/third_party/modemmanager";
      rev = "657324d1abfd446b0319e4c51bd30cf4967eccf4";
      sha256 = "12wlak8zx914zix4vv5a8sl0nyi58v7593h4gjchgv3i8ysgj9ah";
    };

    patches = [];

    nativeBuildInputs = nativeBuildInputs ++ [ autoreconfHook libtool intltool libxslt ];
    buildInputs = buildInputs ++ [ dbus_glib ];

    preAutoreconf = ''
      intltoolize
    '';

    NIX_CFLAGS_COMPILE = [ "-Wno-error" ];

    meta = with lib; meta // {
      maintainers = with maintainers; [ qyliss ];
    };
  }
)
