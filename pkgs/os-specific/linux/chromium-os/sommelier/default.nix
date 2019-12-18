{ common-mk, lib
, mesa, grpc, openssl, libdrm, xlibs, protobuf, wayland, libxkbcommon, vm_protos
, libbrillo, libchrome, linuxHeaders, c-ares, zlib
}:

common-mk {
  platformSubdir = "vm_tools/sommelier";

  platform2Patches = [
    ./0008-sommelier-don-t-leak-source-absolute-paths.patch
    ./0009-sommelier-use-stable-xdg-shell-protocol.patch
  ];

  buildInputs = [
    mesa grpc openssl libdrm protobuf wayland libxkbcommon vm_protos libbrillo
    libchrome linuxHeaders c-ares zlib
  ] ++ (with xlibs; [ pixman libxcb libX11 ]);

  NIX_CFLAGS_COMPILE = [
    "-Wno-error=sign-compare"
    "-Wno-error=class-memaccess"
    "-Wno-error=maybe-uninitialized"
  ];

  installPhase = ''
    mkdir -p $out/bin
    install sommelier wayland_demo x11_demo $out/bin
  '';

  meta = with lib; {
    description = "Nested Wayland compositor with support for X11 forwarding";
    maintainers = with maintainers; [ qyliss ];
  };
}
