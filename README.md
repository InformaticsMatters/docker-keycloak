# The InformaticsMatters keycloak container image

A specialised build of keycloak used by a number of InformaticsMatters projects.

Refer to to the keycloak [container documentation] for background information.

## Building and pushing
To build and push using the currently endorsed keyclock base image...

    docker build . -t informaticsmatters/keycloak:stable
    docker push informaticsmatters/keycloak:stable

To build and push using a specific keycloak base image, like 18.0.0...

    KEYCLOAK_VERSION=18.0.0
    docker build . -t informaticsmatters/keycloak:${KEYCLOAK_VERSION} \
        --build-arg KEYCLOAK_VERSION=${KEYCLOAK_VERSION}
    docker push informaticsmatters/keycloak:${KEYCLOAK_VERSION}

---

[container documentation]: https://www.keycloak.org/server/containers