FROM ubuntu:22.04

# Essentials
ENV TZ=America/Fortaleza
RUN echo $TZ > /etc/timezone \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -yqq \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    libaio-dev \
    g++ \
    make \
    zip \
    unzip \
    curl \
    nano \
    supervisor \
    bash \
    wget

RUN add-apt-repository ppa:ondrej/php \
    && apt-get -yqq update

WORKDIR /src

# NodeJS
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash \
    && source ~/.bashrc

RUN nvm install v20.18.0

# NGINX
RUN apt-get -y install nginx
COPY app.conf /etc/nginx/conf.d/app.conf

# PHP82
RUN apt-get update \
    && apt-get install -yqq php8.3 \
    php8.3-common \
    php8.3-fpm \
    php8.3-dev \
    php8.3-pdo \
    php8.3-opcache \
    php8.3-zip \
    php8.3-phar \
    php8.3-iconv \
    php8.3-cli \
    php8.3-curl \
    php8.3-mbstring \
    php8.3-tokenizer \
    php8.3-fileinfo \
    php8.3-xml \
    php8.3-xmlwriter \
    php8.3-simplexml \
    php8.3-dom \
    php8.3-tokenizer \
    php8.3-redis \
    php8.3-xdebug \
    php8.3-gd \
    php8.3-mysql \
    php8.3-ldap \
    php8.3-sqlite3 \
    php8.3-intl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configuracoes do PHP
RUN linhas=$(grep -m1 -n "listen =" /etc/php/8.3/fpm/pool.d/www.conf | cut -f1 -d:) \
    && sed -i "${linhas}d" /etc/php/8.3/fpm/pool.d/www.conf \
    && sed -i "${linhas}i listen=127.0.0.1:9000" /etc/php/8.3/fpm/pool.d/www.conf

RUN max_cli=$(grep -m1 -n "max_execution_time" /etc/php/8.3/cli/php.ini | cut -f1 -d:) \
    && sed -i "${max_cli}d" /etc/php/8.3/cli/php.ini \
    && sed -i "${max_cli}i max_execution_time = 240" /etc/php/8.3/cli/php.ini 

RUN max_fpm=$(grep -m1 -n "max_execution_time" /etc/php/8.3/fpm/php.ini | cut -f1 -d:) \
    && sed -i "${max_fpm}d" /etc/php/8.3/fpm/php.ini \
    && sed -i "${max_fpm}i max_execution_time = 240" /etc/php/8.3/fpm/php.ini 

# Composer
ARG HASH="`curl -sS https://composer.github.io/installer.sig`"
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === $HASH) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir=/bin --filename=composer
RUN php -r "unlink('composer-setup.php');"

# Supervisor
RUN mkdir -p /etc/supervisor.d/
COPY supervisord.ini /etc/supervisor.d/supervisord.ini

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=5s --start-period=30s CMD curl -f http://localhost || exit 1

CMD [ "supervisord", "-c", "/etc/supervisor.d/supervisord.ini" ]