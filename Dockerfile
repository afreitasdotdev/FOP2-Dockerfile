FROM alpine:latest

ENV php_conf /etc/php5/php.ini
ENV fpm_conf /etc/php5/php-fpm.conf

# Get needed packages
RUN apk add --no-cache bash \
    wget \
    nginx \
    supervisor \
    alpine-sdk \
    php5-fpm \
    php5-mysql \
    php5-mysqli && \
    mkdir -p /etc/nginx && \
    mkdir -p /run/nginx && \
    mkdir -p /var/log/supervisor

# Supervisord config
ADD conf/supervisord.conf /etc/supervisord.conf

# Nginx config
RUN rm -Rf /etc/nginx/nginx.conf
ADD conf/nginx.conf /etc/nginx/nginx.conf

# Nginx site config
RUN mkdir -p /etc/nginx/sites-available/ && \
mkdir -p /etc/nginx/sites-enabled/ && \
rm -Rf /var/www/* && \
mkdir /var/www/html/
ADD conf/nginx-site.conf /etc/nginx/sites-available/default.conf
RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

# Tweak php-fpm config
RUN sed -i -e "s/user = nobody/user = nginx/g" ${fpm_conf} && \
sed -i -e "s/group = nobody/group = nginx/g" ${fpm_conf} && \
sed -i -e "s/;listen.mode = 0660/listen.mode = 0666/g" ${fpm_conf} && \
sed -i -e "s/;listen.owner = nobody/listen.owner = nginx/g" ${fpm_conf} && \
sed -i -e "s/;listen.group = nobody/listen.group = nginx/g" ${fpm_conf} && \
sed -i -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" ${fpm_conf} &&\
ln -s /etc/php5/php.ini /etc/php5/conf.d/php.ini && \
find /etc/php5/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# Link volume
ADD src/ /var/www/html/
WORKDIR /var/www/html/

# Get FOP2
RUN wget --output-document=fop2.tgz https://www.fop2.com/download/debian64
RUN tar xzf fop2.tgz
RUN pwd
WORKDIR /var/www/html/fop2
RUN make install
RUN ls -aRl

# Expose
EXPOSE 443 80
CMD ["/usr/bin/supervisord", "-n", "-c",  "/etc/supervisord.conf"]
