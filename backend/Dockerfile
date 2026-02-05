FROM php:8.1-apache

# Install mysqli extension
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

# Enable Apache modules
RUN a2enmod rewrite

# Copy Apache configuration
RUN echo '<FilesMatch \.php$>' > /etc/apache2/conf-available/php.conf && \
    echo '    SetHandler application/x-httpd-php' >> /etc/apache2/conf-available/php.conf && \
    echo '</FilesMatch>' >> /etc/apache2/conf-available/php.conf && \
    a2enconf php

# Set the working directory
WORKDIR /var/www/html

# Copy project files
COPY . /var/www/html/

# Set permissions
RUN mkdir -p uploads/captains && \
    chmod -R 755 uploads && \
    chown -R www-data:www-data uploads && \
    chown -R www-data:www-data /var/www/html

# Expose port
EXPOSE 80
