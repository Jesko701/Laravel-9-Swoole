FROM phpswoole/swoole:5.1-php8.2

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y     git     unzip     libpq-dev     libzip-dev     && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pdo_mysql bcmath zip opcache

COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction

RUN php artisan vendor:publish --tag=laravel-swoole-config --force
RUN php artisan key:generate || true

RUN chown -R www-data:www-data storage bootstrap/cache     && chmod -R 775 storage bootstrap/cache

EXPOSE 9501

CMD ["php", "artisan", "swoole:http", "start"]