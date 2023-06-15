FROM nginx:1.25

ARG DATE_CREATED

LABEL maintainer="Arash Hatami <hatamiarash7@gmail.com>"
LABEL org.opencontainers.image.created=$DATE_CREATED
LABEL org.opencontainers.image.authors="hatamiarash7"
LABEL org.opencontainers.image.vendor="hatamiarash7"
LABEL org.opencontainers.image.title="Directory Index"
LABEL org.opencontainers.image.description="The first Persian comment system"
LABEL org.opencontainers.image.source="https://github.com/hatamiarash7/docker-directory-index"

COPY default.conf.template /etc/nginx/conf.d/

EXPOSE 80

CMD /bin/bash -c "envsubst < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"