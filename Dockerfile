FROM kazu69/alpine-base:latest
MAINTAINER kazu69

RUN apk add --no-cache \
            autoconf \
            bison \
            bzip2 \
            bzip2-dev \
            binutils-gold \
            curl-dev \
            coreutils \
            g++ \
            gcc \
            gdbm-dev \
            glib-dev \
            libc-dev \
            libedit-dev \
            libxml2-dev \
            libmcrypt-dev \
            libxslt-dev \
            libffi-dev \
            linux-headers \
            libgcc \
            libstdc++ \
            make \
            musl-dev \
            ncurses-dev \
            openssl \
            pkgconf \
            procps \
            paxctl \
            python \
            ruby \
            sqlite-dev \
            yaml-dev \
            zlib-dev

# Build PHP
ENV PHP_VERSION 5.6.26
ENV PHP_FILENAME "php-${PHP_VERSION}.tar.xz"
ENV PHP_SHA256 203a854f0f243cb2810d1c832bc871ff133eccdf1ff69d32846f93bc1bef58a8
ENV GPG_KEYS 0BD78B5F97500D450838F95DFE857D9A90D90EC1 6E4F6AB321FDC07F2C332E3AC2BF0BC433CFC8B3
ENV DOWNLOAD_URL "https://secure.php.net/get/$PHP_FILENAME/from/this/mirror"
ENV PGP_URL "https://secure.php.net/get/$PHP_FILENAME.asc/from/this/mirror"
ENV PGP_KEY_SERVER 'ha.pool.sks-keyservers.net'
ENV COMPOSER_INSTALLER_URL 'https://getcomposer.org/installer'

RUN apk add --no-cache --virtual=.build-dep gnupg && \
    mkdir -p /tmp/build/php && \
    cd /tmp/build/php && \
    curl -fSL $DOWNLOAD_URL -o php.tar.xz && \
    echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c - && \
    curl -fSL $PGP_URL -o php.tar.xz.asc

RUN export GNUPGHOME="$(mktemp -d)" && \
    cd /tmp/build/php && \
    for key in $GPG_KEYS; do \
        gpg --keyserver $PGP_KEY_SERVER --recv-keys "$key"; \
    done && \
    gpg --batch --verify php.tar.xz.asc php.tar.xz && \
    rm -r "$GNUPGHOME" && \
    apk del .build-dep

ENV PHP_INI_DIR /usr/local/etc/php

RUN cd /tmp/build/php && \
      tar -Jxf php.tar.xz -C /tmp/build/php --strip-components=1 && \
      rm php.tar.xz && \
      ./configure \
          --with-config-file-path="$PHP_INI_DIR" \
          --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
          --with-curl \
          --with-iconv \
          --with-libedit \
          --with-mcrypt \
          --with-mhash \
          --with-mysql=mysqlnd \
          --with-mysqli=mysqlnd \
          --with-pdo-mysql=mysqlnd \
          --with-mysql-sock=/var/run/mysqld/mysqld.sock \
          --with-openssl \
          --with-pcre-regex \
          --with-pear \
          --with-sqlite3 \
          --with-pdo-sqlite \
          --with-xsl \
          --with-zlib \
          --enable-bcmath \
          --enable-ctype \
          --enable-cli \
          --enable-calendar \
          --enable-dom \
          --enable-ftp \
          --enable-fileinfo \
          --enable-filter \
          --enable-json \
          --enable-libxml \
          --enable-mbstring \
          --enable-mbregex \
          --enable-mysqlnd \
          --enable-opcache \
          --enable-simplexm \
          --enable-session \
          --enable-sockets \
          --enable-sysvsem \
          --enable-sysvshm \
          --enable-sysvmsg \
          --enable-shmop \
          --enable-tokenizer \
          --enable-pdo \
          --enable-phpdbg \
          --enable-phar \
          --enable-posix \
          --enable-pcntl \
          --enable-xml \
          --enable-xmlwriter \
          --enable-xmlreader \
          --enable-zip \
          --disable-cgi && \
      make -j $(getconf _NPROCESSORS_ONLN) && \
      make install && \
      make clean && \
      rm -rf /tmp/build/php

RUN curl -fSL $COMPOSER_INSTALLER_URL | php -- --install-dir=/usr/local/bin --filename=composer

# Build Ruby
ENV RUBY_VERSION 2.3.1
ENV RUBY_DOWNLOAD_SHA256 b87c738cb2032bf4920fef8e3864dc5cf8eae9d89d8d523ce0236945c5797dcd
ENV RUBYGEMS_VERSION 2.6.6
ENV RUBY_DOWNLOAD_URL "https://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz"

RUN curl -fSL $RUBY_DOWNLOAD_URL -o ruby.tar.gz && \
    echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - && \
    mkdir -p /tmp/build/ruby && \
    tar -xzf ruby.tar.gz -C /tmp/build/ruby --strip-components=1 && \
    rm ruby.tar.gz && \
    cd /tmp/build/ruby && \
    autoconf && \
    ./configure --disable-install-doc && \
    make -j"$(getconf _NPROCESSORS_ONLN)" && \
    make install && \
    gem update --system && \
    gem install bundler

# Build NodeJS
ENV NODE_VERSION v6.7.0
ENV NODE_DOWNLOAD_URL "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}.tar.gz"
ENV NODE_DOWNLOAD_SHA256 02b8ee1719a11b9ab22bef9279519efaaf31dd0d39cba4c3a1176ccda400b8d6

RUN  mkdir -p /tmp/build/node && \
    curl -fSL $NODE_DOWNLOAD_URL -o node.tar.gz && \
    echo "$NODE_DOWNLOAD_SHA256 *node.tar.gz" | sha256sum -c - && \
    tar -xzf node.tar.gz -C /tmp/build/node --strip-components=1 && \
    rm node.tar.gz && \
    cd /tmp/build/node && \
    ./configure --prefix=/usr && \
    make install

# npm@3 install bug for Docker aufs
RUN cd $(npm root -g)/npm && \
    npm install fs-extra && \
    sed -i -e s/graceful-fs/fs-extra/ -e s/fs\.rename/fs.move/ ./lib/utils/rename.js

RUN npm i -g npm
RUN npm cache clean
