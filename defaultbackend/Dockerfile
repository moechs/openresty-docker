ARG RESTY_IMAGE_BASE="moechs/openresty"
ARG RESTY_IMAGE_TAG="main"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

COPY main.conf /etc/nginx/main/default.conf
COPY modules_geoip2.conf /etc/nginx/modules/http_geoip2.conf
COPY http_geoip2.conf /etc/nginx/conf.d/geoip2.conf
COPY vhost.conf /etc/nginx/vhost/default.conf
COPY error_page.conf /etc/nginx/error_page.conf
