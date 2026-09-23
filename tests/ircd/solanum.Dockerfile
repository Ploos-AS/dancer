FROM debian:13-slim AS builder
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates git build-essential libltdl-dev pkg-config meson ninja-build libsqlite3-dev flex bison libssl-dev \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
ARG SOLANUM_REF=main
RUN git clone --depth 1 --branch "$SOLANUM_REF" https://github.com/solanum-ircd/solanum.git .
RUN meson setup build --optimization 2 --prefix=/opt/solanum -Dopenssl=enabled \
 && meson compile -C build \
 && meson install -C build

FROM debian:13-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates libltdl7 libsqlite3-0 libssl3 \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --system --uid 10002 --home /var/lib/solanum --create-home solanum
COPY --from=builder /opt/solanum /opt/solanum
RUN mkdir -p /var/lib/solanum/etc /var/lib/solanum/logs /opt/solanum/logs /opt/solanum/var \
 && chown -R solanum:solanum /var/lib/solanum /opt/solanum/logs /opt/solanum/var
COPY --chown=solanum:solanum tests/ircd/solanum.conf /var/lib/solanum/etc/ircd.conf
USER solanum
WORKDIR /var/lib/solanum
ENTRYPOINT ["/opt/solanum/bin/solanum", "-foreground", "-configfile", "/var/lib/solanum/etc/ircd.conf"]
