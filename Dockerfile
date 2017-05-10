# docker-nginx
#
# Dockerfile for Nginx on Debian 9.0 (stretch)
#
# Copyright (c) 2017 Jari Jokinen. MIT License.
#
# USAGE:
#
#   docker build -t nginx .
#   docker volume create --name nginx-conf
#   docker volume create --name nginx-data
#   docker run -d -p 127.0.0.1:80:80 -p 127.0.0.1:443:443 \
#     -v nginx-conf:/usr/local/nginx/conf \
#     -v nginx-data:/usr/local/nginx/www nginx

FROM debian:stretch-slim
MAINTAINER Jari Jokinen <info@jarijokinen.com>

# Install required packages
RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/01recommends \
	&& apt-get update \
  && apt-get install -y \
    curl \
    gcc \
    libpcre3 \
    libpcre3-dev \
    libssl1.1 \
    libssl-dev \
    make \
    wget \
    zlib1g \
    zlib1g-dev

# Get the latest mainline nginx tarball and extract it
RUN wget http://nginx.org$( \
    curl -s http://nginx.org/en/download.html | grep .tar.gz \
    | grep -oP '/download/nginx.+?.tar.gz' | head -1 \
  ) -O /tmp/nginx.tar.gz \
  && mkdir /tmp/nginx \
  && tar -xf /tmp/nginx.tar.gz -C /tmp/nginx --strip-components=1

# Get the ngx_cache_purge module
RUN wget http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz \
    -O /tmp/ngx_cache_purge.tar.gz \
    && mkdir /tmp/ngx_cache_purge \
    && tar -xf /tmp/ngx_cache_purge.tar.gz -C /tmp/ngx_cache_purge \
    --strip-components=1

# Configure, compile and install nginx
WORKDIR /tmp/nginx
RUN ./configure \
  --with-http_gzip_static_module \
  --with-http_ssl_module \
  --add-module=/tmp/ngx_cache_purge \
  && make \
  && make install
WORKDIR /

# Clean up
RUN apt-get purge -y --auto-remove \
    curl \
    gcc \
    libpcre3-dev \
    libssl-dev \
    make \
    wget \
    zlib1g-dev \
  && rm -rf /tmp/* /var/lib/apt/lists/*

RUN groupadd -r nginx \
  && useradd -r -g nginx nginx \
  && chown -R nginx:nginx /usr/local/nginx

EXPOSE 80 443
CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
