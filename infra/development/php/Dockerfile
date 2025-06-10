# 1. Apache 版 PHP イメージを使う
FROM php:8.3-apache

# 2. 必要なパッケージを追加
RUN apt-get update && apt-get install -y \
        git zip unzip \
    && docker-php-ext-install pdo_mysql         # MySQL ドライバ

# 3. Apache の rewrite モジュールを有効化
RUN a2enmod rewrite

# 4. Laravel のエントリポイントに合わせて DocumentRoot を public/ に変更
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
        /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' \
        /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 5. Composer を取り込む（マルチステージ）
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 6. 作業ディレクトリ
WORKDIR /var/www/html

# 7. ビルド時にソースをコピーする場合（ホスト側から COPY するならここ）
# COPY . .

# 8. ポート指定（Apache は 80）
EXPOSE 80

# 9. デフォルト CMD は親イメージの `apache2-foreground` が設定済み
