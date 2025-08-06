# Use the specified Swoole base image with PHP 8.2 to match package requirements
FROM phpswoole/swoole:5.1-php8.2

# Set the working directory inside the container
WORKDIR /var/www/html

# Install system dependencies for Composer and other tools
# We use apt-get update and install git, unzip, and other necessary extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions required by Laravel
# This includes pdo_mysql (for MySQL), bcmath, and opcache for performance
RUN docker-php-ext-install pdo_mysql bcmath zip opcache

# Copy the entire application code first, including composer.json, composer.lock, and artisan
COPY . .

# Install Composer dependencies based on composer.lock
# --no-dev: Skips development dependencies to keep the production image smaller
# --optimize-autoloader: Optimizes Composer's autoloader for faster class loading
# --no-interaction: Prevents Composer from asking questions during installation
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Publish the laravel-swoole package's configuration
# The package itself is now installed via the 'composer install' command above
RUN php artisan vendor:publish --tag=laravel-swoole-config --force

# Generate application key if it doesn't exist (useful for fresh installs)
# This command will only run if .env is missing APP_KEY
RUN php artisan key:generate || true

# Set appropriate permissions for Laravel's storage and bootstrap/cache directories
# These directories need write permissions for the web server
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Expose the default Swoole HTTP server port
EXPOSE 9501

# Command to run the Laravel Swoole HTTP server
CMD ["php", "artisan", "swoole:http"]