{ common-mk, lib, go-protobuf, grpc, openssl, protobuf }:

common-mk {
  pname = "vm_protos";
  platformSubdir = "vm_tools/proto";

  nativeBuildInputs = [ go-protobuf ];
  buildInputs = [ grpc openssl protobuf ];

  platform2Patches = [
    ./0003-common-mk-add-goproto_library-source_relative-opt.patch
    ./0004-vm_tools-proto-set-go_package-correctly.patch
  ];

  NIX_CFLAGS_COMPILE = [
    "-Wno-error=array-bounds"
    "-Wno-error=deprecated-declarations"
  ];

  postPatch = ''
    substituteInPlace common-mk/proto_library.gni \
        --replace /usr/bin/grpc_cpp_plugin ${grpc}/bin/grpc_cpp_plugin
  '';

  installPhase = ''
    mkdir -p $out/lib/pkgconfig
    install -m 644 ../../vm_tools/proto/vm_protos.pc $out/lib/pkgconfig

    headerPath=include/vm_protos/proto_bindings
    mkdir -p $out/$headerPath
    install -m 644 gen/$headerPath/*.h $out/$headerPath

    install -m 644 *.a $out/lib
  '';

  meta = with lib; {
    description = "Protobuf definitions for Chromium OS system VMs";
    maintainers = with maintainers; [ qyliss ];
    platform = platforms.all;
  };
}
