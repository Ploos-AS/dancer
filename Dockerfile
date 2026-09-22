# syntax=docker/dockerfile:1
ARG ALPINE_VERSION=3.22
FROM alpine:${ALPINE_VERSION} AS builder

ARG DANCER_VERSION=4.16
ARG DANCER_URL
ARG DANCER_SHA256

RUN apk add --no-cache build-base ca-certificates curl

WORKDIR /src
RUN test -n "$DANCER_URL" && test -n "$DANCER_SHA256" \
 && curl -fsSL "$DANCER_URL" -o dancer.tar.gz \
 && echo "$DANCER_SHA256  dancer.tar.gz" | sha256sum -c - \
 && mkdir source \
 && tar -xzf dancer.tar.gz -C source --strip-components=1

WORKDIR /src/source
# M0 qualification: keep build assumptions visible. Adjust only after the
# exact upstream 4.16 archive has been inspected and Alpine/musl tested.
RUN ./configure --prefix=/usr/local \
 && make -j"$(getconf _NPROCESSORS_ONLN)" \
 && make DESTDIR=/out install

FROM alpine:${ALPINE_VERSION}
RUN addgroup -S dancer && adduser -S -D -H -G dancer dancer \
 && mkdir -p /config /data \
 && chown -R dancer:dancer /config /data
COPY --from=builder /out/ /
USER dancer:dancer
WORKDIR /data
VOLUME ["/config", "/data"]
ENTRYPOINT ["/usr/local/bin/dancer"]
