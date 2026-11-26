#!/usr/bin/env bash

# A smoke test for the keycloak container image.
#
# The test builds the image, starts it with a PostgreSQL database,
# and then checks that: -
#
# - the keycloak version is the expected version
# - the server becomes ready (on the management port)
# - the 'master' realm is available under the '/auth' relative path
# - the server log contains no ERROR lines
#
# Usage (from the project root): -
#
#   ./test/smoke-test.sh <expected-keycloak-version>
#
# For example: -
#
#   ./test/smoke-test.sh 26.8.2

set -euo pipefail

expected_version="${1:?Provide the expected keycloak version}"

image="informaticsmatters/keycloak:smoke-test"
network="kc-smoke-test"
db_container="kc-smoke-test-db"
kc_container="kc-smoke-test-kc"
db_password="smoke-test-db"
admin_password="smoke-test-admin"
http_port="18080"
management_port="19000"

cleanup() {
    docker rm -f "${kc_container}" "${db_container}" >/dev/null 2>&1 || true
    docker network rm "${network}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

fail() {
    echo "FAIL: $*" >&2
    echo "--- keycloak log ---" >&2
    docker logs "${kc_container}" >&2 2>&1 || true
    exit 1
}

cleanup

echo "Building the image..."
docker build . -t "${image}" --quiet >/dev/null

echo "Checking the keycloak version..."
version_output="$(docker run --rm --entrypoint /opt/keycloak/bin/kc.sh "${image}" --version)"
actual_version="$(echo "${version_output}" | sed -n 's/^Keycloak \([0-9][^ ]*\).*/\1/p')"
if [[ "${actual_version}" != "${expected_version}" ]]; then
    fail "Expected keycloak ${expected_version} but found '${actual_version}'"
fi

echo "Starting the database..."
docker network create "${network}" >/dev/null
docker run -d --name "${db_container}" --network "${network}" \
    --network-alias database \
    -e POSTGRES_USER=keycloak \
    -e POSTGRES_PASSWORD="${db_password}" \
    postgres:15.10-alpine >/dev/null

for _ in $(seq 1 30); do
    if docker exec "${db_container}" pg_isready -U keycloak -d keycloak >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

echo "Starting keycloak..."
docker run -d --name "${kc_container}" --network "${network}" \
    -e KC_HOSTNAME=http://localhost:${http_port}/auth \
    -e KC_HTTP_ENABLED=true \
    -e KC_DB_PASSWORD="${db_password}" \
    -e KEYCLOAK_ADMIN_PASSWORD="${admin_password}" \
    -p "${http_port}:8080" \
    -p "${management_port}:9000" \
    "${image}" >/dev/null

echo "Waiting for keycloak to be ready..."
ready="false"
for _ in $(seq 1 120); do
    if curl -skf "https://localhost:${management_port}/auth/health/ready" >/dev/null 2>&1; then
        ready="true"
        break
    fi
    if [[ "$(docker inspect -f '{{.State.Running}}' "${kc_container}")" != "true" ]]; then
        fail "The keycloak container stopped"
    fi
    sleep 1
done
if [[ "${ready}" != "true" ]]; then
    fail "Keycloak did not become ready"
fi

echo "Checking the master realm..."
if ! curl -sf "http://localhost:${http_port}/auth/realms/master" >/dev/null; then
    fail "The master realm is not available at /auth/realms/master"
fi

echo "Checking the log for errors..."
if docker logs "${kc_container}" 2>&1 | grep -q ' ERROR '; then
    fail "The keycloak log contains ERROR lines"
fi

echo "Log warnings (for information)..."
docker logs "${kc_container}" 2>&1 | grep ' WARN ' || true

echo "PASS: keycloak ${actual_version}"
