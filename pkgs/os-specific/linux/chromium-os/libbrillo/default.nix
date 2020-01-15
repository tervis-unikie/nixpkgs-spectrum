{ common-mk, lib
, dbus_cplusplus, go-protobuf, protofiles, dbus-interfaces
, libchrome, curl, minijail, protobuf, glib, gtest, modp_b64
}:

common-mk {
  platformSubdir = "libbrillo";

  platform2Patches = [
    ./0003-libbrillo-Use-a-unique_ptr-for-EVP_MD_CTX.patch
    ./0004-libbrillo-Update-for-OpenSSL-1.1.patch
    ./0005-libbrillo-fix-build-with-relative-platform2_root.patch
    ./0006-libbrillo-don-t-leak-source-absolute-paths.patch
    ./0007-libbrillo-fix-build-with-no-__has_feature.patch
  ];

  nativeBuildInputs = [ dbus_cplusplus go-protobuf ];
  buildInputs = [ libchrome curl minijail protobuf glib gtest modp_b64 ];

  NIX_CFLAGS_COMPILE = [
    "-Wno-error=sign-compare"
    "-Wno-error=stringop-truncation"
  ];

  postPatch = ''
    substituteInPlace common-mk/external_dependencies/BUILD.gn \
        --replace '"''${sysroot}/usr/share/policy_tools"' '"${protofiles}/share/policy_tools"' \
        --replace '"''${sysroot}/usr/share/policy_resources"' '"${protofiles}/share/policy_resources"' \
        --replace '"''${sysroot}/usr/share/dbus-1/interfaces/"' '"${dbus-interfaces}/share/dbus-1/interfaces/"' \
        --replace '"''${sysroot}/usr/include/proto"' '"${protofiles}/include/proto"' \
        --replace '"''${sysroot}/usr/share/protofiles"' '"${protofiles}/share/protofiles"'
  '';

  installPhase = ''
    mkdir -p $out/lib/pkgconfig $out/include/install_attributes

    install lib/*.so $out/lib
    install libbrillo*.a $out/lib
    install -m 0644 obj/libbrillo/*.pc $out/lib/pkgconfig

    pushd ../../libbrillo
    find brillo policy -name '*.h' -print0 \
        | xargs -t -0 tar -c \
        | tar -C $out/include -x
    install -m 0644 install_attributes/libinstallattributes.h \
        $out/include/install_attributes
    popd
  '';

  meta = with lib; {
    description = "Chromium OS utility library";
    maintainers = with maintainers; [ qyliss ];
  };
}
