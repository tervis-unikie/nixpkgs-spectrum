{ stdenv, lib, fetchFromGitiles, upstreamInfo, pkg-config, libdrm }:

stdenv.mkDerivation {
  name = "minigbm";
  inherit (upstreamInfo) version;

  src = fetchFromGitiles upstreamInfo.components."src/platform/minigbm";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libdrm ];

  patchPhase = ''
    substituteInPlace Makefile --replace /usr/include $out/include
  '';

  buildFlags = [ "ECHO=echo" "PKG_CONFIG=pkg-config" ];
  installFlags = [ "LIBDIR=$(out)/lib" ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "GBM implementation for Chromium";
    homepage = "https://chromium.googlesource.com/chromiumos/platform/minigbm/";
    maintainers = with maintainers; [ qyliss ];
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
