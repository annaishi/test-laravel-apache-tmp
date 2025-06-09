FROM php:8.3-apache-bullseye as php-base
# エラーがわかりやすくなるが、未定義変数で死んだりする。また、 $BOOL && command とやるときは || true をつけないと死ぬ
SHELL ["/bin/bash", "-oeux", "pipefail", "-c"]

ENV APP_ROOT /work
ENV TZ Asia/Tokyo
WORKDIR $APP_ROOT

# 必須ARG
ARG RELEASE_STAGE
RUN [ "${RELEASE_STAGE:-undefined}" == "undefined" ] && exit 1 || true
RUN [ "${RELEASE_STAGE}" != "development" -a "${RELEASE_STAGE}" != "staging" -a "${RELEASE_STAGE}" != "production" ] && exit 1 || true

# -- コンテナのTimeZone設定
RUN apt-get update && apt-get install -y tzdata && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo "Asia/Tokyo" > /etc/timezone && \
    apt-get remove -y tzdata

# -- Dockerize　(https://github.com/jwilder/dockerize?tab=readme-ov-file)
ENV DOCKERIZE_VERSION v0.8.0
RUN apt-get update && apt-get install -y wget \
    && wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && apt-get remove -y wget

# -- ライブラリのインストール
RUN apt-get install -y \
        git \
        libpng-dev \
        libjpeg-dev \
        libzip-dev \
        unzip &&\
        docker-php-ext-configure gd --with-jpeg=/usr/include/ && \
        docker-php-ext-install gd pdo_mysql zip pcntl exif sockets bcmath opcache

# -- PHPの開発用でのみ利用する拡張のインストール
ARG REQUIRE_DEV=false
RUN $REQUIRE_DEV && sh -c 'apt-get update && apt-get install -y libicu-dev && docker-php-ext-configure intl && docker-php-ext-install intl' || true

# -- PHPのXdebug有効化設定
ARG XDEBUG_DISABLED=true
RUN $XDEBUG_DISABLED || sh -c 'apt-get update && apt-get install -y autoconf build-essential && \
   pecl install xdebug && docker-php-ext-enable xdebug'
COPY ./.docker/php/docker-php-ext-xdebug.ini /tmp/
RUN $XDEBUG_DISABLED && sh -c 'rm /tmp/docker-php-ext-xdebug.ini' || sh -c 'cp /tmp/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini'

# install redis
RUN pecl install redis && docker-php-ext-enable redis

# -- PHPの依存ライブラリのインストール
# キャッシュするために先にcomposer installだけやっておく
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
COPY ./laravel/composer.json .
COPY ./laravel/composer.lock .

RUN mkdir -p database/seeders
RUN mkdir database/factories

RUN ! $REQUIRE_DEV || sh -c 'composer install --no-plugins --no-scripts'
RUN   $REQUIRE_DEV || sh -c 'composer install --no-plugins --no-scripts --no-dev'

##TODO:CIを設定する
##===============================================
## CIで利用する (Apacheの設定とかしない。PHPの設定を緩めたりする)
#FROM php-base as php
#
## PHPの設定
#COPY ./.docker/php.ini-*.patch ./
#RUN cp "${PHP_INI_DIR}/php.ini-development" "${PHP_INI_DIR}/php.ini";
#RUN patch "${PHP_INI_DIR}/php.ini" php.ini-ci.patch;
#
#ENV PATH $PATH:/work/vendor/bin
#RUN composer clear-cache
#
#COPY ./ .
#RUN composer dump-autoload

##TODO:Inertia.js & vue3を入れたら
##===============================================
## JavaScriptのビルド用。出来上がったものを後段でコピーする
#FROM node:20-slim as vite
#SHELL ["/bin/bash", "-oeux", "pipefail", "-c"]
#
#WORKDIR /vite
#
#COPY ./package.json .
#COPY ./package-lock.json .
#RUN npm ci
#
## -- ビルドにかかわるものだけ
## -- .dockerignoreで要らないものは無視される
##COPY ./.eslintignore .
##COPY ./.eslintrc.js .
##COPY ./tsconfig.json .
#COPY ./vite.config.js .
#COPY ./public ./public
##COPY ./resources/assets ./resources/assets
#COPY ./resources/css ./resources/css
#COPY ./resources/js ./resources/js
#
#ARG SKIP_BUILD=false
#ARG RELEASE_STAGE
### ないとnpm run devができない
#ARG APP_URL
## CIの時に$SKIP_BUILD=trueにすることでビルドが実行されなくなる（時間短縮のため）
##RUN if $SKIP_BUILD; then \
##        echo "skip build for ci"; \
##    elif [ "${RELEASE_STAGE}" == "development" ]; then \
##        npm run dev; \
##    else \
##        npm run build; \
##    fi

##===============================================
# viteのビルド用。出来上がったものを後段でコピーする ## laravelのデフォルト用
FROM node:20-slim as vite
WORKDIR /vite

