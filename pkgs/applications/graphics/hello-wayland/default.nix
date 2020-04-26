{ stdenv, lib, fetchFromGitHub
, imagemagick, pkg-config, wayland, wayland-protocols
}:

stdenv.mkDerivation {
  pname = "hello-wayland-unstable";
  version = "2019-01-16";

  src = fetchFromGitHub {
    owner = "emersion";
    repo = "hello-wayland";
    rev = "6c2762e653d4f91b36ee443642b735aa48128a74";
    sha256 = "0qxkyn9w9v477gagcrs18vdzy1ffg8jgp2qsqgdf9rxkfs6m4f36";
  };

  nativeBuildInputs = [ imagemagick pkg-config ];
  buildInputs = [ wayland wayland-protocols ];

  installPhase = ''
    mkdir -p $out/bin
    install hello-wayland $out/bin
  '';

  meta = with lib; {
    description = "Hello world Wayland client";
    homepage = "https://github.com/emersion/hello-wayland";
    maintainers = with maintainers; [ qyliss ];
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
