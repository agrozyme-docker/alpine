FROM alpine:3.8

RUN set -euxo pipefail \
  && apk add --no-cache shadow bash \
  && rm /bin/sh \
  && ln -sf /bin/bash /bin/sh \
  && usermod -s /bin/sh root \
  && groupadd -rg 500 core \
  && useradd -MNr -u 500 -g core -d /dev/null -s /sbin/nologin -c core core

COPY source /

RUN set -euxo pipefail \
  && chmod +x /usr/local/bin/*.sh \
  && mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh

ENV ENV=/etc/profile
CMD ["/bin/sh"]
