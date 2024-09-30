# Dockerfile - alpine
# https://github.com/moechs/openresty-docker
# Official
# https://github.com/openresty/docker-openresty

ARG RESTY_IMAGE_BASE="alpine"
ARG RESTY_IMAGE_TAG="3.20"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

LABEL maintainer="moechs <68768084+moechs@users.noreply.github.com>"

ARG TZ=Asia/Shanghai

# Docker Build Arguments
ARG RESTY_VERSION="1.25.3.2"
ARG RESTY_OPENSSL_VERSION="1.1.1w"
ARG RESTY_OPENSSL_PATCH_VERSION="1.1.1f"
ARG RESTY_OPENSSL_URL_BASE="https://www.openssl.org/source"
ARG RESTY_PCRE_VERSION="8.45"
ARG RESTY_PCRE_BUILD_OPTIONS="--enable-jit"
ARG RESTY_PCRE_SHA256="4e6ce03e0336e8b4a3d6c2b70b1c5e18590a5673a98186da90d4f33c23defc09"
ARG RESTY_J="1"

ARG LUAJIT_VERSION=2.1-20231117.1
ARG RESTY_LUAROCKS_VERSION="3.11.0"
ARG NGINX_DIGEST_AUTH=1.0.0
ARG NGINX_SUBSTITUTIONS=e12e965ac1837ca709709f9a26f572a54d83430e
ARG NGINX_PROXY_CONNECT_VERSION=0.0.7
ARG NGINX_PROXY_CONNECT_PATCH=proxy_connect_rewrite_102101.patch
ARG GEOIP2_VERSION=a607a41a8115fecfc05b5c283c81532a3d605425
ARG MODSECURITY_VERSION=1.0.3
ARG MODSECURITY_LIB_VERSION=v3.0.12
ARG OWASP_MODSECURITY_CRS_VERSION=v4.4.0
ARG LUA_RESTY_GLOBAL_THROTTLE_VERSION=0.2.0
ARG LUA_VAR_NGINX_MODULE_VERSION=0.5.3

ARG RESTY_CONFIG_OPTIONS="\
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --modules-path=/usr/local/openresty/nginx/modules/ \
    --error-log-path=/var/log/openresty/error.log \
    --pid-path=/var/run/openresty/nginx.pid \
    --lock-path=/var/run/openresty/nginx.lock \
    --http-client-body-temp-path=/var/cache/openresty/client_body_temp/ \
    --http-fastcgi-temp-path=/var/cache/openresty/fastcgi_temp/ \
    --http-uwsgi-temp-path=/var/cache/openresty/uwsgi_temp/ \
    --http-scgi-temp-path=/var/cache/openresty/scgi_temp/ \
    --http-proxy-temp-path=/var/cache/openresty/proxy_temp/ \
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
    --with-http_v3_module \
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
    --add-module=ngx_http_substitutions_filter_module-${NGINX_SUBSTITUTIONS} \
    --add-module=lua-var-nginx-module-${LUA_VAR_NGINX_MODULE_VERSION} \
    --add-module=ngx_http_proxy_connect_module-${NGINX_PROXY_CONNECT_VERSION} \
    --add-dynamic-module=nginx-http-auth-digest-${NGINX_DIGEST_AUTH} \
    --add-dynamic-module=ngx_http_geoip2_module-${GEOIP2_VERSION} \
    --add-dynamic-module=ngx_brotli \
    --add-dynamic-module=nginx-sticky-module-ng \
    --add-dynamic-module=ModSecurity-nginx-${MODSECURITY_VERSION} \
    "

ARG LUAROCKS_PACKAGES="\
    lua-resty-ngxvar \
    lua-resty-redis-connector \
    lua-resty-auto-ssl \
    lua-resty-libcjson \
    lua-resty-jit-uuid \
    lua-resty-cookie \
    lua-resty-session \
    lua-resty-jwt \
    lua-resty-url \
    lua-resty-requests \
    lua-resty-etcd \
    lua-resty-kafka \
    lapis \
    "

ARG RESTY_LUAJIT_OPTIONS="--with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'"
ARG RESTY_PCRE_OPTIONS="--with-pcre-jit"

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-pcre \
    --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include' \
    --with-ld-opt='-L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -Wl,-rpath,/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib' \
    "

ENV TZ=${TZ}
# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/bin

