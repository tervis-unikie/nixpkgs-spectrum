{ writeScript, lib
, execline, s6, s6-portable-utils, s6-linux-utils, s6-linux-init, busybox, mesa
}:

{ run ? "true" }:

let
  path = [ s6 s6-portable-utils s6-linux-utils s6-linux-init busybox execline ];
in

writeScript "init-stage1" ''
  #! ${execline}/bin/execlineb -P
  export PATH ${lib.makeBinPath path}
  ${s6}/bin/s6-setsid -qb --

  importas -i spectrumcmd spectrumcmd

  umask 022
  if { s6-mount -t tmpfs -o mode=0755 tmpfs /run }
  if { s6-hiercopy /etc/service /run/service }
  emptyenv -p

  background {
    s6-setsid --
    if { s6-mkdir -p /run/user/0 /dev/pts /dev/shm }
    if { install -o user -g user -d /run/user/1000 }
    if { s6-mount -t devpts -o gid=4,mode=620 none /dev/pts }
    if { s6-mount -t tmpfs none /dev/shm }
    if { s6-mount -t proc none /proc }
    if { s6-ln -s ${mesa.drivers} /run/opengl-driver }

    export HOME /
    export XDG_RUNTIME_DIR /run/user/0
    foreground {
      ifelse { test -n $spectrumcmd }
        { pipeline { heredoc 0 $spectrumcmd base64 -d } /bin/sh }
        ${run}
    }
    importas -i ? ?
    if { s6-echo STATUS: $? }
    s6-svscanctl -6 /run/service
  }

  unexport !
  cd /run/service
  s6-svscan
''
