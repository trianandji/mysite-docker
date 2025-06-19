# Use a specific, stable PHP version with Apache for consistency
# php:8.3-apache is a good choice as of current date (June 2025)
FROM php:8.3-apache

# Set working directory for easier path management
WORKDIR /var/www/html

# 1. Install necessary system dependencies in one RUN command
#    - apt-get update and clean up are combined for efficiency
#    - Additional tools like 'curl' and 'gnupg' might be useful for debugging or future needs
#    - 'procps' for utilities like 'ps' and 'top' (useful for debugging inside container)
RUN apt-get update && \
    apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    curl \
    gnupg \
    procps \
    && rm -rf /var/lib/apt/lists/*

# 2. Install PHP extensions in a separate RUN command for better layer caching
#    - 'opcache' is usually pre-installed/enabled, but harmless to list if you need to ensure it.
#    - 'mysqli' is the procedural interface, 'pdo_mysql' is the PDO interface. Good to have both.
RUN docker-php-ext-install -j$(nproc) \
    pdo pdo_mysql mysqli \
    zip gd intl mbstring exif opcache

# 3. Enable Apache rewrite module
RUN a2enmod rewrite

# 4. Copy your Drupal website files
#    - This assumes your Drupal website's *root* (where index.php, composer.json, etc. are)
#      is directly under the 'html' folder in your Git repo.
#    - Make sure the 'html' folder in your repo contains everything needed for Drupal.
COPY ./html /var/www/html/

# 5. Set correct permissions for Drupal.
#    - More granular permissions: 755 for directories, 644 for files.
#    - This ensures the web server can read files and traverse directories, but not write where it shouldn't.
#    - The `sites/default/files` directory needs write permissions for user uploads.
#    - Ensure the `sites/default/settings.php` is read-only after initial setup.
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && chmod -R 775 /var/www/html/sites/default/files # Allow web server write access to files directory

# 6. Expose port 80 (standard HTTP)
EXPOSE 80

# 7. Command to run Apache in the foreground.
#    This is essential for Docker containers, as the container exits if the main process exits.
CMD ["apache2-foreground"]
