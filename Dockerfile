FROM nginx:1.31.9@sha256:84f7876d21d154885f99554d7ae325d8c2213f9169726ea7ab60642f2573a787

ARG APP_VERSION="undefined@docker"
ARG DATE_CREATED=""
ARG VCS_REF=""

LABEL org.opencontainers.image.title="Directory Index" \
    org.opencontainers.image.description="A read-only directory index served by Nginx" \
    org.opencontainers.image.url="https://github.com/hatamiarash7/docker-directory-index" \
    org.opencontainers.image.source="https://github.com/hatamiarash7/docker-directory-index" \
    org.opencontainers.image.vendor="hatamiarash7" \
    org.opencontainers.image.authors="hatamiarash7" \
    org.opencontainers.image.version="$APP_VERSION" \
    org.opencontainers.image.revision="$VCS_REF" \
    org.opencontainers.image.created="$DATE_CREATED" \
    org.opencontainers.image.licenses="MIT"

# The official Nginx entrypoint renders templates from this directory with
# envsubst before starting Nginx.
COPY default.conf.template /etc/nginx/templates/default.conf.template

EXPOSE 80

STOPSIGNAL SIGQUIT

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD ["curl", "--fail", "--silent", "--show-error", "--noproxy", "*", "--max-time", "3", "--output", "/dev/null", "http://127.0.0.1/health"]

CMD ["nginx", "-g", "daemon off;"]
