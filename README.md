![GitHub release (with filter)](https://img.shields.io/github/v/release/moechs/openresty-docker?logo=github) ![Docker Image Version (tag latest semver)](https://img.shields.io/docker/v/moechs/openresty/latest?logo=docker&logoColor=%23fff) [![Docker Image CI](https://github.com/moechs/openresty-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/moechs/openresty-docker/actions/workflows/ci.yml)

# OpenResty
An Alpine-based OpenResty image with additional Nginx modules and Lua libraries.

## Build

Build the image from the repository root:

```sh
docker build -t moechs/openresty .
```

## Configuration

The image installs the repository's `nginx/` configuration under `/etc/nginx/` and uses the root `nginx.conf` as its entry point. The entry point includes:

* `main/*.conf` for main-context settings
* `modules/*.conf` for dynamic module loading
* `events/*.conf` for event settings
* `conf.d/*.conf` and `vhost/*.conf` for HTTP settings and virtual hosts
* `stream.conf` and `stream/*.conf` for stream settings

## Additional modules

* ngx_http_substitutions_filter_module
* ngx_http_geoip2_module
* ngx_brotli
* nginx-sticky-module-ng
* ModSecurity-nginx
* nginx-module-vts

## Lua modules

Installed with OpenResty's `opm` package manager:

* anjia0532/lua-resty-redis-util
* bungle/lua-resty-jq
* bungle/lua-resty-prettycjson
* bungle/lua-resty-session
* bungle/lua-resty-template
* bungle/lua-resty-validation
* cdbattags/lua-resty-jwt
* cloudflare/lua-resty-cookie
* fffonion/lua-resty-acme
* fffonion/lua-resty-openssl
* knyar/nginx-lua-prometheus
* ledgetech/lua-resty-http
* thibaultcha/lua-resty-mlcache
* xiangnanscu/lua-resty-ipmatcher
* xiaooloong/lua-resty-iconv

## Default backend

The `defaultbackend/` image can be used with [ingress-nginx](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/custom-http-errors: "404,403,500,502,503"
```

  It is based on [error-pages](https://github.com/tarampampam/error-pages).
