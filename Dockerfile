FROM alpine:3.7
COPY source /

RUN set -euxo pipefail \
  && chmod +rx /usr/local/bin/* \
  && mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh \
  && apk add --no-cache bash rpm shadow su-exec tini lua5.3 \
  && rm /bin/sh \
  && ln -sf /bin/bash /bin/sh \
  && ln -sf /usr/bin/lua5.3 /usr/bin/lua  \
  && ln -sf /usr/bin/luac5.3 /usr/bin/luac  \
  && usermod -s /bin/sh root \
  && groupadd -rg 500 core \
  && useradd -Nr -u 500 -g core -s /bin/sh -c core core

ENV ENV=/etc/profile
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/sh"]
