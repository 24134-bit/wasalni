FROM php:8.1-apache

# Install mysqli extension
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

# Set the working directory
WORKDIR /var/www/html

# Copy project files to the container
COPY . /var/www/html/

# Ensure permissions for uploads directory
RUN mkdir -p uploads/captains && chmod -R 755 uploads && chown -R www-data:www-data uploads

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Configure Apache to process PHP files
RUN echo "DirectoryIndex index.php index.html" >> /etc/apache2/apache2.conf && \
    echo "AddType application/x-httpd-php .php" >> /etc/apache2/apache2.conf

# Expose port 80
EXPOSE 80
