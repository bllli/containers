#!/bin/bash

#init timezone
# test -f /usr/share/zoneinfo/${TZ} && \
# ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
# echo "${TZ}" >  /etc/timezone && \
# echo "init TZ: ${TZ}"

echo "current time: `date`"

if [ "$(id -u)x" != "0x" ]; then
    echo "err: you must run the container as root."
    echo "you can specific the PUID and PGID if you want the app run as specific user."
    exit 1
fi

PUID=${PUID:-1000}
PGID=${PGID:-100}

groupmod -o -g "$PGID" app
usermod -o -u "$PUID" app

echo '
-------------------------------------
                                    __        __
   ____   ___   _  __ __  __ _____ / /____ _ / /_
  / __ \ / _ \ | |/_// / / // ___// // __ `// __ \
 / / / //  __/_>  < / /_/ /(__  )/ // /_/ // /_/ /
/_/ /_/ \___//_/|_| \__,_//____//_/ \__,_//_.___/


Brought to you by nexuslab
We gratefully accept donations at:
https://nexuslab.dev/donate
-------------------------------------
GID/UID
-------------------------------------'
echo "
User uid:    $(id -u app)
User gid:    $(id -g app)
-------------------------------------
"

exec /bin/s6-svscan -t0 /etc/svc.d
