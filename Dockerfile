FROM alpine:3.16 as builder

COPY build.sh /

RUN apk upgrade -Ua \
    && apk add bash \
    && /build.sh

FROM kong:2.8.3

USER root

#ENV PATH=/usr/local/openresty/bin:/usr/local/openresty/nginx/sbin:/usr/local/openssl/bin:/usr/local/luarocks/bin:$PATH

COPY --from=builder /usr/local/openresty /usr/local/openresty
COPY --from=builder /usr/local/luarocks /usr/local/luarocks
COPY --from=builder /usr/local/openssl /usr/local/openssl
COPY --from=builder /tmp/build/naxsi/naxsi_config/naxsi_core.rules /etc/kong

RUN sed -i "s/return \[\[/return \[\[\nenable_naxsi = true\nnaxsi_check_rules = \nnaxsi_json_log = false/g" /usr/local/share/lua/5.1/kong/templates/kong_defaults.lua \
  && sed -i '166i \ \ \ \ location /naxsi_block {\n        default_type text/html;\n        return 432 "<!DOCTYPE html><html><center><h1>432 Blocked by Naxsi</h1></center></html>";\n    }\n' /usr/local/share/lua/5.1/kong/templates/nginx_kong.lua \
  && sed -i '171i > if naxsi_json_log == "true" then\n    set $naxsi_json_log 1;\n> end\n' /usr/local/share/lua/5.1/kong/templates/nginx_kong.lua \
  && sed -i '176i > if enable_naxsi == "true" then\n        SecRulesEnabled;\n        DeniedUrl "/naxsi_block";\n\n        $\{\{NAXSI_CHECK_RULES\}\}\n> end\n' /usr/local/share/lua/5.1/kong/templates/nginx_kong.lua \
  && mkdir -pv /etc/kong/naxsi_rules \
  && echo "include /etc/kong/naxsi_rules/*.rules;" >> /etc/kong/custom_http.conf

#   && echo "include /etc/kong/naxsi_core.rules;" > /etc/kong/custom_http.conf \
#CMD ["sleep", "365d"]
