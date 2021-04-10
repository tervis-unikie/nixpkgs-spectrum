{ callPackage }:

{
  app = callPackage ./app { };

  comp = callPackage ./comp { };

  net = callPackage ./net { };
}
