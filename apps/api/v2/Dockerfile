FROM node:20-alpine AS build

ARG DATABASE_DIRECT_URL
ARG DATABASE_URL

WORKDIR /calcom

RUN set -eux;
RUN ln -s /usr/lib/libssl.so.3 /lib/libssl.so.3

ENV NODE_ENV="production"
ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV TURBO_TELEMETRY_DISABLED=1
ENV NEXT_TELEMETRY_DISABLED=1
ENV DO_NOT_TRACK=1
ENV DATABASE_DIRECT_URL=${DATABASE_DIRECT_URL}
ENV DATABASE_URL=${DATABASE_URL}

COPY . .

# Install dependencies with optimized yarn configuration
RUN yarn config set httpTimeout 1800000 && \
    yarn config set enableGlobalCache false && \
    yarn config set enableTelemetry false && \
    yarn config set enableProgressBars false && \
    yarn config set logFilters --json '[{"code":"YN0002","level":"discard"},{"code":"YN0013","level":"discard"}]' && \
    yarn config set nmMode hardlinks-local && \
    YARN_ENABLE_IMMUTABLE_INSTALLS=false yarn install --mode skip-build

# Run post-install scripts with reduced memory footprint
RUN NODE_OPTIONS="--max-old-space-size=1024" yarn run post-install || true

# Build prisma schema and make sure that it is linked to v2 node_modules
RUN yarn workspace @calcom/api-v2 run generate-schemas
RUN rm -rf apps/api/v2/node_modules
RUN yarn install --inline-builds

RUN yarn workspace @calcom/api-v2 run build

EXPOSE 80

CMD [ "yarn", "workspace", "@calcom/api-v2", "start:prod"]
