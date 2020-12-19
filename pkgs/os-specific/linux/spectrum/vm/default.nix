{ callPackage }:

{
  comp = callPackage ./comp { };

  net = callPackage ./net { };
}
