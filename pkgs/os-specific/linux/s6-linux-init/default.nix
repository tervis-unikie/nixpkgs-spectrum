{ lib, skawarePackages }:

with skawarePackages;

buildPackage {
  pname = "s6-linux-init";
  version = "1.0.3.1";
  sha256 = "1yq2xnp41a1lqpjzvq5jawgy64jwaxalvjdnlvgdpi9bkicgasi1";

  description = "Automated /sbin/init creation for s6-based Linux systems";
  platforms = lib.platforms.linux;

  outputs = [ "bin" "dev" "doc" "out" ];

  configureFlags = [
    "--includedir=\${dev}/include"
    "--with-sysdeps=${skalibs.lib}/lib/skalibs/sysdeps"
    "--with-include=${skalibs.dev}/include"
    "--with-include=${s6.dev}/include"
    "--with-include=${execline.dev}/include"
    "--with-lib=${skalibs.lib}/lib"
    "--with-dynlib=${skalibs.lib}/lib"
    "--with-lib=${s6}/lib"
  ];

  postInstall = ''
    find . -type f -executable -delete
    rm lib*.a.*
    mv doc $doc/share/doc/s6-linux-init/html
  '';
}
