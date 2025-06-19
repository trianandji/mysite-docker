FROM php:8.3-apache

WORKDIR /var/www/html

# Install system dependencies
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

# Install PHP extensions
RUN docker-php-ext-install -j$(nproc) \
    pdo pdo_mysql mysqli \
    zip gd intl mbstring exif opcache

# Enable Apache rewrite module
RUN a2enmod rewrite

# ✅ Install Composer inside the image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy your Drupal website files
COPY ./web /var/www/html/

# ✅ Install PHP dependencies with Composer inside the image
RUN composer install --no-dev --optimize-autoloader

# Set correct permissions for Drupal
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && chmod -R 775 /var/www/html/sites/default/files

EXPOSE 80

CMD ["apache2-foreground"]
