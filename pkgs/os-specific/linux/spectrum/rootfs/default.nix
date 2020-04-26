{ runCommandNoCC, writeScript, writeText, makeFontsConf, writeReferencesToFile
, lib, dash, busybox, execline, s6, s6-portable-utils, s6-linux-utils
, s6-linux-init, mesa, squashfs-tools-ng
, source-code-pro, zsh, emacs26-nox, gcc, sway-unwrapped, sommelier, westonLite
}:

let
  makeRootfs = import ./generic.nix {
    inherit runCommandNoCC writeScript writeReferencesToFile makeFontsConf lib
      dash execline s6 s6-portable-utils s6-linux-utils s6-linux-init busybox
      mesa squashfs-tools-ng;
  };

  path = [
    zsh emacs26-nox gcc sway-unwrapped sommelier westonLite busybox s6 execline
  ];

  login = writeScript "login" ''
    #! ${execline}/bin/execlineb -s0
    unexport !
    ${busybox}/bin/login -p -f root $@
  '';

  swayConfig = writeText "sway-config" ''
    xwayland disable
    input * xkb_layout dvorak

    exec weston-terminal --shell ${zsh}/bin/zsh
  '';
in

makeRootfs {
  services.getty.run = writeScript "getty-run" ''
    #! ${execline}/bin/execlineb -P
    ${busybox}/bin/getty -i -n -l ${login} 38400 ttyS0
  '';

  run = ''
    if { chown user /dev/wl0 }

    s6-applyuidgid -u 1000 -g 1000
    export XDG_RUNTIME_DIR /run/user/1000

    export PATH ${lib.makeBinPath path}

    ${sommelier}/bin/sommelier
    sway -Vc ${swayConfig}
  '';

  fonts = [ source-code-pro ];
}
