ARG CADDY_VERSION=2.6.1
FROM caddy-ext:${CADDY_VERSION} as caddy-ext-builder

ARG PHP_EXT_BENCODE_VERSION=8.1.11-fpm-bullseye
FROM php-ext-bencode:${PHP_EXT_BENCODE_VERSION} as php-ext-bencode-builder

ARG PHP_VER_TAG=8.1.11-fpm-bullseye
FROM docker.io/php:${PHP_VER_TAG}

# pecl mod: https://pecl.php.net/package/redis
# https://pecl.php.net/package/imagick
# https://pecl.php.net/package/xdebug

ENV TZ="Asia/Shanghai" \
    PHPFPM_LOG_LEVEL=warning \
    XDEBUG_REMOTE_ENABLE=off \
    XDEBUG_PROFILER_ENABLE=off \
    XDEBUG_PROFILER_OUTPUT_DIR="" \
    XDEBUG_CLIENT_PORT="9003" \
    XDEBUG_CLIENT_HOST="192.168.8.100" \
    PHP_SERVER_PORT=443 \
    TERM="xterm-256color" \
    UMASK_SET=022 \
    PUID=1000 \
    PGID=100

COPY --from=php-ext-bencode-builder /build/ /

#make sure the file copied successfully
RUN ls -lhp $(php-config --extension-dir)/bencode.so && \
    ls -lhp /usr/local/etc/php/conf.d/docker-php-ext-bencode.ini

#libgraphicsmagick1-dev libmagickwand-6.q16-dev
# git clone https://github.com/Imagick/imagick
# docker-php-ext-configure /tmp/imagick
# docker-php-ext-install -j1 /tmp/imagick

# https://pecl.php.net/package/redis
# https://pecl.php.net/package/xdebug
ENV REDIS_VERSION=5.3.7 \
XDEBUG_VERSION=3.1.5

# Install packages
RUN set -eux; \
    \
    echo "current architecture is: $(dpkg --print-architecture)"; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo "${TZ}" >  /etc/timezone; \
    sed -i 's|http://deb.debian.org|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list; \
    sed -i 's|http://security.debian.org|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list; \
    \
    apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd; \
    \
    docker-php-ext-install -j$(nproc) pdo_mysql mysqli exif opcache; \
    apt-get install -y libicu63 libicu-dev \
    && docker-php-ext-install -j$(nproc) intl; \
    apt-get install -y libzip-dev \
    && docker-php-ext-install -j$(nproc) zip; \
    docker-php-ext-install -j$(nproc) bcmath pcntl; \
    pecl install --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no"' redis-${REDIS_VERSION}; \
    pecl install xdebug-${XDEBUG_VERSION}; \
    docker-php-ext-enable redis xdebug; \
    \
    apt-get remove -y git; \
    rm -rf /tmp/*; \
    rm -rf /usr/share/gtk-doc; \
    echo "PHP module enabled: " && php-fpm -m; \
    echo "container date: " && date


# root filesystem
COPY base-rootfs /

ARG TINI_VERSION=v0.19.0

RUN set -eux; \
    \
    apt-get install -y --no-install-recommends procps ncdu tree iproute2; \
    rm -f /etc/init.d/*; \
    rm -rf /lib/systemd; \
    # cleanup doc and man
    rm -rf /usr/share/doc/*; \
    find /usr/share/man/ -type f | xargs rm -f; \
    # remove templates.dat-old, save 752.0 KiB
    rm -f /var/cache/debconf/templates.dat-old; \
    truncate -s 0 /var/log/lastlog; \
    \
    # init app user
    useradd -u $PUID -U -s /bin/false -m -d /home/app -c "app user" app; \
    # link default entrypoint
    ln -s /opt/common.sh /entrypoint.sh; \
    \
    # add s6
    curl -Lo/tmp/s6.tar.gz \
    https://github.com/just-containers/skaware/releases/download/v2.0.7/s6-2.11.0.0-linux-amd64-bin.tar.gz; \
    tar xvkzf /tmp/s6.tar.gz -C /; \
    rm -rf /tmp/s6.tar.gz; \
    # Add Tini
    curl -Lo/tini \
    https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-amd64; \
    chmod +x /tini; \
    \
    /tini --version

COPY --from=caddy-ext-builder /usr/bin/caddy /usr/bin/caddy

# setup composer
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
COPY --from=docker.io/library/composer:latest /usr/bin/composer /usr/local/bin/composer

RUN set -eux; \
    \
apt-get update && apt-get install -y zip unzip p7zip-full libnss3-tools; \
rm -rf /tmp/*; \
rm -rf /usr/share/gtk-doc; \
# install keys
curl \
    --silent \
    --fail \
    --location \
    --retry 3 \
    --output /tmp/keys.dev.pub \
    --url https://raw.githubusercontent.com/composer/composer.github.io/master/snapshots.pub \
  ; \
curl \
    --silent \
    --fail \
    --location \
    --retry 3 \
    --output /tmp/keys.tags.pub \
    --url https://raw.githubusercontent.com/composer/composer.github.io/master/releases.pub \
  ; \
printf "# composer php cli ini settings\n\
date.timezone=UTC\n\
memory_limit=-1\n\
" > $PHP_INI_DIR/php-cli.ini; \
composer --ansi --version --no-interaction; \
composer diagnose

VOLUME ["/app/public", "/app/ssl"]

WORKDIR /app/public

ENTRYPOINT ["/tini", "--"]

CMD ["/entrypoint.sh"]

# vim: set ft=dockerfile ts=4 sw=4 et:
