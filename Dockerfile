FROM alpine:3.8
COPY source /

RUN set -euxo pipefail \
  && chmod +x /usr/local/bin/*.sh \
  && mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh \
  && apk add --no-cache bash shadow sudo \
  && rm /bin/sh \
  && ln -sf /bin/bash /bin/sh \
  && usermod -s /bin/sh root \
  && groupadd -rg 500 core \
  && useradd -Nr -u 500 -g core -s /bin/sh -c core core \
  && sed -ri -e '/^[[:space:]]*root[[:space:]]+/ a core ALL=(ALL) NOPASSWD: ALL' /etc/sudoers \
  && /usr/sbin/visudo -cf /etc/sudoers

ENV ENV=/etc/profile
CMD ["/bin/sh"]
