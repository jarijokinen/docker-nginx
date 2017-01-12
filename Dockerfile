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
#   docker run -d -p 127.0.0.1:80:80 -v nginx-conf:/usr/local/nginx/conf \
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
  && tar -xzvf /tmp/nginx.tar.gz -C /tmp/nginx --strip-components=1

# Configure, compile and install nginx
WORKDIR /tmp/nginx
RUN ./configure \
  --with-http_gzip_static_module \
  --with-http_ssl_module \
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

EXPOSE 80
CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
