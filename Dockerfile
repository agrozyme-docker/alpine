FROM alpine:3.8

RUN set -ex \
  && apk add --no-cache bash \
  && rm /bin/sh \
  && ln -sf /bin/bash /bin/sh

RUN set -ex \
  sed -ri \
  -e 's!:/bin/ash!:/bin/bash!g' \
  /etc/passwd \
  && export PS1=$(printf '%q' "'\u@\h:\w\$ '") \
  && sed -ri \  
  -e "s!export PS1=.*!export PS1=${PS1} !g" \
  /etc/profile 

COPY root/ /root/
CMD ["/bin/bash"]