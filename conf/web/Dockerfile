FROM mediawiki

ADD ./000-default.conf /etc/apache2/sites-enabled/000-default.conf
RUN /bin/bash -c 'apt update -yqq && \
                  apt install -yqq openssl && \
                  a2enmod ssl && \
                  mkdir -p /etc/ssl/certs/apache && \
                  openssl req -x509 \
                    -nodes \
                    -days 3650 \
                    -newkey rsa:2048 \
                    -subj "/C=US/O=Nexus Wiki/CN=nexus-wiki.org" \
                    -keyout /etc/ssl/certs/apache/nexus-wiki.org.key \
                    -out /etc/ssl/certs/apache/nexus-wiki.org.crt'
