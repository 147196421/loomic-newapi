FROM node:22-slim AS deps

RUN corepack enable && corepack prepare pnpm@10.26.2 --activate

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json tsconfig.base.json ./
COPY apps/web/package.json apps/web/
COPY packages/shared/package.json packages/shared/
COPY packages/config/package.json packages/config/
COPY packages/ui/package.json packages/ui/

RUN pnpm install --frozen-lockfile --ignore-scripts

FROM deps AS builder

ARG NEXT_PUBLIC_SERVER_BASE_URL=https://runtime-api.invalid
ARG NEXT_PUBLIC_SUPABASE_URL=https://runtime-supabase.invalid
ARG NEXT_PUBLIC_SUPABASE_ANON_KEY=runtime-supabase-anon-key

ENV NEXT_PUBLIC_SERVER_BASE_URL=$NEXT_PUBLIC_SERVER_BASE_URL
ENV NEXT_PUBLIC_SUPABASE_URL=$NEXT_PUBLIC_SUPABASE_URL
ENV NEXT_PUBLIC_SUPABASE_ANON_KEY=$NEXT_PUBLIC_SUPABASE_ANON_KEY

COPY apps/web/ apps/web/
COPY packages/shared/ packages/shared/
COPY packages/config/ packages/config/
COPY packages/ui/ packages/ui/

RUN pnpm --filter @loomic/shared build && pnpm --filter @loomic/web build

FROM nginx:1.27-alpine AS production

COPY apps/web/nginx.conf /etc/nginx/conf.d/default.conf
COPY apps/web/40-runtime-config.sh /docker-entrypoint.d/40-runtime-config.sh
COPY --from=builder /app/apps/web/out /usr/share/nginx/html

RUN chmod 755 /docker-entrypoint.d/40-runtime-config.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz >/dev/null || exit 1
