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
# Upstream's generated Makefile owns CSPECIAL; passing CFLAGS alone is not enough.
# Keep the legacy compiler mode explicit and local to this old source tree.
RUN ./configure --prefix=/usr/local \
 && sed -i 's/##//g' list.h \
 && make -j"$(getconf _NPROCESSORS_ONLN)" CSPECIAL="-O2 -std=gnu89 -Wno-error=implicit-function-declaration" LDFLAGS="-lm" \
 && mkdir -p /out/usr/local/bin /out/usr/local/share/dancer /out/data \
 && cp ../dancer /out/usr/local/bin/dancer \
 && cp ../example/dancer.config ../example/dancer.users ../example/dancer.funcs ../example/dancer.explain /out/usr/local/share/dancer/ \
 && cp ../example/dancer.config ../example/dancer.users ../example/dancer.funcs ../example/dancer.explain /out/data/

FROM alpine:${ALPINE_VERSION}
RUN addgroup -S dancer && adduser -S -D -H -G dancer dancer \
 && mkdir -p /data \
 && chown -R dancer:dancer /data
COPY --from=builder /out/usr/local/bin/ /usr/local/bin/
COPY --from=builder /out/usr/local/share/dancer/ /usr/local/share/dancer/
COPY --from=builder --chown=dancer:dancer /out/data/ /data/
USER dancer:dancer
WORKDIR /data
ENTRYPOINT ["/usr/local/bin/dancer"]
