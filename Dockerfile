# Dockerfile - alpine
# https://github.com/moechs/openresty-docker
# Official
# https://github.com/openresty/docker-openresty

ARG RESTY_IMAGE_BASE="alpine"
ARG RESTY_IMAGE_TAG="3.18"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

LABEL maintainer="moechs <68768084+moechs@users.noreply.github.com>"

ARG LUAJIT_VERSION=2.1-20230410
ARG RESTY_LUAROCKS_VERSION="3.9.2"
ARG NGINX_DIGEST_AUTH=1.0.0
ARG NGINX_SUBSTITUTIONS=b8a71eacc7f986ba091282ab8b1bbbc6ae1807e0
ARG GEOIP2_VERSION=a607a41a8115fecfc05b5c283c81532a3d605425
ARG MODSECURITY_VERSION=1.0.3
ARG MODSECURITY_LIB_VERSION=e9a7ba4a60be48f761e0328c6dfcc668d70e35a0
ARG OWASP_MODSECURITY_CRS_VERSION=v3.3.5
ARG LUA_RESTY_GLOBAL_THROTTLE_VERSION=0.2.0

# Docker Build Arguments
ARG RESTY_IMAGE_BASE="alpine"
ARG RESTY_IMAGE_TAG="3.18"
ARG RESTY_VERSION="1.21.4.3"
ARG RESTY_OPENSSL_VERSION="1.1.1w"
ARG RESTY_OPENSSL_PATCH_VERSION="1.1.1f"
ARG RESTY_OPENSSL_URL_BASE="https://www.openssl.org/source"
ARG RESTY_PCRE_VERSION="8.45"
ARG RESTY_PCRE_BUILD_OPTIONS="--enable-jit"
ARG RESTY_PCRE_SHA256="4e6ce03e0336e8b4a3d6c2b70b1c5e18590a5673a98186da90d4f33c23defc09"
ARG RESTY_J="4"
ARG RESTY_CONFIG_OPTIONS="\
    --http-client-body-temp-path=/var/run/openresty/client_body_temp/ \
    --http-fastcgi-temp-path=/var/run/openresty/fastcgi_temp/ \
    --http-uwsgi-temp-path=/var/run/openresty/uwsgi_temp/ \
    --http-scgi-temp-path=/var/run/openresty/scgi_temp/ \
    --http-proxy-temp-path=/var/run/openresty/proxy_temp/ \
    --with-compat \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    "
ARG RESTY_CONFIG_OPTIONS_MORE="\
    --with-stream_ssl_preread_module \
    --add-module=ngx_http_substitutions_filter_module-$NGINX_SUBSTITUTIONS \
    --add-dynamic-module=nginx-http-auth-digest-$NGINX_DIGEST_AUTH \
    --add-dynamic-module=ngx_http_geoip2_module-${GEOIP2_VERSION} \
    --add-dynamic-module=ngx_brotli \
    --add-dynamic-module=nginx-sticky-module-ng \
    --add-dynamic-module=ModSecurity-nginx-${MODSECURITY_VERSION} \
    "
ARG RESTY_LUAJIT_OPTIONS="--with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'"
ARG RESTY_PCRE_OPTIONS="--with-pcre-jit"
# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-pcre \
    --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include' \
    --with-ld-opt='-L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -Wl,-rpath,/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib' \
    "

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

