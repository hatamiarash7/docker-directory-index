# Directory Index

A Docker image that serves a read-only directory listing from `/data` using Nginx.

## Features

- Directory browsing with Nginx `autoindex`
- Read-only content serving: `GET` and `HEAD` are allowed; other methods are rejected
- Built-in `GET /health` endpoint for container and load-balancer checks
- Dotfiles are hidden, including nested `.env` and `.git` paths
- Symbolic links are not followed when serving content
- Multi-platform images published to Docker Hub and GitHub Container Registry

## Quick start

You need Docker Engine or Docker Desktop. Mount a dedicated directory at `/data` using a read-only bind mount. This example binds to localhost so the index is not exposed on every network interface:

```bash
mkdir -p public
printf 'Hello from Directory Index!\n' > public/hello.txt

docker run --detach \
  --name directory-index \
  --publish 127.0.0.1:8080:80 \
  --mount "type=bind,source=$PWD/public,target=/data,readonly" \
  --security-opt no-new-privileges:true \
  hatamiarash7/directory-index:latest
```

Open <http://localhost:8080> in a browser or use curl:

```bash
curl http://localhost:8080/
curl http://localhost:8080/health
```

The health endpoint returns `OK` with HTTP status `200`. The image includes an HTTP-based Docker health check. It checks Nginx availability, not whether `/data` is mounted or readable.

### Docker Compose

The included [`compose.yaml`](compose.yaml) serves `./public` at <http://localhost:8080>. With Docker Compose v2 installed, run:

```bash
mkdir -p public
docker compose up --detach
docker compose logs --follow
```

Stop it with `docker compose down`. Edit the bind mount source to serve a different directory. To expose the service beyond localhost, change the port mapping deliberately and add appropriate network access controls.

## Configuration

| Option            | Default   | Description                            |
| ----------------- | --------- | -------------------------------------- |
| Container port    | `80`      | Nginx HTTP port                        |
| Content directory | `/data`   | Directory exposed by the index         |
| Health endpoint   | `/health` | Returns `OK` without accessing `/data` |

Directories need read and execute permissions for the container's `nginx` worker user; files need read permission. Do not use `chmod 777` as a permissions fix. On SELinux hosts, an appropriate bind-mount label such as `:ro,Z` may be required.

Nginx serves `index.html` when present and lists directories otherwise. File types use Nginx's MIME mappings, sizes are shown in bytes, and listing timestamps are UTC. Content responses use `Cache-Control: no-cache` so clients revalidate stored copies. Requesting `/health` never serves a file with that name from the mount. Logs go to stdout/stderr (`docker logs directory-index`).

### Custom Nginx configuration

Edit [`default.conf.template`](default.conf.template) and rebuild, or mount a replacement template:

```bash
docker run --rm \
  --publish 127.0.0.1:8080:80 \
  --mount "type=bind,source=$PWD/public,target=/data,readonly" \
  --mount "type=bind,source=$PWD/default.conf.template,target=/etc/nginx/templates/default.conf.template,readonly" \
  directory-index:local
```

The official Nginx entrypoint renders templates into `/etc/nginx/conf.d` with `envsubst` at startup. There are no project-specific environment variables. Preserve `/data`, port `80`, and `/health` in custom configurations; the root filesystem must remain writable for generated config, the PID file, and Nginx temporary files.

## Security and behavior changes

- There is no authentication or TLS. Use a trusted network or a reverse proxy with HTTPS and access controls before exposing sensitive content.
- Mount only files intended to be shared. A read-only mount prevents writes through that mount, not downloads or host-side changes. Do not serve an entire home directory, repository, or private log directory.
- Dotfiles return `404`; symlinks cannot be used to serve files or browse directories. These restrictions also apply to content that older versions exposed. Remove these directives only after reviewing the consequences.
- Only `GET` and `HEAD` are accepted for content requests. The synthetic health endpoint returns `OK` independently of the request method.
- HTML, SVG, and other active content may be rendered by browsers. Do not share this image's origin with an authenticated application or treat it as a sandbox for untrusted uploads.
- The Nginx master starts as root, matching the official image, and workers drop privileges. This image does not promise arbitrary `--user` or read-only-root operation; `/data` should still be mounted read-only.

