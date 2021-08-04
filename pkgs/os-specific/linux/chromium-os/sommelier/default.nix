{ common-mk, lib
, abseil-cpp, mesa, grpc, openssl, libdrm, xlibs, protobuf, wayland
, libxkbcommon, vm_protos, linuxHeaders, c-ares, zlib
}:

common-mk {
  platformSubdir = "vm_tools/sommelier";

  platform2Patches = [
    ./0005-sommelier-don-t-leak-source-absolute-paths.patch
    ./0006-Revert-Revert-vm_tools-sommelier-Switch-to-the-stabl.patch
  ];

  buildInputs = [
    abseil-cpp mesa grpc openssl libdrm protobuf wayland libxkbcommon vm_protos
    linuxHeaders c-ares zlib
  ] ++ (with xlibs; [ pixman libxcb libX11 ]);

  gnArgs.use_demos = false;

  NIX_CFLAGS_COMPILE = [
    "-Wno-error=sign-compare"
    "-Wno-error=stringop-truncation"
    "-Wno-error=class-memaccess"
    "-Wno-error=maybe-uninitialized"
  ];

  installPhase = ''
    mkdir -p $out/bin
    install sommelier $out/bin
  '';

  meta = with lib; {
    description = "Nested Wayland compositor with support for X11 forwarding";
    maintainers = with maintainers; [ qyliss ];
  };
}
