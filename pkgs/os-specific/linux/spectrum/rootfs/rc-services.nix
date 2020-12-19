{ runCommandNoCC, lib, s6-rc }:

{ services ? [] }:

let
  inherit (lib) concatStrings escapeShellArg mapAttrsToList optionalString;

  source = runCommandNoCC "s6-services-source" {} ''
    mkdir $out
    ${concatStrings (mapAttrsToList (name: attrs: ''
      mkdir $out/${name}
      ${concatStrings (mapAttrsToList (key: value: ''
        cp ${value} $out/${name}/${key}
      '') attrs)}
    '') services)}
  '';

  s6RcCompile = { fdhuser ? null }: source:
    runCommandNoCC "s6-rc-compile" {} ''
      ${s6-rc}/bin/s6-rc-compile \
        ${optionalString (fdhuser != null) "-h ${escapeShellArg fdhuser}"} \
        $out ${source}
    '';
in

s6RcCompile {} source
