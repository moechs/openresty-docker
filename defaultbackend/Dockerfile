ARG RESTY_IMAGE_BASE="moechs/openresty"
ARG RESTY_IMAGE_TAG="main"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

COPY main.conf /etc/nginx/main/default.conf
COPY modules.conf /etc/nginx/modules/modules.conf
COPY http.conf /etc/nginx/conf.d/common.conf
COPY vhost.conf /etc/nginx/vhost/default.conf
COPY error_page.conf /etc/nginx/error_page.conf
