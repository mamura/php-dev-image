#!/bin/bash
set -e

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

if [ ! -z "$PROJECT_WEBROOT" ]
then
    sed -i -e "s|/src/;|$PROJECT_WEBROOT;|g" /etc/nginx/conf.d/app.conf
    ln -sf /etc/nginx/conf.d/app.conf /etc/nginx/sites-available/app
    ln -sf /etc/nginx/conf.d/app.conf /etc/nginx/sites-enabled/app
    rm -f /etc/nginx/sites-enabled/default
fi

if [ ! -d /run/php/ ]
then
    mkdir /run/php/
    chown www-data:www-data /run/php/
fi
