FROM alpine:3.8
COPY rootfs /
ENV ENV="/etc/profile" LUA_PATH=";;/usr/local/bin/module/?.lua"

RUN set -uxo pipefail \
  && apk add --no-cache luarocks5.3 \
  && ln -sf /usr/bin/lua5.3 /usr/bin/lua  \
  && ln -sf /usr/bin/luac5.3 /usr/bin/luac  \
  && ln -sf /usr/bin/luarocks-5.3 /usr/bin/luarocks  \
  && ln -sf /usr/bin/luarocks-admin-5.3 /usr/bin/luarocks-admin \
  && lua /usr/local/bin/build/alpine.lua

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/sh"]