# Add LuaRocks paths
# If OpenResty changes, these may need updating:
#    /usr/local/openresty/bin/resty -e 'print(package.path)'
#    /usr/local/openresty/bin/resty -e 'print(package.cpath)'
ENV LUA_PATH="/usr/local/openresty/site/lualib/?.ljbc;/usr/local/openresty/site/lualib/?/init.ljbc;/usr/local/openresty/lualib/?.ljbc;/usr/local/openresty/lualib/?/init.ljbc;/usr/local/openresty/site/lualib/?.lua;/usr/local/openresty/site/lualib/?/init.lua;/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/?/init.lua;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua"
ENV LUA_CPATH="/usr/local/openresty/site/lualib/?.so;/usr/local/openresty/lualib/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so"


RUN apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        bash \
        build-base \
        coreutils \
        curl-dev \
        gawk \
        gd-dev \
        geoip-dev \
        git \
        libcurl \
        libmaxminddb-dev \
        libtool \
        libxml2 \
        libxslt-dev \
        linux-headers \
        lmdb \
        make \
        perl-dev \
        readline-dev \
        yajl-dev \
        zlib-dev \
        patch \
        libcap \
    && apk add --no-cache \
        bash \
        ca-certificates \
        curl \
        diffutils \
        dumb-init \
        gd \
        geoip \
        jq \
        libcurl \
        libgcc \
        libmaxminddb-libs \
        libstdc++ \
        libxslt \
        openssl \
        perl \
        tzdata \
        unzip \
        util-linux \
        wget \
        yajl \
        zlib \
    && echo "/lib:/usr/lib:/usr/local/lib:/usr/local/openresty/luajit/lib:/usr/local/openresty/openssl/lib:/usr/local/openresty/pcre/lib" > /etc/ld-musl-$(uname -m).path \
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
    && curl -fSL https://github.com/api7/lua-var-nginx-module/archive/refs/tags/v${LUA_VAR_NGINX_MODULE_VERSION}.tar.gz -o lua-var-nginx-module-${LUA_VAR_NGINX_MODULE_VERSION}.tar.gz \
    && tar xzf lua-var-nginx-module-${LUA_VAR_NGINX_MODULE_VERSION}.tar.gz \
    && curl -fSL https://github.com/chobits/ngx_http_proxy_connect_module/archive/refs/tags/v${NGINX_PROXY_CONNECT_VERSION}.tar.gz -o ngx_http_proxy_connect_module-${NGINX_PROXY_CONNECT_VERSION}.tar.gz \
    && tar xzf ngx_http_proxy_connect_module-${NGINX_PROXY_CONNECT_VERSION}.tar.gz \
    && cd bundle/nginx-$(echo $RESTY_VERSION|cut -d . -f 1-3) && patch -p1 < ../../ngx_http_proxy_connect_module-${NGINX_PROXY_CONNECT_VERSION}/patch/${NGINX_PROXY_CONNECT_PATCH} && cd - \
    && git clone --depth=1 https://github.com/moechs/nginx-sticky-module-ng.git \
    && git clone --depth=1 https://github.com/google/ngx_brotli.git \
    && cd ngx_brotli && git submodule init && git submodule update && git submodule update && cd - \
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
      --with-yajl=/usr \
      --disable-doxygen-doc \
      --disable-doxygen-html \
      --disable-examples \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && mkdir -p /etc/nginx/modsecurity \
    && cp unicode.mapping /etc/nginx/modsecurity/unicode.mapping \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && sed -i 's#$ngx_prefix = "$prefix/nginx";#$ngx_prefix = "/etc/nginx";#g' configure \
    && eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} ${RESTY_LUAJIT_OPTIONS} ${RESTY_PCRE_OPTIONS} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && setcap    cap_net_bind_service=+ep /usr/sbin/nginx \
    && setcap -v cap_net_bind_service=+ep /usr/sbin/nginx \
    && setcap    cap_net_bind_service=+ep /usr/bin/dumb-init \
    && setcap -v cap_net_bind_service=+ep /usr/bin/dumb-init \
    && cd /tmp \
    && opm get knyar/nginx-lua-prometheus \
        xiangnanscu/lua-resty-ipmatcher \
        xiaooloong/lua-resty-iconv \
        bungle/lua-resty-prettycjson \
        bungle/lua-resty-template \
        bungle/lua-resty-validation \
        bungle/lua-resty-jq \
        fffonion/lua-resty-openssl \
        fffonion/lua-resty-acme \
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
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make build \
    && make install \
    && cd /tmp \
    && for pkg in ${LUAROCKS_PACKAGES};do luarocks install ${pkg};done \
    && mkdir -p /etc/nginx \
    && cd /etc/nginx/ \
    && git clone -b ${OWASP_MODSECURITY_CRS_VERSION} https://github.com/coreruleset/coreruleset \
    && mv coreruleset owasp-modsecurity-crs && cd owasp-modsecurity-crs \
    && mv crs-setup.conf.example crs-setup.conf \
    && mv rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf \
    && mv rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf \
    && rm -rf .git* .*.yml *.md docs tests INSTALL KNOWN_BUGS LICENSE util/regression-tests \
    && rm -rf /etc/nginx/*_temp /etc/nginx/conf/* /etc/nginx/html \
    && rm -f /usr/lib/libmodsecurity.a \
        /usr/lib/libmodsecurity.la \
        /usr/local/lib/libfuzzy.a \
        /usr/local/lib/libfuzzy.la \
        /usr/local/openresty/luajit/lib/libluajit-5.1.a \
        /usr/local/openresty/openssl/lib/libcrypto.a \
        /usr/local/openresty/openssl/lib/libssl.a \
        /usr/local/openresty/pcre/lib/libpcre.a \
        /usr/local/openresty/pcre/lib/libpcre.la \
        /usr/local/openresty/pcre/lib/libpcreposix.a \
        /usr/local/openresty/pcre/lib/libpcreposix.la \
    && cd /tmp && rm -rf \
        openssl-${RESTY_OPENSSL_VERSION}.tar.gz openssl-${RESTY_OPENSSL_VERSION} \
        pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
        openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
        lua-resty-global-throttle-${LUA_RESTY_GLOBAL_THROTTLE_VERSION}.tar.gz lua-resty-global-throttle-${LUA_RESTY_GLOBAL_THROTTLE_VERSION} \
        luarocks-${RESTY_LUAROCKS_VERSION} luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
        ssdeep ModSecurity \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* /etc/nginx/logs \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && ln -sf /dev/stdout /var/log/openresty/access.log \
    && ln -sf /dev/stderr /var/log/openresty/error.log \
    && ln -sf /var/log/openresty /etc/nginx/logs \
    && mkdir -p /opt/modsecurity/var/log /opt/modsecurity/var/upload /opt/modsecurity/var/audit \
        /var/log/audit /var/log/openresty /var/run/openresty /data/web /usr/local/data \
        /var/cache/openresty/client_body_temp \
        /var/cache/openresty/proxy_temp \
        /var/cache/openresty/fastcgi_temp \
        /var/cache/openresty/uwsgi_temp \
        /var/cache/openresty/scgi_temp \
        /var/cache/openresty/proxy_cache \
        /var/cache/openresty/auth_cache \
    && chown -R nobody:nobody /opt/modsecurity \
        /data \
        /var/log \
        /var/cache/openresty \
        /var/run/openresty \
        /usr/local/openresty \
        /etc/nginx \
    && curl -fSL $(curl -s https://api.github.com/repos/metowolf/qqwry.dat/releases/latest|jq -r '.assets[0].browser_download_url') -o /usr/local/data/qqwry.dat \
    && mmdb=$(curl -s https://api.github.com/repos/P3TERX/GeoLite.mmdb/releases/latest) \
    && curl -fSL $(echo $mmdb|jq -r '.assets[0].browser_download_url') -o /usr/local/data/$(echo $mmdb|jq -r '.assets[0].name') \
    && curl -fSL $(echo $mmdb|jq -r '.assets[1].browser_download_url') -o /usr/local/data/$(echo $mmdb|jq -r '.assets[1].name') \
    && curl -fSL $(echo $mmdb|jq -r '.assets[2].browser_download_url') -o /usr/local/data/$(echo $mmdb|jq -r '.assets[2].name') \
    && curl -fSL https://github.com/xluohome/phonedata/raw/master/phone.dat -o /usr/local/data/phone.dat \
    && echo Done!

# Copy nginx configuration files
COPY nginx/ /etc/nginx/
COPY lualib/ /usr/local/openresty/site/lualib/
COPY nginx.conf /etc/nginx/nginx.conf

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT

WORKDIR /etc/nginx
