FROM debian:jessie-slim as builder
MAINTAINER Wietse Muizelaar <wietse.muizelaar@xs4all.nl>
ENV NETATALK_VERSION 3.1.11

ENV DEPS="build-essential libssl-dev libgcrypt11-dev libkrb5-dev libpam0g-dev libwrap0-dev libdb-dev libglib2.0-dev file libcrack2-dev libtdb-dev libevent-dev"
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install \
        --no-install-recommends \
        --fix-missing \
        --assume-yes \
        $DEPS \
        wget \
        ca-certificates \
        && wget "http://ufpr.dl.sourceforge.net/project/netatalk/netatalk/${NETATALK_VERSION}/netatalk-${NETATALK_VERSION}.tar.gz" \
        && tar xvfz netatalk-${NETATALK_VERSION}.tar.gz

WORKDIR netatalk-${NETATALK_VERSION}

RUN ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-zeroconf \
        --disable-tcp-wrappers \
        --disable-quota \
        --disable-shell-check \
        --without-acls \
        --with-init-style=debian-systemd \
        --without-libevent \
        --without-tdb \
        --with-cracklib \
        --without-kerberos \
        --without-ldap \
        --without-afpstats \
        --with-pam-confdir=/etc/pam.d \
        --enable-silent-rules \
        && make \
        && make install DESTDIR=/builded

RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64.deb \
  && dpkg -i dumb-init_1.2.0_amd64.deb

FROM debian:jessie-slim
MAINTAINER Wietse Muizelaar <wietse.muizelaar@xs4all.nl>

ENV LANG C.UTF-8

COPY --from=builder /usr/bin/dumb-init /usr/bin/dumb-init
COPY --from=builder /builded/ /

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY afp.conf /etc/afp.conf
ENV DEBIAN_FRONTEND=newt

RUN apt-get update \
 && apt-get install \
        --no-install-recommends \
        libevent-2.0 \
        libtdb1 \
        libcrack2 \
        libssl1.0.0

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["/docker-entrypoint.sh"]
