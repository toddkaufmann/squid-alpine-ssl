# FROM alpine:3.7
FROM alpine:3.18

LABEL maintainer="toddkaufmann@gmail.com"

#set enviromental values for certificate CA generation
ENV CN=squid.local \
    O=squid \
    OU=squid \
    C=US

#set proxies for alpine apk package manager
ARG all_proxy 

ENV http_proxy=$all_proxy \
    https_proxy=$all_proxy

# 2023-12-19 update
# (1/9) Installing ca-certificates (20230506-r0)

#4 2.132 ERROR: unable to select packages:
#4 2.134   openssl-3.1.4-r1:
#4 2.134     breaks: world[openssl=3.1.4-r2]
#4 2.134   squid-5.9-r0:
#4 2.134     breaks: world[squid=6.6-r0]

#    squid=6.6-r0 \
#    openssl=3.1.4-r2 \

RUN apk add --no-cache \
    squid=5.9-r0 \
    openssl=3.1.4-r1 \
    ca-certificates && \
    update-ca-certificates

COPY start.sh /usr/local/bin/
COPY openssl.cnf.add /etc/ssl
COPY conf/squid*.conf /etc/squid/

RUN cat /etc/ssl/openssl.cnf.add >> /etc/ssl/openssl.cnf

RUN chmod +x /usr/local/bin/start.sh

EXPOSE 3128
EXPOSE 4128

ENTRYPOINT ["/usr/local/bin/start.sh"]