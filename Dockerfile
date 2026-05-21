# syntax=docker/dockerfile:1.6
# hadolint: consistent syntax, BuildKit features (cache mounts), multi-stage AS casing

# Match Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.3.7
FROM ruby:${RUBY_VERSION}-alpine AS base

WORKDIR /rails

ENV BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_JOBS="4" \
    BUNDLE_RETRY="3"

# Throw-away build stage to reduce size of final image
FROM base AS build

ARG BUNDLE_WITHOUT="development:test"
ARG PRECOMPILE_BOOTSNAP="1"

# Install packages needed to build gems (vips removed — image_processing is not in Gemfile)
# hadolint ignore=DL3018
RUN --mount=type=cache,id=apk-cache,sharing=locked,target=/var/cache/apk \
    apk add --no-cache \
    build-base \
    git \
    libpq-dev \
    yaml-dev \
    pkgconfig \
    tzdata

COPY Gemfile Gemfile.lock ./

# Cache bundle downloads between builds (requires BuildKit: DOCKER_BUILDKIT=1)
RUN --mount=type=cache,id=bundle-cache-ruby33,sharing=locked,target=/usr/local/bundle/cache \
    if [ -n "${BUNDLE_WITHOUT}" ]; then bundle config set --local without "${BUNDLE_WITHOUT}"; fi && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    if [ "${PRECOMPILE_BOOTSNAP}" = "1" ]; then bundle exec bootsnap precompile --gemfile; fi

COPY . .

RUN if [ "${PRECOMPILE_BOOTSNAP}" = "1" ]; then bundle exec bootsnap precompile app/ lib/; fi

# Final stage for app image
FROM base AS runtime

# netcat-openbsd: tiny; used by docker-entrypoint to wait for Redis (avoids redis-server package)
# hadolint ignore=DL3018
RUN --mount=type=cache,id=apk-cache,sharing=locked,target=/var/cache/apk \
    apk add --no-cache \
    curl \
    libpq \
    yaml \
    tzdata \
    postgresql-client \
    netcat-openbsd \
    util-linux

RUN addgroup -S rails && adduser -S rails -G rails

COPY --from=build --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails

USER rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000

CMD ["./bin/rails", "server"]

# Local development (docker compose uses: build.target: development)
FROM runtime AS development

ENV RAILS_ENV="development" \
    BUNDLE_WITHOUT=""

# Production — keep this last so plain `docker build .` produces a production image
FROM runtime AS production

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_WITHOUT="development:test"
