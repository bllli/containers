FROM docker.io/golang:1.19.2-bullseye as builder

WORKDIR /build

ARG CADDY_VERSION=2.6.1

RUN set -eux; \
    go env -w GO111MODULE=on; \
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest; \
    xcaddy build v${CADDY_VERSION} \
    --with github.com/kirsch33/realip


FROM alpine

COPY --from=builder /build/caddy /usr/bin/caddy
