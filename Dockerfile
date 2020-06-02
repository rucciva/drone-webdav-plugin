FROM appropriate/curl

ARG HTTP_PROXY
ARG URL=https://github.com/ncw/rclone/releases/download/v1.46/rclone-v1.46-linux-amd64.zip
WORKDIR /tmp
RUN HTTP_PROXY=${HTTP_PROXY} curl -o rclone.zip -L $URL
RUN unzip rclone.zip

FROM alpine:3.11.6

RUN apk add --no-cache ca-certificates bash

COPY --from=0 /tmp/rclone-v1.46-linux-amd64/rclone /usr/bin/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/bin/bash", "-c" ]
CMD [ "/entrypoint.sh" ]