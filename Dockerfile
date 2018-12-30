FROM alpine:edge
COPY source /

RUN set -euxo pipefail \
  && chmod +x /usr/local/bin/*.sh \
  && mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh \
  && apk add --no-cache bash shadow su-exec tini \
  && rm /bin/sh \
  && ln -sf /bin/bash /bin/sh \
  && usermod -s /bin/sh root \
  && groupadd -rg 500 core \
  && useradd -Nr -u 500 -g core -s /bin/sh -c core core

ENV ENV=/etc/profile
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/sh"]
