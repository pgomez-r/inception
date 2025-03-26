#!/bin/bash

if [ ! -f /var/www/html/wp-content/initialized ]; then
  cp -r /initial-state/wp-content/* /var/www/html/wp-content/
  touch /var/www/html/wp-content/initialized
fi
