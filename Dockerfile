## Dockerfile for building an October CMS image with the following installed; Nginx, PHP-FPM.
## @updated : 11 Oct 2017

# The base Ubuntu 16 image.
FROM ubuntu:16.04

# Maintainer
MAINTAINER dev@vieo.co

# Make OS non-interactive so as to prevent apt from complaining.
#ARG DEBIAN_FRONTEND noninteractive

# Set container environment variables
ENV ENV_STATUS=production
ENV	PORT=8010

# Prep steps basic package requirements + October package/software requirements
RUN	apt-get update && \
		DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \ 
		DEBIAN_FRONTEND=noninteractive apt-get -y install curl nginx php php-pgsql php-fpm php-apcu pwgen unzip openssl php-curl php-gd php-mcrypt php-memcache php-memcached php-sqlite3 php-json php-cli php-mbstring phpunit git libphp-pclzip

## CONFIGURATIONS
# Nginx config
RUN	sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
		sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf && \
		echo "daemon off;" >> /etc/nginx/nginx.conf
		
COPY ./nginx-site.conf /etc/nginx/sites-available/default
		
# PHP-FPM config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.0/fpm/php.ini && \
		sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.0/fpm/php.ini && \
		sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.0/fpm/php.ini && \
		sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf && \
		sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf && \
		phpenmod mcrypt

# Composer install and config + October install and config
RUN cd ~ && \ 
		curl -sS https://getcomposer.org/installer -o composer-setup.php && \
		php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \ 
		rm -rf composer-setup.php && \
		cd /var/www/ && \
		rm -rf html/ &&\
		composer -n create-project october/october html && \
		chown -R www-data:www-data /var/www/html

# Forward request and error logs to docker log collector.
#RUN ln -sf /dev/stdout /var/log/nginx/access.log \
#	&& ln -sf /dev/stderr /var/log/nginx/error.log
		
# Copy source code and content to specified image directories
COPY docker-entrypoint.sh /usr/local/bin/

# Set the working directory
#WORKDIR /var/www

# Set a host volumes for the container to persist data.
#VOLUME ["/var/www"]

# Running port to be used by the container application.
# We can use predefined ENV variables with '$<env-name>'
EXPOSE $PORT

# The main entry point for the application
CMD ["/bin/bash", "docker-entrypoint.sh"]
