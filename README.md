![GitHub release (with filter)](https://img.shields.io/github/v/release/moechs/openresty-docker?logo=github) ![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/moechs/openresty/latest?logo=docker&logoColor=%23fff) [![Docker Image CI](https://github.com/moechs/openresty-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/moechs/openresty-docker/actions/workflows/ci.yml)

# OpenResty
Alpine version of OpenResty with luarocks and many additional modules

### Config Files
* /etc/nginx/modules/*.conf  (load_module)
* /etc/nginx/conf.d/*.conf (http)
* /etc/nginx/vhost/*.conf (server)
* /etc/nginx/stream/*.conf (stream)

### Additional modules
* lua-var-nginx-module
* ngx_http_substitutions_filter_module
* nginx-http-auth-digest
* ngx_http_geoip2_module
* ngx_http_proxy_connect_module
* ngx_brotli
* nginx-sticky-module-ng
* stream_ssl_preread_module
* ModSecurity-nginx

### Installed lua modules
* anjia0532/lua-resty-redis-util
* bungle/lua-resty-jq
* bungle/lua-resty-prettycjson
* bungle/lua-resty-session
* bungle/lua-resty-template
* bungle/lua-resty-validation
* c64bob/lua-resty-aes
* fffonion/lua-resty-acme
* fffonion/lua-resty-openssl
* jkeys089/lua-resty-hmac
* knyar/nginx-lua-prometheus
* spacewander/lua-resty-rsa
* xiangnanscu/lua-resty-ipmatcher
* xiaooloong/lua-resty-iconv


Official OpenResty packaging source and scripts: [https://github.com/openresty/openresty-packaging.git](https://github.com/openresty/openresty-packaging.git)

----------------

# defaultbackend

This can be configured to work with the [ingress-nginx](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx)

### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/custom-http-errors: "404,403,500,502,503"
    nginx.ingress.kubernetes.io/server-snippet: |
      location /error_page/ {
        proxy_pass http://ingress-nginx-defaultbackend.ingress-nginx.svc;
        proxy_set_header X-Forwarded-For $remote_addr;
      }
```

See also [https://github.com/tarampampam/error-pages](https://github.com/tarampampam/error-pages)
