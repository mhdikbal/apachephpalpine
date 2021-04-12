FROM alpine:latest

LABEL org.label-schema.schema-version="HTTPD +PHP alpine" 

WORKDIR /var/www/localhost/htdocs
COPY index.php /var/www/localhost/htdocs

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_DOCUMENT_ROOT /var/www/localhost/htdocs
ENV MAX_UPLOAD_SIZE 10M

# Setup apache and php
RUN apk --update \
    add apache2 \
    openrc \
    curl \
    php7-apache2 \
    php7-bcmath \
    php7-bz2 \
    php7-calendar \
    php7-common \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-gd \
    php7-iconv \
    php7-mbstring \
    php7-mysqli \
    php7-mysqlnd \
    php7-openssl \
    php7-pdo_mysql \
    php7-pdo_pgsql \
    php7-pdo_sqlite \
    php7-phar \
    php7-session \
    php7-xml \
    && rm -f /var/cache/apk/* \
    && mkdir -p /opt/utils \
    && mkdir /htdocs

RUN addgroup -g 1000 -S apache2 && \
    adduser -S -D -H -u 1000 -h /etc/apache2/ -s /sbin/nologin -G apache2 -g apache2  apache2 && \
    chown -R apache2:apache2 /var/www/ && \
    chown -R apache2:apache2 /etc/apache2 && \
    chown -R apache2:apache2 /var/log/apache2 && \
    chown -R apache2:apache2 /run/apache2 && \
    ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log 

RUN export phpverx=$(alpinever=$(cat /etc/alpine-release);[ ${alpinever//./} -ge 309 ] && echo  7|| echo 5)

RUN apk add apache2 php$phpverx-apache2 

RUN rc-update add apache2

EXPOSE 80

#ADD start.sh /opt/utils/

#RUN chmod +x /opt/utils/start.sh
#RUN /opt/utils/start.sh

RUN sed -i "s/#LoadModule\ rewrite_module/LoadModule\ rewrite_module/" /etc/apache2/httpd.conf \
    && sed -i "s/#LoadModule\ session_module/LoadModule\ session_module/" /etc/apache2/httpd.conf \ 
    && sed -i "s/#LoadModule\ session_cookie_module/LoadModule\ session_cookie_module/" /etc/apache2/httpd.conf \
    && sed -i "s/#LoadModule\ session_crypto_module/LoadModule\ session_crypto_module/" /etc/apache2/httpd.conf \
    && sed -i "s/#LoadModule\ deflate_module/LoadModule\ deflate_module/" /etc/apache2/httpd.conf \
    && sed -i "s#^DocumentRoot \".*#DocumentRoot \"/var/www/localhost/htdocs\"#g" /etc/apache2/httpd.conf \
    && printf "\n<Directory \"/var/www/localhost/htdocs\">\n\tAllowOverride All\n</Directory>\n" >> /etc/apache2/httpd.conf

HEALTHCHECK CMD wget -q --no-cache --spider localhost/index.html

ENTRYPOINT ["httpd","-D","FOREGROUND"]