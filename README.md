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
| `DATABASE_URL` | Postgres |
| `REDIS_URL` | Sessions, denylist, cache |
| `DEVISE_JWT_SECRET_KEY` | **Shared** with escrow + payment |
| `DEVISE_PEPPER` / `SERVICE_TOKEN_SALT` | Credential hashing |
| `AWS_*` | KYC document storage (S3 + KMS) |
| `MISSION_CONTROL_JOBS_USER/PASSWORD` | `/jobs` basic auth |

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
