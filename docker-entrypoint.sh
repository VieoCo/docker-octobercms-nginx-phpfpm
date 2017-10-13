#!/bin/bash
# The container entry point for starting relevant services.
/etc/init.d/php7.0-fpm start && service nginx start