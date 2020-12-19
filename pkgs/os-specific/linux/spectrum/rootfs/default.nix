{ writeScript, writeText, lib, makeRootfs
, busybox, execline, s6, sommelier, source-code-pro, wayfire, zsh
, gcc, emacs26-nox, westonLite
}:

let
  path = [
    zsh emacs26-nox gcc wayfire sommelier westonLite busybox s6 execline
  ];

  login = writeScript "login" ''
    #! ${execline}/bin/execlineb -s0
    unexport !
    ${busybox}/bin/login -p -f root $@
  '';

  # This can't be /etc/wayfire/defaults.ini because autostart entries
  # from that file aren't applied.
  wayfireConfig = writeText "wayfire-config" ''
    [core]
    xwayland = false

    [input]
    xkb_layout = us
    xkb_variant = dvorak

    [autostart]
    terminal = weston-terminal --shell $(command -v zsh)
  '';
in

makeRootfs {
  services.getty.run = writeScript "getty-run" ''
    #! ${execline}/bin/execlineb -P
    ${busybox}/bin/getty -i -n -l ${login} 38400 ttyS0
  '';

  rcServices.ok-all = {
    type = writeText "ok-all-type" ''
      bundle
    '';
    contents = writeText "ok-all-contents" ''
      wayfire
    '';
  };

  rcServices.wayfire = {
    type = writeText "wayfire-type" ''
      longrun
    '';
    run = writeScript "wayfire-run" ''
      #! ${execline}/bin/execlineb -S0

      s6-applyuidgid -u 1000 -g 1000

      export HOME /
      export PATH ${lib.makeBinPath path}
      export XDG_RUNTIME_DIR /run/user/1000

      ${sommelier}/bin/sommelier
      wayfire -c ${wayfireConfig}
    '';
    dependencies = writeText "wayfire-dependencies" ''
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
}
