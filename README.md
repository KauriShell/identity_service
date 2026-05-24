# TrustBridge — Identity Service

Rails API for **authentication**, users, KYC, payout accounts, devices, in-app notifications, and service-to-service identity lookups. Issues JWT access tokens consumed by escrow and payment services. Default port **3000**.

## Ownership

**This service owns**

- User registration, sign-in/out, password reset, confirm/unlock (Devise JSON API)
- Phone **OTP** auth (`auth/send_otp`, `auth/verify_otp`)
- JWT access + refresh tokens (`auth/refresh`, denylist in Redis)
- KYC submissions and admin review
- Payout accounts, push **devices**, user notifications
- Service tenants (B2B API keys)
- Internal APIs: user lookup, transactional email, notification fan-out
- Admin: KYC tier limits, job dashboard settings
- Background jobs via **Solid Queue** (Mission Control at `/jobs`)

**Does not own**

- Escrow state or disputes → `escrow_service`
- Payments / M-Pesa → `payment_service`

## API surface (`config/routes.rb`)

| Area | Path | Notes |
|------|------|-------|
| Auth | `/api/v1/auth/*` | Devise: `sign_in`, `sign_up`, `sign_out`; OTP; `refresh`; `me` |
| Users | `/api/v1/users` | Profile CRUD, `permissions` |
| KYC | `/api/v1/kyc` | `submit`, `status`, admin `review` |
| Payout accounts | `/api/v1/payout_accounts` | CRUD, `set_primary` |
| Notifications | `/api/v1/notifications` | Inbox, `read`, `read_all` |
| Devices | `/api/v1/devices` | Push registration |
| Service tenants | `/api/v1/service_tenants` | API credentials |
| Internal | `/api/v1/internal/*` | `users/:id`, `notifications`, `emails` (service auth) |
| Admin | `/api/v1/admin/settings` | Jobs, KYC tiers |
| Health | `/api/v1/health` | Liveness |
| API docs | `/api-docs` | Swagger UI (Rswag) |

## Key directories

```
app/
├── controllers/api/v1/     # REST + Devise controllers
├── services/               # KYC, refresh tokens, token revocation
├── models/                 # User, KycVerification, Device, Notification, …
├── serializers/            # JSON responses
├── lib/identity/           # Permission helpers
└── mailers/                # Transactional email
config/
├── credentials.yml.enc     # Encrypted secrets (master.key local only)
└── queue.yml               # Solid Queue workers
swagger/v1/swagger.yaml     # OpenAPI spec
spec/requests/api_docs/     # Specs that regenerate swagger
```

## Requirements

- Ruby 3.2+
- PostgreSQL (`identity_service_development`)
- Redis

## Configuration

```bash
cp .env.example .env
```

| Variable | Notes |
|----------|--------|
| `DATABASE_*` | Postgres primary + replica (see `.env.example`) |
| `REDIS_URL` | Denylist, cache, Rack::Attack |
| `DEVISE_JWT_SECRET_KEY` | **Shared** with escrow + payment |
| `IDENTITY_SERVICE_TOKEN` | Service tenant token (match `escrow_service`) |
| `DEVISE_PEPPER` / `SERVICE_TOKEN_SALT` | Credential hashing |
| `AWS_*` | KYC document storage (S3 + KMS) |
| `ALLOWED_ORIGINS` / `ALLOWED_HOSTS` | CORS and host allowlist |
| `MISSION_CONTROL_JOBS_USER/PASSWORD` | `/jobs` basic auth |

## Deployment

### Vercel

**This repo cannot run on Vercel.** A `404: NOT_FOUND` with ID `cpt1::…` means Vercel has no app output for that URL.

Deploy **`trustbridge`** on Vercel and host identity elsewhere. See `trustbridge/docs/VERCEL_DEPLOY.md`.

### Recommended hosts (Docker)

- **Render** — use `render.yaml` in this repo (Blueprint deploy)
- **Railway / Fly.io** — `Dockerfile` target `production`, port `3000`
- **Local full stack** — root `docker compose up identity identity_jobs`

### Health check URL

Configure the platform probe to one of:

- `GET /api/v1/health` (recommended)
- `GET /up` or `GET /` (redirect to health)

### Required production env

Set at minimum: `SECRET_KEY_BASE`, `RAILS_MASTER_KEY`, `DEVISE_JWT_SECRET_KEY`, `DEVISE_PEPPER`, `SERVICE_TOKEN_SALT`, `ALLOWED_HOSTS` (include your public hostname), `DATABASE_*`, `REDIS_URL`, `AWS_*`, and a strong `MISSION_CONTROL_JOBS_PASSWORD`.

`ALLOWED_HOSTS` must include the hostname users hit (e.g. `identity-api.example.com`). Omitting it causes blocked requests in production (not Vercel’s HTML 404).

## Docker

From workspace root:

```bash
docker compose up --build identity identity_jobs
```

App: http://localhost:3000  
Swagger: http://localhost:3000/api-docs  
Jobs UI: http://localhost:3000/jobs (user `dev` / password `change-me` in compose)

```bash
docker compose exec identity ./bin/rails db:prepare
docker compose exec identity bundle exec rspec
```

## Local (non-Docker)

```bash
bundle install
bin/rails db:prepare
bin/rails server -p 3000
bin/jobs   # Solid Queue when USE_SOLID_QUEUE=1
```

## Tests

```bash
bundle exec rspec
```

Regenerate Swagger from request specs:

```bash
bundle exec rspec spec/requests/api_docs
```

## Related

- Web app auth proxy: `trustbridge` (`app/api/auth/*`)
- Mobile OTP flow: `trustbridge-mobile`
- KT doc: `../docs/identity_service_kt.md`
