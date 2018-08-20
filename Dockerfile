FROM php:7.1-cli-alpine3.7
ENV RABBITMQ_VERSION v0.8.0
ENV PHP_AMQP_VERSION v1.9.3
ENV PHP_REDIS_VERSION 4.1.0
ENV PHP_MONGO_VERSION 1.5.2
# persistent / runtime deps
ENV PHPIZE_DEPS \
    autoconf \
    cmake \
    file \
    g++ \
    gcc \
    libc-dev \
    pcre-dev \
    make \
    git \
    pkgconf \
    re2c \
    # for GD
    freetype-dev \
    libpng-dev  \
    libjpeg-turbo-dev
RUN apk add --no-cache --virtual .persistent-deps \
    libmcrypt-dev \
    # for intl extension
    icu-dev \
    # for postgres
    postgresql-dev \
    # for soap
    libxml2-dev \
    # for amqp
    libressl-dev \
    # for GD
    freetype \
    libpng \
    libjpeg-turbo
RUN set -xe \
    # workaround for rabbitmq linking issue
    && ln -s /usr/lib /usr/local/lib64 \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
    && docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure bcmath --enable-bcmath \
    && docker-php-ext-configure intl --enable-intl \
    && docker-php-ext-configure pcntl --enable-pcntl \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql \
    && docker-php-ext-configure pdo_pgsql --with-pgsql \
    && docker-php-ext-configure mbstring --enable-mbstring \
    && docker-php-ext-configure soap --enable-soap \
    && docker-php-ext-install -j$(nproc) \
        gd \
        bcmath \
        intl \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        mbstring \
        soap \
        iconv \
        mcrypt \
    && git clone --branch ${RABBITMQ_VERSION} https://github.com/alanxz/rabbitmq-c.git /tmp/rabbitmq \
        && cd /tmp/rabbitmq \
        && mkdir build && cd build \
        && cmake .. \
        && cmake --build . --target install \
    && git clone --branch ${PHP_AMQP_VERSION} https://github.com/pdezwart/php-amqp.git /tmp/php-amqp \
        && cd /tmp/php-amqp \
        && phpize  \
        && ./configure  \
        && make  \
        && make install \
    && git clone --branch ${PHP_REDIS_VERSION} https://github.com/phpredis/phpredis /tmp/phpredis \
        && cd /tmp/phpredis \
        && phpize  \
        && ./configure  \
        && make  \
        && make install \
        && make test \
    && git clone --branch ${PHP_MONGO_VERSION} https://github.com/mongodb/mongo-php-driver /tmp/php-mongo \
        && cd /tmp/php-mongo \
        && git submodule sync && git submodule update --init \
        && phpize  \
        && ./configure  \
        && make  \
        && make install \
        && make test \
    && apk del .build-deps \
    && rm -rf /tmp/* \
    && rm -rf /app \
    && mkdir /app
# Copy configuration
COPY config/php7.ini /usr/local/etc/php/conf.d/
COPY config/amqp.ini /usr/local/etc/php/conf.d/
COPY config/redis.ini /usr/local/etc/php/conf.d/
COPY config/mongodb.ini /usr/local/etc/php/conf.d/
COPY config/php-cli.ini /usr/local/etc/php/php.ini
VOLUME ["/app"]
WORKDIR /app
