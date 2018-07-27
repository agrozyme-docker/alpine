FROM alpine:3.8
COPY source /

RUN set -euxo pipefail \
  && chmod +x /usr/local/bin/*.sh \
  && mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh \
  && apk add --no-cache shadow bash \
  && rm /bin/sh \
  && ln -sf /bin/bash /bin/sh \
  && usermod -s /bin/sh root \
  && groupadd -rg 500 core \
  && useradd -Nr -u 500 -g core -s /sbin/nologin -c core core

ENV ENV=/etc/profile
CMD ["/bin/sh"]
