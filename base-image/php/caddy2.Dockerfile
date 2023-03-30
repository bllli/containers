FROM docker.io/golang:1.19.2-bullseye as builder

WORKDIR /build

ARG CADDY_VERSION=v2.6.1

RUN set -eux; \
    go env -w GO111MODULE=on; \
    go env -w GOPROXY=https://goproxy.cn,direct; \
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest; \
    xcaddy build ${CADDY_VERSION} \
    --with github.com/kirsch33/realip


FROM alpine

COPY --from=builder /build/caddy /usr/bin/caddy
