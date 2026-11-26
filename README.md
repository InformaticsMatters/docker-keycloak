# The InformaticsMatters keycloak container image

![GitHub tag (latest by date)](https://img.shields.io/github/v/tag/informaticsmatters/docker-keycloak)

[![build](https://github.com/InformaticsMatters/docker-keycloak/actions/workflows/build.yaml/badge.svg)](https://github.com/InformaticsMatters/docker-keycloak/actions/workflows/build.yaml)
[![release](https://github.com/InformaticsMatters/docker-keycloak/actions/workflows/release.yaml/badge.svg)](https://github.com/InformaticsMatters/docker-keycloak/actions/workflows/release.yaml)

A specialised build of keycloak used by a number of InformaticsMatters projects.

Refer to to the keycloak [container documentation] for background information.

## Building and pushing
To build and push using the currently endorsed keyclock base image...

    docker build . -t informaticsmatters/keycloak:stable
    docker push informaticsmatters/keycloak:stable

To build and push using a specific keycloak base image, like `26.8.2`...

    KEYCLOAK_VERSION=26.8.2
    docker build . -t informaticsmatters/keycloak:${KEYCLOAK_VERSION} \
        --build-arg KEYCLOAK_VERSION=${KEYCLOAK_VERSION}
    docker push informaticsmatters/keycloak:${KEYCLOAK_VERSION}

## Testing
A smoke test builds the image and starts it with a PostgreSQL database.
The test checks the keycloak version, the readiness probe, the `master` realm
and the server log. Run it from the project root with the expected version: -

    ./test/smoke-test.sh 26.8.2

## Upgrading a deployed keycloak
Keycloak changes the database schema when a new version starts.
After the upgrade, the old version cannot use the database.
Before you upgrade, make a backup of the database.
To go back to the old version, restore the old image and the database backup.

From keycloak `26.0` the image ignores `KC_PROXY` and the
`legacy-logout-redirect-uri` SPI option, because keycloak removed them.
`KEYCLOAK_ADMIN` and `KEYCLOAK_ADMIN_PASSWORD` are deprecated
(but still work) and keycloak uses them only for a new database.

## Theme development
A docker compose file is provided to allow you to run a keycloak instance
with a database and a volume mounted for theme development. The compose file
will start a keycloak instance with a postgres database. For further information
and basic instruction on getting started read the comments inside the
theme development docker compose file: -

- docker-compose-theme-development.yaml

And, for instructions on how to develop themes, read the
[Keycloak theme development] documentation.

---

[container documentation]: https://www.keycloak.org/server/containers
[keycloak theme development]: https://www.keycloak.org/docs/latest/server_development/index.html#_themes
