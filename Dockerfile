FROM elixir:1.19-alpine AS builder
RUN apk add --no-cache build-base git bash openssl ncurses-libs
WORKDIR /app
RUN mix local.hex --force && mix local.rebar --force
ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}
COPY mix.exs mix.lock ./
RUN mix deps.get --only ${MIX_ENV} && mix deps.compile
COPY config/config.exs config/${MIX_ENV}.exs config/
COPY lib lib
COPY priv priv
RUN mix compile --warnings-as-errors
COPY config/runtime.exs config/
RUN mix release --overwrite

FROM elixir:1.19-alpine AS migrations
WORKDIR /app
RUN apk add --no-cache bash openssl ncurses-libs
ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}
COPY --from=builder /app ./
CMD ["mix", "ecto.setup"]

FROM alpine:3.23 AS runner
RUN apk add --no-cache libstdc++ openssl ncurses-libs bash
RUN addgroup -S prometheus && adduser -S prometheus -G prometheus
WORKDIR /app
ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}
ENV RELEASE_ROOT=/app
COPY --from=builder --chown=prometheus:prometheus /app/_build/${MIX_ENV}/rel/prometheus ./
USER prometheus
EXPOSE 4000
CMD ["sh", "-c", "bin/prometheus eval \"Prometheus.Release.setup\" && bin/prometheus start"]
