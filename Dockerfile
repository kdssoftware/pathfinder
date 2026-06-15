FROM php:7.4-apache

RUN apt-get update && apt-get install -y \
    unzip \
    libzip-dev \
    git \
    libevent-dev \
    libssl-dev \
    pkg-config \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql zip pcntl sockets gd

RUN pecl install redis \
    && yes "" | pecl install event \
    && docker-php-ext-enable redis \
    && docker-php-ext-enable --ini-name zz-event.ini event

RUN a2enmod rewrite

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . /var/www/html/

RUN git config --global --add safe.directory /var/www/html

RUN if [ -f ".htaccess_HTTP" ]; then cp .htaccess_HTTP .htaccess; fi

RUN if [ -f "composer.json" ]; then composer install --no-dev --optimize-autoloader; fi

RUN mkdir -p tmp/cache logs history export conf \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 775 tmp logs history export conf

RUN echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/pathfinder.ini && \
    echo "max_input_vars = 3000" >> /usr/local/etc/php/conf.d/pathfinder.ini && \
    echo "max_execution_time = 120" >> /usr/local/etc/php/conf.d/pathfinder.ini && \
    echo "html_errors = 0" >> /usr/local/etc/php/conf.d/pathfinder.ini && \
    echo "session.save_handler = redis" >> /usr/local/etc/php/conf.d/pathfinder.ini && \
    echo "session.save_path = 'tcp://redis:6379'" >> /usr/local/etc/php/conf.d/pathfinder.ini

EXPOSE 80
