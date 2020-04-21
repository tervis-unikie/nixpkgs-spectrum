{ runCommandNoCC, writeScript, writeReferencesToFile, makeFontsConf, lib
, dash, execline, s6, s6-portable-utils, s6-linux-utils, s6-linux-init, busybox
, mesa, squashfs-tools-ng
}:

{ services, run, fonts ? [], path ? [] }:

let
  makeStage1 = import ./stage1.nix {
    inherit writeScript lib
      execline s6 s6-portable-utils s6-linux-utils s6-linux-init busybox mesa;
  };

  makeServicesDir = import ./services.nix {
    inherit runCommandNoCC writeScript lib execline;
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

    mkdir bin sbin dev etc proc run tmp
    ln -s ${dash}/bin/dash bin/sh
    ln -s ${makeStage1 { inherit run; }} sbin/init
    cp ${./etc/passwd} etc/passwd
    cp ${./etc/group} etc/group

    mkdir etc/fonts
    ln -s ${fontsConf} etc/fonts/fonts.conf

    touch etc/login.defs
    cp -r ${makeServicesDir { inherit services; }} etc/service
  '';
in
rootfs
