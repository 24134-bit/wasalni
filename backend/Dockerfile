FROM php:8.1-apache

# Install PostgreSQL dev libraries and the driver in one layer
RUN apt-get update && apt-get install -y libpq-dev \
    && docker-php-ext-install pdo_pgsql pgsql

# Enable Apache modules
RUN a2enmod rewrite headers

# Copy project files
COPY . /var/www/html/

# Set permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
