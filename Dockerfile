# Stage 1: Builder (build on Debian for better compatibility)
FROM php:8.2-cli AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git unzip libpq-dev libzip-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pdo_mysql bcmath zip opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction

RUN composer require swooletw/laravel-swoole \
    && php artisan vendor:publish --tag=laravel-swoole-config --force

RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache


# Stage 2: Runtime (Alpine-based)
FROM phpswoole/swoole:php8.2-alpine

WORKDIR /var/www/html

# Copy built app from builder stage
COPY --from=builder /app /var/www/html

EXPOSE 9501

CMD ["php", "artisan", "swoole:http", "start"]