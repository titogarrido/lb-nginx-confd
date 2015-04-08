FROM dockerfile/ubuntu

MAINTAINER Tito Garrido <titogarrido@gmail.com>

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Confd and nginx Installation
ENV CONFD_VERSION 0.8.0

# Install Nginx.
RUN \
	add-apt-repository -y ppa:nginx/stable && \
	apt-get update && \
	apt-get install -qqy nginx curl && \
	rm -rf /var/lib/apt/lists/* && \
	echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
        sed -i "s/# gzip/gzip/g" /etc/nginx/nginx.conf && \
	chown -R www-data:www-data /var/lib/nginx

RUN rm /etc/nginx/sites-enabled/default
RUN sed -i '/access_log/i\
log_format upstreamlog "[$time_local] ($status) from $remote_addr to: $upstream_addr: $request Upstream Response Time: $upstream_response_time Request time: $request_time";' /etc/nginx/nginx.conf
RUN sed -i 's/access\.log;/access\.log upstreamlog;/g' /etc/nginx/nginx.conf

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# Define mountable directories.
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html"]

ADD nginx.toml /etc/confd/conf.d/nginx.toml
ADD nginx.tmpl /etc/confd/templates/nginx.tmpl

WORKDIR /usr/local/bin
RUN \
    curl -s -L https://github.com/kelseyhightower/confd/releases/download/v$CONFD_VERSION/confd-$CONFD_VERSION-linux-amd64 -o confd; \
    chmod +x confd

# add confd-watch script
ADD /confd-watch /usr/local/bin/confd-watch
RUN chmod a+x /usr/local/bin/confd-watch

EXPOSE 80 443

CMD ["/usr/local/bin/confd-watch"]

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
