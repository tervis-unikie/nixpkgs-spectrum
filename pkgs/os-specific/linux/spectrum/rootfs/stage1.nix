{ writeScript, lib
, execline, s6, s6-rc, s6-portable-utils, s6-linux-utils, s6-linux-init, busybox, mesa
, path ? []
}:

let
  path' = path ++ [
    s6 s6-rc s6-portable-utils s6-linux-utils s6-linux-init busybox execline
  ];
in

writeScript "init-stage1" ''
  #! ${execline}/bin/execlineb -P
  export PATH ${lib.makeBinPath path'}
  ${s6}/bin/s6-setsid -qb --

  umask 022
  if { s6-mount -t tmpfs -o mode=0755 tmpfs /run }
  if { s6-hiercopy /etc/service /run/service }
  emptyenv -p

  background {
    s6-setsid --

    if { s6-rc-init -c /etc/s6-rc /run/service }

    if { s6-mkdir -p /run/user/0 /dev/pts /dev/shm }
    if { install -o user -g user -d /run/user/1000 }
    if { s6-mount -t devpts -o gid=4,mode=620 none /dev/pts }
    if { s6-mount -t tmpfs none /dev/shm }
    if { s6-mount -t proc none /proc }
    if { s6-mount -t sysfs none /sys }
    if { s6-ln -s ${mesa.drivers} /run/opengl-driver }

    s6-rc change ok-all
  }

  unexport !
  cd /run/service
  s6-svscan
''
