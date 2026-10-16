# Repository guidance

- This repository is a single Docker image, not an application package: the tracked runtime inputs are `Dockerfile` and `default.conf.template`; there is no package manager, test suite, linter, or typecheck configuration.
- The image serves the container's `/data` directory through Nginx on port `80`; preserve the `/data` mount and the `/health` endpoint when changing the Nginx config.
- `default.conf.template` is rendered to `/etc/nginx/conf.d/default.conf` at container startup with `envsubst`; edit the template rather than expecting a generated config file in the repository.
- Local validation is a Docker build followed by a container smoke test, for example: `docker build -t directory-index:local .`, then run with `-v /path/to/content:/data:ro -p 8080:80` and verify `curl http://localhost:8080/health` returns `OK`.
- The release workflow runs only for published GitHub releases. It uses Buildx/QEMU to publish the image for the platforms listed in `.github/workflows/docker.yml` to Docker Hub and GHCR, then runs Trivy; local changes alone do not trigger that workflow.
- Release builds depend on network access to download the pinned Tini binary in the `Dockerfile`, and publishing requires the workflow's Docker Hub and GHCR secrets.
