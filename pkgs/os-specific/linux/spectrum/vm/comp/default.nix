{ lib, makeRootfs, runCommand, writeScript, writeText
, busybox, emacs-nox, execline, gcc, linux_vm, s6, sommelier, source-code-pro
, tinywl, westonLite, zsh
}:

runCommand "vm-comp" rec {
  linux = linux_vm;

  path = [
    busybox emacs-nox execline gcc s6 sommelier tinywl westonLite zsh
  ];

  login = writeScript "login" ''
    #! ${execline}/bin/execlineb -s0
    unexport !
    ${busybox}/bin/login -p -f root $@
  '';

  rootfs = makeRootfs {
    services.getty.run = writeScript "getty-run" ''
      #! ${execline}/bin/execlineb -P
      ${busybox}/bin/getty -i -n -l ${login} 38400 ttyS0
    '';

    rcServices.ok-all = {
      type = writeText "ok-all-type" ''
        bundle
      '';
      contents = writeText "ok-all-contents" ''
        compositor
      '';
    };

    rcServices.compositor = {
      type = writeText "compositor-type" ''
        longrun
      '';
      run = writeScript "compositor-run" ''
        #! ${execline}/bin/execlineb -S0

        s6-applyuidgid -u 1000 -g 1000

        export HOME /
        export PATH ${lib.makeBinPath path}
        export XDG_RUNTIME_DIR /run/user/1000
        export XKB_DEFAULT_LAYOUT dvorak

        ${sommelier}/bin/sommelier
        ${tinywl}/bin/tinywl -s "weston-terminal --shell $(command -v zsh)"
      '';
      dependencies = writeText "compositor-dependencies" ''
        wl0
      '';
    };

    rcServices.wl0 = {
      type = writeText "wl0-type" ''
        oneshot
      '';
      up = writeText "wl0-run" ''
        chown user /dev/wl0
      '';
    };

    fonts = [ source-code-pro ];
  };

  inherit (rootfs) squashfs;
} ''
  mkdir $out
  ln -s $linux/bzImage $out/kernel
  ln -s $squashfs $out/squashfs
''
