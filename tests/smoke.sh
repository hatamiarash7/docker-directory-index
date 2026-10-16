#!/usr/bin/env bash
# Build first, then run: bash tests/smoke.sh directory-index:local
set -Eeuo pipefail
umask 022

image="${1:-directory-index:local}"
content=$(mktemp -d "${TMPDIR:-/tmp}/directory-index-test.XXXXXX")
container=""

cleanup() {
	result=$?
	trap - EXIT
	if [[ -n "$container" ]]; then
		if ((result != 0)); then
			docker logs "$container" >&2 || true
		fi
		docker rm --force "$container" >/dev/null
	fi
	rm -rf -- "$content"
	exit "$result"
}
trap cleanup EXIT

# Nginx workers must be able to traverse the temporary bind mount.
chmod 755 "$content"
mkdir -p "$content/nested/.git"
printf 'directory-index test\n' >"$content/file.txt"
printf 'nested file\n' >"$content/nested/file.txt"
printf 'space in filename\n' >"$content/with spaces.txt"
printf 'body { color: black; }\n' >"$content/style.css"
printf 'private\n' >"$content/.env"
printf 'private\n' >"$content/nested/.git/config"
ln -s /etc/passwd "$content/outside-link"
ln -s /etc "$content/outside-directory"

container=$(docker run --detach \
	--publish 127.0.0.1::80 \
	--volume "$content:/data:ro" \
	--env 'http_proxy=http://127.0.0.1:1' \
	"$image")
port=$(docker inspect --format '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' "$container")
base="http://127.0.0.1:$port"
http=(curl --disable --silent --show-error --noproxy '*' --max-time 5)

wait_for_health() {
	local attempt
	for ((attempt = 0; attempt < 30; attempt++)); do
		if "${http[@]}" --fail "$base/health" >/dev/null 2>&1; then
			return 0
		fi
		sleep 1
	done
}

wait_for_health

expect_status() {
	local expected=$1 path=$2 actual
	shift 2
	actual=$("${http[@]}" --output /dev/null --write-out '%{http_code}' "$@" "$base$path")
	if [[ "$actual" != "$expected" ]]; then
		printf 'Expected HTTP %s for %s, got %s\n' "$expected" "$path" "$actual" >&2
		return 1
	fi
}

[[ "$("${http[@]}" --fail "$base/health")" == OK ]]
"${http[@]}" --head "$base/health" >"$content/health-headers"
grep -Fiq 'Content-Type: text/plain' "$content/health-headers"
grep -Fiq 'Cache-Control: no-store' "$content/health-headers"
docker exec "$container" nginx -t
docker exec "$container" curl --fail --silent --show-error --noproxy '*' --max-time 3 http://127.0.0.1/health >/dev/null
"${http[@]}" --fail "$base/" >"$content/listing"
grep -Fq 'file.txt' "$content/listing"
grep -Fq 'nested/' "$content/listing"
if grep -Fq '.env' "$content/listing"; then
	printf 'Dotfile leaked into directory listing\n' >&2
	exit 1
fi
[[ "$("${http[@]}" --fail "$base/file.txt")" == 'directory-index test' ]]
[[ "$("${http[@]}" --fail "$base/nested/file.txt")" == 'nested file' ]]
[[ "$("${http[@]}" --fail "$base/with%20spaces.txt")" == 'space in filename' ]]
expect_status 200 /file.txt --head
expect_status 206 /file.txt --header 'Range: bytes=0-3'
expect_status 404 /missing
expect_status 404 /.env
expect_status 404 /%2eenv
expect_status 404 /nested/.git/config
expect_status 404 /outside-link
expect_status 404 /outside-directory/
expect_status 403 /file.txt --request POST
expect_status 403 /file.txt --request PUT --data 'not allowed'
expect_status 403 /file.txt --request DELETE
"${http[@]}" --head "$base/style.css" >"$content/headers"
grep -Fiq 'Content-Type: text/css' "$content/headers"
grep -Fiq 'X-Content-Type-Options: nosniff' "$content/headers"
grep -Fiq 'Cache-Control: no-cache' "$content/headers"
"${http[@]}" --head "$base/nested" >"$content/redirect"
grep -Fiq 'Location: /nested/' "$content/redirect"
if grep -Eiq '^Server: nginx/' "$content/headers"; then
	printf 'Nginx version leaked in Server header\n' >&2
	exit 1
fi

# The image healthcheck should become healthy, not merely return valid config.
for ((attempt = 0; attempt < 45; attempt++)); do
	health=$(docker inspect --format '{{.State.Health.Status}}' "$container")
	if [[ "$health" == healthy ]]; then
		break
	fi
	sleep 1
done
[[ "$health" == healthy ]]

# An empty mount must still provide a working health endpoint and an index.
docker stop --time 10 "$container" >/dev/null
[[ "$(docker inspect --format '{{.State.ExitCode}}' "$container")" == 0 ]]
docker rm "$container" >/dev/null
container=""
mkdir "$content/empty"
container=$(docker run --detach --publish 127.0.0.1::80 --volume "$content/empty:/data:ro" "$image")
port=$(docker inspect --format '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostPort}}' "$container")
base="http://127.0.0.1:$port"
wait_for_health
"${http[@]}" --fail "$base/health" >/dev/null
expect_status 200 /
printf '<h1>Custom index</h1>\n' >"$content/empty/index.html"
[[ "$("${http[@]}" --fail "$base/")" == '<h1>Custom index</h1>' ]]

printf 'All container smoke tests passed for %s\n' "$image"
