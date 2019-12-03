{ runCommand, chromiumos-overlay }:

runCommand "dbus-properties" {
  passthru.updateScript = ../update.py;
} ''
  mkdir -p $out/share/dbus-1/interfaces
  cp ${chromiumos-overlay}/sys-apps/dbus/files/org.freedesktop.DBus.Properties.xml \
      $out/share/dbus-1/interfaces
''
