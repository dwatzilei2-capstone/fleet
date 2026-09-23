FROM php:8.3-apache

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl libpq-dev \
    && docker-php-ext-install pdo_pgsql \
    && a2enmod headers rewrite \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --optimize-autoloader

COPY . .

RUN chown -R www-data:www-data /var/www/html \
    && sed -ri 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

ENV PORT=8080
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=5 \
    CMD curl --fail --silent "http://127.0.0.1:${PORT}/health.php" > /dev/null || exit 1

CMD ["sh", "-c", "sed -ri \"s/Listen 80/Listen ${PORT}/\" /etc/apache2/ports.conf && sed -ri \"s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/\" /etc/apache2/sites-available/000-default.conf && exec apache2-foreground"]