RUN apk add --no-cache --virtual .build-deps \
        build-base \
        coreutils \
        curl \
        gd-dev \
        geoip-dev \
        libxslt-dev \
        linux-headers \
        make \
        perl-dev \
        readline-dev \
        zlib-dev \
        bash git gawk libmaxminddb-dev zlib patch yajl lmdb libxml2 autoconf automake libtool libcurl pcre lmdb yajl curl-dev \
    && apk add --no-cache \
        gd \
        geoip \
        libgcc \
        libxslt \
        zlib \
        bash perl curl wget openssl unzip ca-certificates tzdata libmaxminddb-libs \
    && cd /tmp \
    && git config --global --add core.compression -1 \
    && curl -fSL "${RESTY_OPENSSL_URL_BASE}/openssl-${RESTY_OPENSSL_VERSION}.tar.gz" -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && cd openssl-${RESTY_OPENSSL_VERSION} \
    && if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.1" ] ; then \
        echo 'patching OpenSSL 1.1.1 for OpenResty' \
        && curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1 ; \
    fi \
    && if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.0" ] ; then \
        echo 'patching OpenSSL 1.1.0 for OpenResty' \
        && curl -s https://raw.githubusercontent.com/openresty/openresty/ed328977028c3ec3033bc25873ee360056e247cd/patches/openssl-1.1.0j-parallel_build_fix.patch | patch -p1 \
        && curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1 ; \
    fi \
    && ./config \
      no-threads shared zlib -g \
      enable-ssl3 enable-ssl3-method \
      --prefix=/usr/local/openresty/openssl \
      --libdir=lib \
      -Wl,-rpath,/usr/local/openresty/openssl/lib \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install_sw \
    && cd /tmp \
    && curl -fSL https://downloads.sourceforge.net/project/pcre/pcre/${RESTY_PCRE_VERSION}/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && echo "${RESTY_PCRE_SHA256}  pcre-${RESTY_PCRE_VERSION}.tar.gz" | shasum -a 256 --check \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && cd /tmp/pcre-${RESTY_PCRE_VERSION} \
    && ./configure \
        --prefix=/usr/local/openresty/pcre \
        --disable-cpp \
        --enable-utf \
        --enable-unicode-properties \
        ${RESTY_PCRE_BUILD_OPTIONS} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && git clone --depth=1 https://github.com/ssdeep-project/ssdeep \
    && cd ssdeep/ && ./bootstrap && ./configure && make && make install \
    && cd /tmp \
    && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && sed -i 's#openresty#OWS#g' bundle/nginx-*/src/core/nginx.h \
    && sed -i 's#openresty#OWS#g' bundle/nginx-*/src/http/ngx_http_header_filter_module.c \
    && sed -i 's#openresty#OWS#g' bundle/nginx-*/src/http/ngx_http_special_response.c \
    && sed -i 's#server: nginx#server: ows#g' bundle/nginx-*/src/http/v2/ngx_http_v2_filter_module.c \
    && sed -i 's#nginx\[8\] = "\\x87\\x3d\\x65\\xaa\\xc2\\xa1\\x3e\\xbf"#nginx\[4\] = "\\x83\\xd5\\xcb\\x77"#g' bundle/nginx-*/src/http/v2/ngx_http_v2_filter_module.c \
    && curl -fSL https://github.com/atomx/nginx-http-auth-digest/archive/v${NGINX_DIGEST_AUTH}.tar.gz -o nginx-http-auth-digest-${NGINX_DIGEST_AUTH}.tar.gz \
    && tar xzf nginx-http-auth-digest-${NGINX_DIGEST_AUTH}.tar.gz \
    && curl -fSL https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/${NGINX_SUBSTITUTIONS}.tar.gz -o ngx_http_substitutions_filter_module-${NGINX_SUBSTITUTIONS}.tar.gz \
    && tar xzf ngx_http_substitutions_filter_module-${NGINX_SUBSTITUTIONS}.tar.gz \
    && curl -fSL https://github.com/leev/ngx_http_geoip2_module/archive/${GEOIP2_VERSION}.tar.gz -o ngx_http_geoip2_module-${GEOIP2_VERSION}.tar.gz \
    && tar xzf ngx_http_geoip2_module-${GEOIP2_VERSION}.tar.gz \
    && curl -fSL https://github.com/SpiderLabs/ModSecurity-nginx/archive/v${MODSECURITY_VERSION}.tar.gz -o ModSecurity-nginx-${MODSECURITY_VERSION}.tar.gz \
    && tar xzf ModSecurity-nginx-${MODSECURITY_VERSION}.tar.gz \
    && git clone --depth=1 https://github.com/google/ngx_brotli.git \
    && cd ngx_brotli && git submodule init && git submodule update && git submodule update && cd - \
    && git clone --depth=1 https://github.com/moechs/nginx-sticky-module-ng.git \
    && cd bundle/LuaJIT-${LUAJIT_VERSION} \
    && make -j8 TARGET_STRIP=@: CCDEBUG=-g XCFLAGS='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT' CC=cc PREFIX=/usr/local/openresty/luajit \
    && make install PREFIX=/usr/local/openresty/luajit \
    && cd /tmp \
    && git clone -n https://github.com/SpiderLabs/ModSecurity \
    && cd ModSecurity/ \
    && git checkout ${MODSECURITY_LIB_VERSION} \
    && git submodule init && git submodule update \
    && sh build.sh \
    && sed -i '115i LUA_CFLAGS=\"${LUA_CFLAGS} -DWITH_LUA_JIT_2_1\"' build/lua.m4 \
    && sed -i '117i AC_SUBST(LUA_CFLAGS)' build/lua.m4 \
    && ./configure \
      --prefix=/usr \
      --with-lua=/usr/local/openresty/luajit \
      --with-pcre=/usr/local/openresty/pcre \
      --disable-doxygen-doc \
      --disable-doxygen-html \
      --disable-examples \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && mkdir -p /etc/nginx/modsecurity \
    && cp unicode.mapping /etc/nginx/modsecurity/unicode.mapping \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} ${RESTY_LUAJIT_OPTIONS} ${RESTY_PCRE_OPTIONS} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && opm get knyar/nginx-lua-prometheus \
        xiangnanscu/lua-resty-ipmatcher \
        xiaooloong/lua-resty-iconv \
        bungle/lua-resty-prettycjson \
        bungle/lua-resty-template \
        bungle/lua-resty-validation \
        bungle/lua-resty-jq \
        fffonion/lua-resty-openssl \
        jkeys089/lua-resty-hmac \
        spacewander/lua-resty-rsa \
        c64bob/lua-resty-aes \
    && curl -fSL https://github.com/ElvinEfendi/lua-resty-global-throttle/archive/v${LUA_RESTY_GLOBAL_THROTTLE_VERSION}.tar.gz -o lua-resty-global-throttle-${LUA_RESTY_GLOBAL_THROTTLE_VERSION}.tar.gz && tar xzf lua-resty-global-throttle-${LUA_RESTY_GLOBAL_THROTTLE_VERSION}.tar.gz \
    && cd lua-resty-global-throttle-${LUA_RESTY_GLOBAL_THROTTLE_VERSION} \
    && make DESTDIR=/usr/local/openresty LUA_LIB_DIR=site/lualib install \
    && cd /tmp \
    && curl -fSL https://luarocks.github.io/luarocks/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && cd luarocks-${RESTY_LUAROCKS_VERSION} \
    && ./configure \
        --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit \
        --lua-suffix=jit-2.1.0-beta3 \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make build \
    && make install \
    && mkdir -p /etc/nginx \
    && cd /etc/nginx/ \
    && git clone -b ${OWASP_MODSECURITY_CRS_VERSION} https://github.com/coreruleset/coreruleset \
    && mv coreruleset owasp-modsecurity-crs && cd owasp-modsecurity-crs \
    && mv crs-setup.conf.example crs-setup.conf \
    && mv rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf \
    && mv rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf \
    && rm -rf .git* .*.yml *.md docs tests INSTALL KNOWN_BUGS LICENSE util/regression-tests \
    && mkdir -p /opt/modsecurity/var/log /opt/modsecurity/var/upload /opt/modsecurity/var/audit /var/log/audit /var/log/nginx /var/run/openresty /data/web \
    && chown -R nobody:nobody /opt/modsecurity /var/log /var/run/openresty /data/web \
    && rm -rf /usr/local/openresty/nginx/*_temp /usr/local/openresty/nginx/conf/* /usr/local/openresty/nginx/html \
    && cd /tmp && rm -rf \
        openssl-${RESTY_OPENSSL_VERSION}.tar.gz openssl-${RESTY_OPENSSL_VERSION} \
        pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
        openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
        lua-resty-global-throttle-${LUA_RESTY_GLOBAL_THROTTLE_VERSION}.tar.gz lua-resty-global-throttle-${LUA_RESTY_GLOBAL_THROTTLE_VERSION} \
        luarocks-${RESTY_LUAROCKS_VERSION} luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
        ssdeep ModSecurity \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* \
    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

# Add LuaRocks paths
# If OpenResty changes, these may need updating:
#    /usr/local/openresty/bin/resty -e 'print(package.path)'
#    /usr/local/openresty/bin/resty -e 'print(package.cpath)'
ENV LUA_PATH="/usr/local/openresty/site/lualib/?.ljbc;/usr/local/openresty/site/lualib/?/init.ljbc;/usr/local/openresty/lualib/?.ljbc;/usr/local/openresty/lualib/?/init.ljbc;/usr/local/openresty/site/lualib/?.lua;/usr/local/openresty/site/lualib/?/init.lua;/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/?/init.lua;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua"

ENV LUA_CPATH="/usr/local/openresty/site/lualib/?.so;/usr/local/openresty/lualib/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so"

# Copy nginx configuration files
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY nginx/ /etc/nginx/
COPY lualib/ /usr/local/openresty/site/lualib/
COPY data/ /usr/local/share/data/

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT

WORKDIR /etc/nginx
