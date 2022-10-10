# syntax=docker/dockerfile:1.4

ARG ZOOKEEPER_VERSION=3.6.3

FROM docker.io/bitnami/minideb:bullseye as builder

COPY --link --from=ghcr.io/bitcompat/gosu:1.14.0 /opt/bitnami/ /opt/bitnami/
COPY --link --from=ghcr.io/bitcompat/wait-for-port:1.0.3-bullseye-r1 /opt/bitnami/ /opt/bitnami/
COPY --link --from=ghcr.io/bitcompat/java:11.0.16.1-1-bullseye-r1 /opt/bitnami/java/ /opt/bitnami/java/

ARG JAVA_EXTRA_SECURITY_DIR="/bitnami/java/extra-security"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --link prebuildfs /
COPY --link rootfs /
RUN install_packages ca-certificates curl gzip tar

ARG ZOOKEEPER_VERSION

ADD --link https://dlcdn.apache.org/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz /opt/src/
RUN <<EOT bash
    set -eux
    cd /opt/src
    tar -xzf apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz

    mv apache-zookeeper-${ZOOKEEPER_VERSION}-bin /opt/bitnami/zookeeper
    chmod g+rwX /opt/bitnami
    chown 1001:1001 -R /opt/bitnami/zookeeper
    /opt/bitnami/scripts/zookeeper/postunpack.sh

    mkdir -p /opt/bitnami/zookeeper/licenses
    cp /opt/bitnami/zookeeper/LICENSE.txt /opt/bitnami/zookeeper/licenses/zookeeper-${ZOOKEEPER_VERSION}.txt
EOT

FROM docker.io/bitnami/minideb:bullseye as stage-0

COPY --link --from=builder /opt/bitnami /opt/bitnami

RUN <<EOT bash
    set -eux
    install_packages ca-certificates gzip libc6 procps tar zlib1g netcat xmlstarlet
    mkdir -p /bitnami/zookeeper/data
    ln -sv /opt/bitnami/scripts/zookeeper/entrypoint.sh /entrypoint.sh
    ln -sv /opt/bitnami/scripts/zookeeper/run.sh /run.sh
EOT

LABEL org.opencontainers.image.ref.name="${ZOOKEEPER_VERSION}-debian-11-r1" \
      org.opencontainers.image.title="zookeeper" \
      org.opencontainers.image.version="${ZOOKEEPER_VERSION}"

ARG TARGETARCH
ENV HOME="/" \
    OS_ARCH="${TARGETARCH}" \
    OS_FLAVOUR="debian-11" \
    OS_NAME="linux" \
    APP_VERSION="${ZOOKEEPER_VERSION}" \
    BITNAMI_APP_NAME="zookeeper" \
    JAVA_HOME="/opt/bitnami/java" \
    PATH="/opt/bitnami/java/bin:/opt/bitnami/common/bin:/opt/bitnami/zookeeper/bin:$PATH"

EXPOSE 2181 2888 3888 8080

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/zookeeper/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/zookeeper/run.sh" ]
