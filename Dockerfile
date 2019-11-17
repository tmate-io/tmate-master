FROM elixir:1.9-alpine AS build

RUN mix local.hex --force && mix local.rebar --force
RUN apk --no-cache add git npm

WORKDIR /build

COPY mix.exs .
COPY mix.lock .

ENV MIX_ENV prod

RUN mix deps.get
RUN mix deps.compile

COPY assets/package-lock.json assets/package-lock.json
COPY assets/package.json assets/package.json
RUN cd assets && npm install

COPY assets assets
RUN cd assets && npm run deploy

COPY lib lib
COPY test test
COPY config config
COPY priv/gettext priv/gettext
COPY priv/repo priv/repo
COPY rel rel

ENV HOSTNAME "master-0"
RUN mix do phx.digest, distillery.release --no-tar && \
        mkdir _build/lib-layer && \
        mv _build/prod/rel/tmate/lib/tmate* _build/lib-layer

### Minimal run-time image
FROM alpine:3.9

RUN apk --no-cache add ncurses-libs openssl ca-certificates bash

RUN adduser -D app

ENV MIX_ENV prod

WORKDIR /opt/app

# Copy release from build stage
# We copy in two passes to benefit from docker layers
# Note "COPY some_dir dst" will copy the content of some_dir into dst
COPY --from=build /build/_build/prod/rel/* .
COPY --from=build /build/_build/lib-layer lib/

USER app

RUN mkdir /tmp/app
ENV RELEASE_MUTABLE_DIR /tmp/app
ENV REPLACE_OS_VARS true

# Start command
CMD ["/opt/app/bin/tmate", "foreground"]
