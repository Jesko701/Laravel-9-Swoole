Laravel 9 with Swoole and MySQL using DockerThis guide provides a comprehensive set of steps to set up a Laravel 9 project, integrate it with the Swoole high-performance server, and run both the application and a MySQL database using Docker and Docker Compose.Table of ContentsPrerequisitesProject InitiationSwoole Package InstallationDocker SetupDockerfileDocker Compose ConfigurationEnvironment ConfigurationBuilding and Running the ApplicationAccessing the ApplicationTroubleshooting1. PrerequisitesBefore you begin, ensure you have the following installed on your local machine:PHP (8.0.2 or higher): While the Docker container will provide PHP 8.2, you might need a local PHP installation for Composer.Composer: The dependency manager for PHP.Download ComposerDocker Desktop: Includes Docker Engine and Docker Compose.Download Docker DesktopGit: For cloning projects (if starting from an existing one).2. Project InitiationIf you don't have an existing Laravel 9 project, create a new one:Open your terminal or command prompt.Navigate to your desired development directory.Create a new Laravel 9 project:composer create-project laravel/laravel:^9.0 your-project-name
(Replace your-project-name with your preferred project directory name.)Navigate into your new project directory:cd your-project-name
3. Swoole Package InstallationThe swooletw/laravel-swoole package provides the necessary integration for Laravel to run on Swoole.On your local machine, inside your Laravel project directory, run:composer require swooletw/laravel-swoole
This command will add the package to your composer.json and composer.lock files.4. Docker SetupWe will create two Docker configuration files: Dockerfile for building the application image and docker-compose.yml for orchestrating the application and database services.DockerfileCreate a file named Dockerfile in the root of your Laravel project:# Use the specified Swoole base image with PHP 8.2 to match package requirements
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
CMD ["php", "artisan", "swoole:http", "start"]
Docker Compose ConfigurationCreate a file named docker-compose.yml in the root of your Laravel project:version: '3.8'

services:
  app:
    # Build the Docker image using the Dockerfile in the current directory
    build:
      context: .
      dockerfile: Dockerfile
    # Map port 9501 from the host to port 9501 in the container
    ports:
      - "9501:9501"
    # Mount the current project directory into the container's working directory
    # This allows for live code changes without rebuilding the image
    volumes:
      - .:/var/www/html
    # Restart the container automatically unless it's explicitly stopped
    restart: unless-stopped
    # Ensure the 'db' service is started before the 'app' service
    depends_on:
      - db
    # Define environment variables for the Laravel application
    # These will override or complement variables in the .env file
    environment:
      APP_ENV: local
      APP_DEBUG: "true"
      # Database connection details for the MySQL container
      DB_CONNECTION: mysql
      DB_HOST: db # This refers to the 'db' service name in docker-compose
      DB_PORT: 3306
      DB_DATABASE: laravel # Match this with MYSQL_DATABASE in the db service
      DB_USERNAME: laravel_user # Match this with MYSQL_USER in the db service
      DB_PASSWORD: password # Match this with MYSQL_PASSWORD in the db service
      # Swoole specific environment variables, which the package reads automatically
      SWOOLE_HTTP_HOST: 0.0.0.0
      SWOOLE_HTTP_PORT: 9501
    # Command to run when the container starts (overrides Dockerfile CMD if specified here)
    # This will start the Swoole HTTP server for Laravel using the correct command
    command: php artisan swoole:http start

  db:
    # Use the official MySQL 8.0 Docker image
    image: mysql:8.0
    # Map port 3306 from the host to port 3306 in the container (optional, for direct host access)
    ports:
      - "3306:3306"
    # Define environment variables for MySQL configuration
    environment:
      MYSQL_ROOT_PASSWORD: root_password # Set a strong root password
      MYSQL_DATABASE: laravel # The database Laravel will connect to
      MYSQL_USER: laravel_user # The user Laravel will use
      MYSQL_PASSWORD: password # The password for the Laravel user
      MYSQL_ALLOW_EMPTY_PASSWORD: "no" # Do not allow empty password for root
    # Persist database data to a named volume
    volumes:
      - db_data:/var/lib/mysql
    # Restart the container automatically unless it's explicitly stopped
    restart: unless-stopped
    # Set a custom healthcheck to ensure MySQL is ready before the app connects
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u$$MYSQL_USER", "-p$$MYSQL_PASSWORD"]
      interval: 10s
      timeout: 5s
      retries: 5

# Define named volumes for persistent data storage
volumes:
  db_data:
5. Environment ConfigurationUpdate your Laravel project's .env file to match the database and Swoole configurations defined in docker-compose.yml.APP_ENV=local
APP_DEBUG=true

# Database Configuration
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel_user
DB_PASSWORD=password

# Swoole Configuration
SWOOLE_HTTP_HOST=0.0.0.0
SWOOLE_HTTP_PORT=9501

# Other Laravel .env variables...
APP_NAME="Laravel"
APP_URL=http://localhost:9501
LOG_CHANNEL=stack
LOG_LEVEL=debug
# ... (rest of your .env file)
Important: Replace root_password, laravel, laravel_user, and password with strong, secure values.6. Building and Running the ApplicationNow, let's build your Docker images and start the containers.Stop any existing Docker containers that might be using the same ports:docker-compose down
Build your Docker images: This step reads your Dockerfile and creates the app service image.docker-compose build
Start your Docker containers in detached mode (in the background):docker-compose up -d
Run Laravel database migrations: Once the containers are up, execute your migrations to create database tables.docker-compose exec app php artisan migrate
7. Accessing the ApplicationYour Laravel application should now be running with Swoole and connected to the MySQL database.Access your application in your web browser at:http://localhost:9501Check container logs to ensure everything is running smoothly:docker-compose logs -f app
docker-compose logs -f db
You should see messages indicating the Swoole HTTP server starting on 0.0.0.0:9501 in the app logs.8. TroubleshootingIf you encounter issues, here are some common troubleshooting steps:"This page isn’t working right now / didn’t send any data."Check docker-compose logs -f app for PHP errors or if the Swoole server failed to start.Ensure SWOOLE_HTTP_HOST=0.0.0.0 and SWOOLE_HTTP_PORT=9501 are correctly set in your .env and that the command in docker-compose.yml is php artisan swoole:http start.Clear Laravel caches inside the container:docker-compose exec app php artisan config:clear
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear
docker-compose exec app php artisan optimize:clear
docker-compose restart app
"Command 'swoole:start' is not defined."Ensure swooletw/laravel-swoole is correctly installed in your composer.json and composer.lock (run composer require swooletw/laravel-swoole locally).Verify the Dockerfile has RUN php artisan vendor:publish --tag=laravel-swoole-config --force.Confirm the command in docker-compose.yml for the app service is php artisan swoole:http start."Could not open input file: artisan" during docker-compose buildEnsure the COPY . . command in your Dockerfile comes before composer install.Composer dependency issues (PHP version mismatch, etc.)Ensure your Dockerfile uses a PHP version compatible with your Laravel project and its dependencies (e.g., phpswoole/swoole:5.1-php8.2).Run composer update locally to update your composer.lock if dependencies have changed or new ones were added.By following these steps, you should have a high-performance Laravel 9 application running with Swoole and MySQL in a Dockerized environment.