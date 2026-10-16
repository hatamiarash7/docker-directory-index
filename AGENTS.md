# Repository guidance

- This repository is a single Docker image, not an application package: the runtime inputs are `Dockerfile` and `default.conf.template`; validation uses `tests/smoke.sh` rather than an application package manager or unit-test framework.
- The image serves the container's `/data` directory through Nginx on port `80`; preserve the `/data` mount and the `/health` endpoint when changing the Nginx config.
- The official Nginx entrypoint renders `/etc/nginx/templates/default.conf.template` to `/etc/nginx/conf.d/default.conf` with `envsubst`; edit the repository template rather than a generated config.
- Validate runtime changes with `docker build -t directory-index:local .` and `bash tests/smoke.sh directory-index:local`. The smoke script needs Bash, curl, and a local Docker daemon; it creates and cleans up its own fixtures and containers. Use `shellcheck tests/smoke.sh` when changing the script.
- Dotfiles and symlinks are intentionally blocked; preserve those restrictions and relative directory redirects when editing Nginx config. Keep `compose.yaml` localhost-only with a read-only content mount by default.
- `.github/workflows/docker.yml` validates PRs, pushes to `master`, manual runs, and published releases. Only published releases push images, after native smoke tests and the Trivy vulnerability gate pass. The remaining release platforms are built but not runtime-tested in CI.
- Keep release platforms aligned with the pinned base image's actual registry manifest. Renovate maintains the base-image version/digest; Dependabot maintains Actions. Publishing uses `DOCKERHUB_TOKEN` and the job-scoped `GITHUB_TOKEN` for GHCR; no separate GHCR PAT or Tini download is needed.
