# syntax=docker/dockerfile:1
ARG ALPINE_VERSION=3.22
FROM alpine:${ALPINE_VERSION} AS builder

ARG DANCER_VERSION=4.16
ARG DANCER_URL=https://downloads.sourceforge.net/project/dancer/dancer/4.16/dancer-4.16.tar.gz
ARG DANCER_SHA256=b61d754811a8cdb0ee0eb3ea50bae5d257f7eb070d5a94febfe7ba11728c1dca

RUN apk add --no-cache build-base ca-certificates curl
WORKDIR /src
RUN curl -fsSL "$DANCER_URL" -o dancer.tar.gz \
 && echo "$DANCER_SHA256  dancer.tar.gz" | sha256sum -c - \
 && mkdir source \
 && tar -xzf dancer.tar.gz -C source --strip-components=1

WORKDIR /src/source/src
# Dancer uses C89-era inline semantics. FreeBSD also qualifies it as gnu89.
ENV CFLAGS="-O2 -std=gnu89"
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
