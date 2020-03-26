{ stdenv, lib, buildPackages, fetchFromGitiles, upstreamInfo, perl, buildLinux
, modDirVersionArg ? null
, ... } @ args:

let
  versionData = upstreamInfo.components."chromiumos/third_party/kernel";
in

with lib;
with lib.kernel;

buildLinux (args // rec {
  inherit (versionData) version;

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion =
    if modDirVersionArg == null
    then concatStringsSep "." (take 3 (splitVersion "${version}.0"))
    else modDirVersionArg;

  # branchVersion needs to be x.y
  extraMeta.branch = versions.majorMinor version;

  src = fetchFromGitiles { inherit (versionData) name url rev sha256; };

  updateScript = ../chromium-os/update.py;

  structuredExtraConfig = {
    # Enabling this (the default) caused a build failure.  If you can
    # archieve a successful build with this enabled, go ahead and
    # enable it.
    TCG_CR50_SPI = no;
  } // (args.structuredExtraConfig or {});
} // (args.argsOverride or {}))
