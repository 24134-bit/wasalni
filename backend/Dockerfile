FROM php:8.1-apache

# Install mysqli extension
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

# Set the working directory
WORKDIR /var/www/html

# Copy project files to the container
COPY . /var/www/html/

# Ensure permissions for uploads directory
RUN mkdir -p uploads/captains && chmod -R 755 uploads && chown -R www-data:www-data uploads

# Enable Apache mod_rewrite (if needed for .htaccess)
RUN a2enmod rewrite

# Expose port 80 (Render automatically detects this)
EXPOSE 80
