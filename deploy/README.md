# Production deployment with GHCR

This deployment avoids installing pnpm dependencies on the production server. GitHub Actions builds the web and server images; the server only pulls image layers.

## 1. Configure repository variables

Before merging the deployment pull request, open:

Settings > Secrets and variables > Actions > Variables

Create these repository variables:

- `NEXT_PUBLIC_SERVER_BASE_URL` — for example `https://api.example.com`
- `NEXT_PUBLIC_SUPABASE_URL` — your Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` — the browser-safe Supabase anon key

These values are compiled into the static web image. Do not put the service-role key, JWT secret, database password, or AI keys in repository variables.

## 2. Build images

After the workflow is on `main`, either push a matching change or run **Build production images** manually from the Actions tab.

It publishes:

- `ghcr.io/147196421/loomic-web:latest`
- `ghcr.io/147196421/loomic-server:latest`

Make the packages public in GitHub package settings, or authenticate the server with a fine-grained token that has read access to packages:

```bash
printf '%s' "$GHCR_READ_TOKEN" | docker login ghcr.io -u 147196421 --password-stdin
```

Do not save the token in shell history or commit it to the repository.

## 3. Configure the server

Copy the `deploy` directory to `/opt/loomic/deploy`, then:

```bash
cd /opt/loomic/deploy
cp .env.production.example .env.production
chmod 600 .env.production
```

Fill in the real Supabase and AI provider values. Never commit `.env.production`.

## 4. Start or update

```bash
cd /opt/loomic/deploy
docker compose --env-file .env.production -f docker-compose.production.yml pull
docker compose --env-file .env.production -f docker-compose.production.yml up -d
docker compose --env-file .env.production -f docker-compose.production.yml ps
```

The services bind only to loopback:

- Web: `127.0.0.1:8925`
- API/WebSocket: `127.0.0.1:8926`

Configure the host reverse proxy with separate public hostnames. For example:

- `app.example.com` -> `127.0.0.1:8925`
- `api.example.com` -> `127.0.0.1:8926`

Caddy and modern reverse proxies forward WebSockets automatically. For Nginx, make sure the API virtual host forwards the `Upgrade` and `Connection` headers.

## 5. Operations

```bash
# Logs
docker compose --env-file .env.production -f docker-compose.production.yml logs -f --tail=200

# Restart
docker compose --env-file .env.production -f docker-compose.production.yml restart

# Update to the latest images
docker compose --env-file .env.production -f docker-compose.production.yml pull
docker compose --env-file .env.production -f docker-compose.production.yml up -d

# Stop without deleting persisted external data
docker compose --env-file .env.production -f docker-compose.production.yml down
```

Supabase owns the persistent database, authentication, object storage, and PGMQ queue. Back up the Supabase project separately.