COPY ./laravel/package.json .
COPY ./laravel/package-lock.json .
# ziggy
COPY --from=php-base /work/vendor ./vendor
RUN npm ci

# -- ビルドにかかわるものだけ
# -- .dockerignoreで要らないものは無視される
#COPY ./.eslintignore .
#COPY ./.eslintrc.js .
#COPY ./tsconfig.json .
COPY ./laravel/vite.config.js .
COPY ./laravel/tailwind.config.js .
COPY ./laravel/postcss.config.js .
COPY ./laravel/public ./public
#COPY ./resources/assets ./resources/assets
COPY ./laravel/resources/css ./resources/css
COPY ./laravel/resources/js ./resources/js

ARG COMPILE_ASSETS=false
RUN ! $COMPILE_ASSETS || bash -c 'npm run build'

RUN $COMPILE_ASSETS ||  bash -c 'mkdir -p public/build && touch public/build/dummy'

#===============================================
# 実際にサービスで使うところまで構築するフェーズ
FROM php-base

# -- 残りをもってく。 .dockerignoreで要らないものは無視される
COPY ./ .
# ビルドしたアセットをコピーしてくる
COPY --from=vite /vite/public/build ./public/build

##TODO:
#### 持っていくのはbuildディレクトリとmanifest.jsonなので、↑とはぶつからない
#COPY --from=vue3-build /vue3/public/ ./public/

# プロジェクトのクラスをautoloaderに登録する
RUN composer dump-autoload

# -- PHPの設定 (from: https://hub.docker.com/_/php)

ARG RELEASE_STAGE
COPY ./.docker/php/php.ini-*.patch ./
RUN if [ "${RELEASE_STAGE}" == "development" ]; then \
        cp "${PHP_INI_DIR}/php.ini-development" "${PHP_INI_DIR}/php.ini"; \
        patch "${PHP_INI_DIR}/php.ini" php.ini-common.patch; \
#        patch "${PHP_INI_DIR}/php.ini" php.ini-dev.patch; \　##これは死ぬ
    else \
        cp "${PHP_INI_DIR}/php.ini-production" "${PHP_INI_DIR}/php.ini"; \
        # デフォルトphp.iniでLaravel最適化
        php artisan view:cache; \
        patch "${PHP_INI_DIR}/php.ini" php.ini-common.patch; \
    fi

# -- コマンドのハードコード対応
RUN mkdir -p /var/www && \
    ln -s $APP_ROOT /var/www/work

# Apacheの設定
##必要に応じて
## a2enmod headers && \
## a2dismod -f alias && \
RUN a2enmod rewrite && \
    a2dismod -f autoindex && \
    sed -i -E 's/^(ServerTokens) OS$/\1 Prod/' /etc/apache2/conf-enabled/security.conf && \
    sed -i -E 's/^(ServerSignature) On$/\1 Off/' /etc/apache2/conf-enabled/security.conf && \
    sed -i -E 's/^(KeepAliveTimeout) 5$/\1 150/' /etc/apache2/apache2.conf

COPY ./.docker/apache/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY ./.docker/apache/envvars /etc/apache2/envvars

RUN chown -R www-data:www-data /work/storage
# WHY IS THIS NEEDED?!?!
RUN chmod o+w /work/bootstrap/cache

# Optimize
# https://readouble.com/laravel/10.x/ja/deployment.html
RUN if [ "${RELEASE_STAGE}" == "development" ]; then \
        echo "skip optimization"; \
    else \
        # configやrouteはenvが焼き込まれてしまうので使わない
        # php artisan config:cache; \
        # php artisan route:cache; \
        PHP_MEMORY_LIMIT=1G php artisan view:cache; \
    fi



# 簡易的なやつ
# FROM php:8.3-apache-bullseye

# # エラー検知を強める
# SHELL ["/bin/bash", "-oeux", "pipefail", "-c"]
# ENV TZ=Asia/Tokyo APP_ROOT=/work
# WORKDIR $APP_ROOT

# # タイムゾーン設定を軽量に
# RUN apt-get update && apt-get install -y --no-install-recommends tzdata \
#  && ln -snf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
#  && echo "Asia/Tokyo" > /etc/timezone \
#  && apt-get purge -y --auto-remove tzdata

# # 必要拡張だけ入れる（本番用）
# RUN apt-get install -y git libpng-dev libjpeg-dev libzip-dev unzip \
#  && docker-php-ext-configure gd --with-jpeg=/usr/include/ \
#  && docker-php-ext-install gd pdo_mysql zip pcntl exif sockets bcmath opcache

# # Composer
# COPY ./laravel/composer.json ./
# COPY ./laravel/composer.lock ./
# RUN composer install --no-dev --no-scripts --prefer-dist --no-plugins

# # アプリ本体
# COPY ./laravel/ ./

# # ファイル権限
# RUN chown -R www-data:www-data storage bootstrap/cache

# # Apache 設定（最低限の例）
# RUN a2enmod rewrite

# EXPOSE 80
# CMD ["apache2-foreground"]
