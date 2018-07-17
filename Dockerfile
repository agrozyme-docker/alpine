FROM alpine:3.8

RUN set -ex \
  && apk add --no-cache bash \
  && sed -ri \
  -e 's!:/bin/ash!:/bin/bash!g' \
  /etc/passwd

CMD ["/bin/bash"]