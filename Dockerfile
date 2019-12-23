FROM alpine:3.11
COPY rootfs /
ENV ENV="/etc/profile" LUA_PATH=";;/usr/local/bin/module/?.lua"

RUN set +e -uxo pipefail \
  && chmod +x /usr/local/bin/* \
  && apk add --no-cache luarocks5.3 \
  && ln -sf /usr/bin/lua5.3 /usr/bin/lua  \
  && ln -sf /usr/bin/luac5.3 /usr/bin/luac  \
  && ln -sf /usr/bin/luarocks-5.3 /usr/bin/luarocks  \
  && ln -sf /usr/bin/luarocks-admin-5.3 /usr/bin/luarocks-admin \
  && /usr/local/bin/docker-build.lua

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/sh"]
