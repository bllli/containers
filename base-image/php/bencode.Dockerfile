ARG PHP_VER_TAG=8.1.11-fpm-bullseye
FROM docker.io/php:${PHP_VER_TAG}

# pecl mod: https://pecl.php.net/package/redis
# https://pecl.php.net/package/imagick
# https://pecl.php.net/package/xdebug

ENV TZ="Asia/Shanghai"

# Install packages
RUN set -eux; \
    	\
        apt-get update -y; \
        apt-get install -y --no-install-recommends git; \
    git clone -b master https://github.com/Frederick888/php-bencode.git /tmp/bencode;\
    docker-php-ext-configure /tmp/bencode; \
    docker-php-ext-install -j$(nproc) /tmp/bencode; \
    rm -rf /tmp/bencode; \
    docker-php-ext-enable bencode; \
    rm -rf /tmp/*; \
    mkdir -p /build$(php-config --extension-dir); \
    mkdir -p /build/usr/local/etc/php/conf.d/; \
    echo "bencode.namespace=1" >> /usr/local/etc/php/conf.d/docker-php-ext-bencode.ini; \
    cp -v $(php-config --extension-dir)/bencode.so /build/$(php-config --extension-dir)/bencode.so; \
    cp -v /usr/local/etc/php/conf.d/docker-php-ext-bencode.ini /build/usr/local/etc/php/conf.d/; \
    echo "PHP bencode module enabled: " && php-fpm -m | grep bencode; \
    echo "test: " && php -r 'print_r(\bencode\bitem::parse("d4:infod6:lengthi364e4:name8:test.rare3:inti1548400939e4:listl5:UTF-83:GBKe6:string13:uTorrent/3130e")->to_array());'; \
    echo "container date: " && date

# vim: set ft=dockerfile ts=4 sw=4 et:
