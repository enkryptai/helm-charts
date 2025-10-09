# Redteam Proxy Environment Variables

This service requires the following environment variables.  
Values are stored in remote secrets (`dev/enkryptai/redteaming`).

---

## 🤖 AI & Model Providers
- `OPENAI_API_KEY` – OpenAI API key
- `HF_TOKEN` – HuggingFace token
- `MISTRAL_API_KEY` – Mistral API key
- `GROQ_API_KEY` – Groq API key
- `GOOGLE_API_KEY` – Google API key
- `SMALLESTAI_API_KEY` – SmallestAI API key

---

## ☁️ Cloud & Storage
- `AZURE_STORAGE_CONNECTION_STRING` – Azure blob storage connection
- `REGION` – Deployment region
- `ACCESS_KEY_ID` – Cloud access key
- `SECRET_ACCESS_KEY` – Cloud secret key
- `ENDPOINT` – Cloud storage endpoint
- `SUPABASE_URL` – Supabase instance URL
- `SUPABASE_KEY` – Supabase API key
- `SUPABASE_STORAGE_URL` – Supabase storage bucket URL

---

## 📦 Services & Infrastructure
- `REDIS_URL` – Redis cache connection URL

---

## 📡 Proxy Config
- `PROXY_USERNAME`
- `PROXY_PASSWORD`
- `PROXY_SERVER`

---

## 📢 Integrations
- `SLACK_ALERT_ROOM_WEBHOOK_URL` – Slack alert channel webhook

---

## 🔑 Auth & Tokens
- `NEXTJS_AUTH_TOKEN` – Auth token for Next.js proxy
- `SIERRA_TOKEN` – Sierra integration token
- `SIERRA_RELEASE` – Sierra release version

---

## Notes
- Keep secrets in **AWS Secret Store** or Vault.
- Never commit `.env` files with values.
- For local dev, copy `.env.example` and fill manually.