## Image registries and platforms

Images are published on releases as:

- Docker Hub: [`hatamiarash7/directory-index`](https://hub.docker.com/r/hatamiarash7/directory-index)
- GHCR: [`ghcr.io/hatamiarash7/directory-index`](https://github.com/hatamiarash7/docker-directory-index/pkgs/container/directory-index)

The release workflow targets `linux/386`, `linux/amd64`, `linux/arm/v5`, `linux/arm/v7`, `linux/arm64`, `linux/ppc64le`, and `linux/s390x`, matching the pinned base image's manifest. `linux/mips64le` is no longer available in the base image.

For reproducible deployments, pin a release tag or image digest instead of using `latest`.

## Local development and validation

This repository has no application package manager. You need Docker, Bash, and curl to run the container smoke tests:

```bash
docker build --tag directory-index:local .
bash tests/smoke.sh directory-index:local
```

[`tests/smoke.sh`](tests/smoke.sh) creates temporary fixtures, uses an automatically assigned localhost port, and cleans up its containers and fixtures. It verifies listings, nested files, URL-encoded names, `HEAD`, range requests, missing files, dotfiles, symlink restrictions, rejected write methods, response headers, Docker health, empty directories, and graceful shutdown. Optionally run `shellcheck tests/smoke.sh` for static shell checks.

The base image is pinned by version and multi-platform digest. Renovate proposes base-image updates; Dependabot maintains SHA-pinned GitHub Actions. Rebuild and run the tests after changing either runtime input.

## Releases

The [Docker workflow](.github/workflows/docker.yml) validates pull requests, pushes to `master`, manual runs, and published releases. Validation builds and tests the native runner image and scans it with Trivy. Fixable high/critical vulnerabilities fail validation before publishing. This is not a vulnerability scan or runtime test of every release architecture. Scan results are uploaded to GitHub Security on non-PR runs.

Only published GitHub releases publish images; a manual run is validation-only. The workflow requires:

- `DOCKERHUB_TOKEN`: a Docker Hub access token with permission to push this repository
- Optional `DOCKERHUB_USERNAME`: defaults to `hatamiarash7`
- GitHub Actions permission to write packages for GHCR

GHCR uses the job-scoped `GITHUB_TOKEN` with `packages: write`; a separate `GH_TOKEN` secret is not required. If the GHCR package already exists, grant this repository Actions access to it. SARIF uploads require code scanning to be available for the repository and `security-events: write`.

A release tagged `v1.2.3` publishes `v1.2.3`, `1.2.3`, and `latest`. Non-semantic release tags are also retained. Prereleases receive version tags but never update `latest`. Release builds include SBOM and provenance attestations and publish to both registries. Registry credentials are only used in the release publishing job.

## Contributing

1. Fork the repository.
2. Create a branch: `git switch --create my-change`.
3. Make the change and run the local Docker validation above.
4. Commit and push your branch.
5. Open a pull request with a description of the behavior or configuration change.

Please report bugs through the repository's issue tracker, including the image tag, platform, logs, and a minimal reproduction. Do not include sensitive filenames or private data in public reports. Report security vulnerabilities privately to the maintainer through the contact details on their [GitHub profile](https://github.com/hatamiarash7).

## Support

[![Donate with Bitcoin](https://img.shields.io/badge/Bitcoin-bc1qmmh6vt366yzjt3grjxjjqynrrxs3frun8gnxrz-orange)](https://donatebadges.ir/donate/Bitcoin/bc1qmmh6vt366yzjt3grjxjjqynrrxs3frun8gnxrz) [![Donate with Ethereum](https://img.shields.io/badge/Ethereum-0x0831bD72Ea8904B38Be9D6185Da2f930d6078094-blueviolet)](https://donatebadges.ir/donate/Ethereum/0x0831bD72Ea8904B38Be9D6185Da2f930d6078094)

<a href="https://payping.ir/@hatamiarash7"><img src="https://cdn.payping.ir/statics/Payping-logo/Trust/blue.svg" alt="Support via PayPing" height="128" width="128"></a>

## License

This project is available under the [MIT License](LICENSE).
