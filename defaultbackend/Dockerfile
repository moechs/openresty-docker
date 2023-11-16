ARG RESTY_IMAGE_BASE="moechs/openresty"
ARG RESTY_IMAGE_TAG="main"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

ADD main.conf /etc/nginx/main/default.conf
ADD modules.conf /etc/nginx/modules/modules.conf
ADD http.conf /etc/nginx/conf.d/common.conf
ADD vhost.conf /etc/nginx/vhost/default.conf
ADD error_page.conf /etc/nginx/error_page.conf

RUN chown -R nobody:nobody /etc/nginx

USER nobody

EXPOSE 8080
