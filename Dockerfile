#base image
FROM php:apache

# Arguments defined in docker-compose.yml
ARG user=user1
ARG uid=1000

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    vim

RUN apt-get update

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

#install php dependencies
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath 

#install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
&& composer --version

#copy laravelapp to apache folder
COPY --chown=${user}:www-data ./laravel-realworld-example-app/ /var/www/laravel-realworld-example-app/

RUN chmod -R 755 /var/www/laravel-realworld-example-app

#copy the env file
COPY ./.env /var/www/laravel-realworld-example-app/.env

# Create system user to run Composer and Artisan Commands
RUN mkdir -p /home/$user/.composer 
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN chown -R $user:$user /home/$user 
RUN chown -R $user:$user /var/www/laravel-realworld-example-app
RUN chmod -R 755 /var/www/laravel-realworld-example-app/storage/

#disable default apache conf file
RUN a2dissite 000-default

#create my conf file
COPY ./laravel.conf /etc/apache2/sites-available/laravel.conf

#enable my conf file
RUN a2ensite laravel.conf
RUN a2enmod rewrite

WORKDIR /var/www/laravel-realworld-example-app/

RUN composer install --ignore-platform-reqs
RUN php artisan config:clear 
RUN composer update --ignore-platform-reqs
RUN php artisan key:generate
RUN php artisan cache:clear
RUN php artisan route:clear
RUN php artisan view:clear



USER $user

EXPOSE 3000