FROM alpine:3.8

RUN set -euxo pipefail \
  && apk add --no-cache shadow bash \
  && rm /bin/sh \
  && ln -sf /bin/bash /bin/sh

COPY source /

RUN set -euxo pipefail \
  && chmod +x /usr/local/bin/*.sh \
  && addgroup -g 500 -S core \
  && adduser -DHS -u 500 -G core -h /dev/null -s /sbin/nologin -g core core \
  && sed -ri -e 's!:/bin/ash!:/bin/bash!g' /etc/passwd \
  && export PS1=$(printf '%q' "'\u@\h:\w\$ '") \
  && sed -ri -e "s!export PS1=.*!export PS1=${PS1} !g" /etc/profile

CMD ["/bin/bash"]
