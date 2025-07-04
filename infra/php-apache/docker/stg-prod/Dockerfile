FROM php:8.3-apache-bullseye as php-base
# エラーがわかりやすくなるが、未定義変数で死んだりする。また、 $BOOL && command とやるときは || true をつけないと死ぬ
SHELL ["/bin/bash", "-oeux", "pipefail", "-c"]

ENV APP_ROOT /work
ENV TZ Asia/Tokyo
WORKDIR $APP_ROOT

# -- コンテナのTimeZone設定
RUN apt-get update && apt-get install -y tzdata && \
cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
echo "Asia/Tokyo" > /etc/timezone && \
apt-get remove -y tzdata

# -- ライブラリのインストール
RUN apt-get install -y \
        git \
        libpng-dev \
        libjpeg-dev \
        libzip-dev \
        unzip &&\
        docker-php-ext-configure gd --with-jpeg=/usr/include/ && \
        docker-php-ext-install gd pdo_mysql zip pcntl exif sockets bcmath opcache

# install redis
RUN pecl install redis && docker-php-ext-enable redis

# -- PHPの依存ライブラリのインストール
# キャッシュするために先にcomposer installだけやっておく
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
COPY ../../../../laravel/composer.json .
COPY ../../../../laravel/composer.lock .

RUN mkdir -p database/seeders
RUN mkdir database/factories

RUN sh -c 'composer install --no-plugins --no-scripts --no-dev'

##===============================================
# viteのビルド用。出来上がったものを後段でコピーする ## laravelのデフォルト用
FROM node:20-slim as vite
WORKDIR /vite

# node-gyp のビルドに必要な依存をインストール (追記)
RUN apt-get update && apt-get install -y python3 make g++

COPY ../../../../laravel/package.json .
COPY ../../../../laravel/package-lock.json .

# ziggy
COPY --from=php-base /work/vendor ./vendor
RUN npm ci

# -- ビルドにかかわるものだけ
# -- .dockerignoreで要らないものは無視される
#COPY ../../../../laravel/.eslintignore .
#COPY ../../../../laravel/.eslintrc.js .
#COPY ../../../../laravel/tsconfig.json .
COPY ../../../../laravel/vite.config.js .
# COPY ../../../../laravel/tailwind.config.js .
# COPY ../../../../laravel/postcss.config.js .
COPY ../../../../laravel/public ./public
#COPY ../../../../laravel/resources/assets ./resources/assets
COPY ../../../../laravel/resources/css ./resources/css
COPY ../../../../laravel/resources/js ./resources/js

RUN bash -c 'npm run build'

#===============================================
# 実際にサービスで使うところまで構築するフェーズ
FROM php-base

# -- 残りをもってく。 .dockerignoreで要らないものは無視される
COPY ../../../../laravel/ .
# ビルドしたアセットをコピーしてくる
COPY --from=vite /vite/public/build ./public/build

# プロジェクトのクラスをautoloaderに登録する
RUN composer dump-autoload

# -- PHPの設定 (from: https://hub.docker.com/_/php)
COPY ../../../../infra/php-apache/php/php.ini-*.patch ${PHP_INI_DIR}/
RUN cp "${PHP_INI_DIR}/php.ini-production" "${PHP_INI_DIR}/php.ini"; \
    # デフォルトphp.iniでLaravel最適化
    php artisan view:cache; \
    patch "${PHP_INI_DIR}/php.ini" "${PHP_INI_DIR}/php.ini-common.patch"

# apacheのルートにシンボリックリンクを貼る
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

COPY ../../../../infra/php-apache/apache/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY ../../../../infra/php-apache/apache/envvars /etc/apache2/envvars

RUN chown -R www-data:www-data /work/storage
# WHY IS THIS NEEDED?!?!
RUN chmod o+w /work/bootstrap/cache

# Optimize
# https://readouble.com/laravel/10.x/ja/deployment.html
RUN PHP_MEMORY_LIMIT=1G php artisan view:cache; \    
    # configやrouteはenvが焼き込まれてしまうので使わない
    # php artisan config:cache; \
    # php artisan route:cache; \
    