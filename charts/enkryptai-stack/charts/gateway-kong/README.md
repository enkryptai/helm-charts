# Gateway Environment Variables

These variables are required for **Gateway Migration** and **Gateway** services.  
All values are stored in remote secrets (`dev/enkryptai/gateway`).

---

## ⚙️ Core Kong Configuration
- `KONG_LOG_LEVEL`
- `KONG_PROXY_LISTEN`
- `KONG_ADMIN_LISTEN`
- `KONG_DATABASE`
- `KONG_PROXY_ACCESS_LOG`
- `KONG_SSL_PROTOCOLS`

---

## 🗄️ Postgres Configuration
- `KONG_PG_DATABASE`
- `KONG_PG_HOST`
- `KONG_PG_PORT`
- `KONG_PG_USER`
- `KONG_PG_PASSWORD`
- `KONG_PG_SSL`
- `KONG_PG_SSL_VERSION`
- `KONG_PG_SSL_REQUIRED`
- `KONG_PG_SSL_VERIFY`

---

## 🚦 Performance & Nginx
- `KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE`
- `KONG_NGINX_HTTP_KEEPALIVE_REQUESTS`
- `KONG_MEM_CACHE_SIZE`
- `KONG_UPSTREAM_KEEPALIVE_MAX_REQUESTS`

---

## 📊 Tracing & Observability
- `KONG_TRACING_INSTRUMENTATIONS`
- `KONG_TRACING_SAMPLING_RATE`

---

## 🔒 OpenFGA Config
- `DECK_OPENFGA_URL`
- `DECK_OPENFGA_STORE_ID`
- `DECK_OPENFGA_AUTHORIZATION_MODEL_ID`

---

## 🖥️ Dashboard Config
- `DECK_APP_DASHBOARD_DOMAIN`
- `DECK_APP_DASHBOARD_DOMAIN_URL`
- `DECK_APP_DASHBOARD_PORT`
- `DECK_APP_DASHBOARD_SCHEME`

---

## 📡 Integrations & Services
- `DECK_ELASTIC_HOST`
- `DECK_ENKRYPT_ENVIRONMENT`
- `DECK_FLUENT_BIT_HOST`
- `DECK_GUARDRAILS_HOST`
- `DECK_GUARDRAILS_PORT`
- `DECK_GUARDRAILS_SCHEME`

---

## 👤 Kong Admin Credentials
- `DECK_INTERNAL_KONG_ADMIN_EMAIL`
- `DECK_INTERNAL_KONG_ADMIN_USERNAME`
- `DECK_INTERNAL_KONG_ADMIN_PASSWORD`

---

## 🔑 KeyDB / Redis
- `DECK_KEYDB_HOST`

---

## 🛠️ Kong Deck
- `DECK_KONG_ADDR`
- `DECK_KONG_LOGS_PLUGIN_ELASTIC_BASIC_AUTH`

---

## 🏆 Leaderboard Config
- `DECK_LEADERBOARD_AUTH`
- `DECK_LEADERBOARD_CORS_ORIGIN`
- `DECK_LEADERBOARD_DETAILS_PASSWORD`
- `DECK_LEADERBOARD_HOST`
- `DECK_LEADERBOARD_PORT`
- `DECK_LEADERBOARD_PUBLIC_CONSUMER_API_KEY`
- `DECK_LEADERBOARD_PUBLIC_CONSUMER_EMAIL`
- `DECK_LEADERBOARD_SCHEME`

---

## 🌐 Frontend / Next.js
- `DECK_NEXT_JS_BASIC_AUTH`
- `DECK_VERCEL_PROTECTION_AUTH`

---

## 🧪 Red Teaming
- `DECK_RED_TEAMING_HOST`
- `DECK_RED_TEAMING_PORT`
- `DECK_RED_TEAMING_SCHEME`
- `DECK_RED_TEAMING_URL`

---

## 🧩 Sample Models
- `DECK_INITIAL_SAMPLE_MODEL_PASSWORD`
- `DECK_SAMPLE_MODEL_REAL_APIKEY`

---

## Notes
- Keep all values in **AWS Secrets Store** or Vault.
- Never commit secrets to `.env`.
- For local dev, copy `.env.example` and fill values.


