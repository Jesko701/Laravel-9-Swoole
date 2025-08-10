
# Laravel 9 with Swoole and MySQL using Docker

This guide walks you through setting up a **Laravel 9** application integrated with **Swoole** for high-performance HTTP handling and **MySQL**, all running inside **Docker** containers.

---

## 📑 Table of Contents

1. [Prerequisites](#1-prerequisites)  
2. [Project Initiation](#2-project-initiation)  
3. [Swoole Installation](#3-swoole-installation)  
4. [Docker Setup](#4-docker-setup)  
   - [Dockerfile](#dockerfile)  
   - [docker-compose.yml](#docker-compose-configuration)  
5. [Environment Configuration](#5-environment-configuration)  
6. [Build & Run the Application](#6-build--run-the-application)  
7. [Access the Application](#7-access-the-application)  
8. [Important: Update Laravel Rate Limiter Configuration](#8-important-update-laravel-rate-limiter-configuration)  
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites

Make sure the following tools are installed on your system:

- **PHP 8.0.2+** (local install may be required for Composer usage)  
- **Composer** – [Get Composer](https://getcomposer.org/download/)  
- **Docker Desktop** – [Install Docker](https://www.docker.com/products/docker-desktop/)  
- **Git** (optional, if cloning a repo)

---

## 2. Project Initiation

To create a new Laravel 9 project:

```bash
composer create-project laravel/laravel:^9.0 your-project-name
cd your-project-name
```

Replace `your-project-name` with your preferred directory name.

---

## 3. Swoole Installation

Install the Laravel Swoole bridge package:

```bash
composer require swooletw/laravel-swoole
```

This will enable your Laravel application to run on the Swoole HTTP server.

---

## 4. Docker Setup

### Dockerfile

Create a `Dockerfile` in the root directory:

```Dockerfile
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
```

### Docker Compose Configuration

Create a `docker-compose.yml` in the root directory:

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "9501:9501"
    volumes:
      - .:/var/www/html
    restart: unless-stopped
    depends_on:
      - db
    environment:
      APP_ENV: local
      APP_DEBUG: "true"
      DB_CONNECTION: mysql
      DB_HOST: db
      DB_PORT: 3306
      DB_DATABASE: laravel
      DB_USERNAME: laravel_user
      DB_PASSWORD: password
      SWOOLE_HTTP_HOST: 0.0.0.0
      SWOOLE_HTTP_PORT: 9501
    command: php artisan swoole:http start

  db:
    image: mysql:8.0
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: laravel
      MYSQL_USER: laravel_user
      MYSQL_PASSWORD: password
      MYSQL_ALLOW_EMPTY_PASSWORD: "no"
    volumes:
      - db_data:/var/lib/mysql
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u$$MYSQL_USER", "-p$$MYSQL_PASSWORD"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  db_data:
```

---

## 5. Environment Configuration

Update your `.env` file accordingly:

```env
APP_ENV=local
APP_DEBUG=true
APP_NAME="Laravel"
APP_URL=http://localhost:9501

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel_user
DB_PASSWORD=password

SWOOLE_HTTP_HOST=0.0.0.0
SWOOLE_HTTP_PORT=9501

LOG_CHANNEL=stack
LOG_LEVEL=debug
```

> 🔐 **Tip**: Replace `root_password`, `laravel_user`, and `password` with strong credentials in production.

---

## 6. Build & Run the Application

Run the following commands:

```bash
# Stop any containers using conflicting ports
docker-compose down

# Build the Docker image
docker-compose build

# Start services
docker-compose up -d

# Run database migrations
docker-compose exec app php artisan migrate
```

---

## 7. Access the Application

Visit [http://localhost:9501](http://localhost:9501) in your browser.  
To view container logs:

```bash
docker-compose logs -f app
docker-compose logs -f db
```

---

## 8. Important: Update Laravel Rate Limiter Configuration

When using Laravel with Swoole and serving many concurrent requests, it’s important to properly configure the rate limiter to prevent unwanted throttling or abuse.

Please update the `configureRateLimiting()` method in `app/Providers/RouteServiceProvider.php` as follows:

```php
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;

protected function configureRateLimiting()
{
    RateLimiter::for('api', function (Request $request) {
        return Limit::perMinute(60)->by(optional($request->user())->id ?: $request->ip());
    });
}
```

This setup limits API requests to 60 per minute per authenticated user or by IP address for guests. Adjust these values to fit your application’s needs.

> 💡 Proper rate limiting helps maintain performance and protects your application from abuse when handling high traffic with Swoole.

---

## 9. Troubleshooting

### ❌ _This page isn’t working_ / No response

- Check app logs:  
  `docker-compose logs -f app`
- Confirm `.env` contains:
  ```env
  SWOOLE_HTTP_HOST=0.0.0.0
  SWOOLE_HTTP_PORT=9501
  ```
- Ensure the Swoole server is started in Docker:  
  `php artisan swoole:http start`

### ❌ `Command "swoole:http" is not defined`

- Ensure the package is installed:  
  `composer require swooletw/laravel-swoole`
- Confirm the Dockerfile has:
  ```Dockerfile
  RUN php artisan vendor:publish --tag=laravel-swoole-config --force
  ```

### ❌ `Could not open input file: artisan`

- Ensure this Dockerfile line appears before `composer install`:
  ```Dockerfile
  COPY . .
  ```

### ❌ Composer or PHP version issues

- Ensure your Docker image is using PHP 8.2 (`phpswoole/swoole:5.1-php8.2`)
- Run `composer update` locally if needed

---

By following this guide, you’ll have a **high-performance Laravel 9 application running on Swoole and MySQL**, fully containerized with Docker for ease of development and deployment.