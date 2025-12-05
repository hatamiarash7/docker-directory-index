FROM --platform=$BUILDPLATFORM nginx:1.29

ARG APP_VERSION="undefined@docker"
ARG DATE_CREATED
ENV TINI_VERSION=v0.19.0

LABEL org.opencontainers.image.title="Directory Index"
LABEL org.opencontainers.image.description="Directory index using Nginx"
LABEL org.opencontainers.image.url="https://github.com/hatamiarash7/docker-directory-index"
LABEL org.opencontainers.image.source="https://github.com/hatamiarash7/docker-directory-index"
LABEL org.opencontainers.image.vendor="hatamiarash7"
LABEL org.opencontainers.image.authors="hatamiarash7"
LABEL org.opencontainers.version="$APP_VERSION"
LABEL org.opencontainers.image.created="$DATE_CREATED"
LABEL org.opencontainers.image.licenses="MIT"

COPY default.conf.template /etc/nginx/conf.d/

# Add tini
ADD https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini /tini
RUN chmod +x /tini

EXPOSE 80

ENTRYPOINT ["/tini", "--"]

CMD ["/bin/bash", "-c", "envsubst < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]