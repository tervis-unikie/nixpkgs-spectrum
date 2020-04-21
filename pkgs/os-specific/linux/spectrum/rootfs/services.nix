{ runCommandNoCC, writeScript, lib, execline }:

{ services ? [] }:

let
  services' = {
    ".s6-svscan" = {
      finish = writeScript "init-stage3" ''
        #! ${execline}/bin/execlineb -P
        foreground { s6-nuke -th }
        s6-sleep -m -- 2000
        foreground { s6-nuke -k }
        wait { }
        s6-linux-init-hpr -fr
      '';
    } // services.".s6-svscan" or {};
  } // services;
in

runCommandNoCC "services" {} ''
  mkdir $out
  ${lib.concatStrings (lib.mapAttrsToList (name: attrs: ''
    mkdir $out/${name}
    ${lib.concatStrings (lib.mapAttrsToList (key: value: ''
      cp ${value} $out/${name}/${key}
    '') attrs)}
  '') services')}
''
