{ runCommandNoCC, writeScript, writeReferencesToFile, makeFontsConf, lib
, dash, execline, s6, s6-rc, s6-portable-utils, s6-linux-utils, s6-linux-init, busybox
, mesa, squashfs-tools-ng
}:

{ services, rcServices ? {}, fonts ? [], path ? [] }:

let
  stage1 = import ./stage1.nix {
    inherit writeScript lib
      execline s6 s6-rc s6-portable-utils s6-linux-utils s6-linux-init busybox mesa
      path;
  };

  makeServicesDir = import ./services.nix {
    inherit runCommandNoCC writeScript lib execline;
  };

  makeRcServicesDir = import ./rc-services.nix {
    inherit runCommandNoCC lib s6-rc;
  };

  fontsConf = makeFontsConf { fontDirectories = fonts; };

  squashfs = runCommandNoCC "root-squashfs" {} ''
    cd ${rootfs}
    (
        grep -v ^${rootfs} ${writeReferencesToFile rootfs}
        printf "%s\n" *
    ) \
        | xargs tar -cP --owner root:0 --group root:0 --hard-dereference \
        | ${squashfs-tools-ng}/bin/tar2sqfs -c gzip -X level=1 $out
  '';

  rootfs = runCommandNoCC "rootfs" { passthru = { inherit squashfs; }; } ''
    mkdir $out
    cd $out

    mkdir bin sbin dev proc run sys tmp
    ln -s ${dash}/bin/dash bin/sh
    ln -s ${stage1} sbin/init
    cp -r ${./etc} etc
    chmod u+w etc

    mkdir etc/fonts
    ln -s ${fontsConf} etc/fonts/fonts.conf

    touch etc/login.defs
    cp -r ${makeServicesDir { inherit services; }} etc/service
    cp -r ${makeRcServicesDir { services = rcServices; }} etc/s6-rc
  '';
in
rootfs
