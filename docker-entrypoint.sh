#!/bin/bash

if [ ! -z "${AFP_USER}" ]; then
    if [ ! -z "${AFP_UID}" ]; then
        cmd="$cmd --uid ${AFP_UID}"
    fi
    if [ ! -z "${AFP_GID}" ]; then
        cmd="$cmd --gid ${AFP_GID}"
        groupadd --gid ${AFP_GID} ${AFP_USER}
    fi
    adduser $cmd --no-create-home --disabled-password --gecos '' "${AFP_USER}"
    if [ ! -z "${AFP_PASSWORD}" ]; then
        echo "${AFP_USER}:${AFP_PASSWORD}" | chpasswd
    fi
fi

if [ ! -d /media/timemachine ]; then
  mkdir /media/timemachine
  echo "use -v /my/dir/to/timemachine:/media/timemachine" > readme.txt
fi
chown "${AFP_USER}" /media/timemachine

sed -i'' -e "s,%USER%,${AFP_USER:-},g" /etc/afp.conf

echo ---begin-afp.conf--
cat /etc/afp.conf
echo ---end---afp.conf--

exec /usr/sbin/netatalk -d
