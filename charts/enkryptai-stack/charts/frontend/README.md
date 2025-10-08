# Environment Variables

This project requires the following environment variables to be set.  
Values are securely stored in remote secrets (`dev/enkryptai/frontend`).

---

## 🔑 Authentication & API Keys
- `APIAAS_KONG_BASIC_AUTH`
- `APIAAS_KONG_SERVICE_BASIC_AUTH`
- `APIAAS_KONG_URL`
- `NEXT_PUBLIC_APIAAS_KONG_URL`
- `ENCRYPTION_PASSPHRASE`
- `RESEND_API_KEY`

---

## 🌐 API & Frontend
- `NEXT_PUBLIC_API_URL`
- `NEXT_PUBLIC_ENVIRONMENT`
- `NEXT_PUBLIC_URL`

---

## 🗄️ Supabase
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `NEXT_PUBLIC_SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `NEXT_PUBLIC_LEADERBOARD_SUPABASE_URL`
- `NEXT_PUBLIC_LEADERBOARD_SUPABASE_ANON_KEY`
- `NEXT_PUBLIC_LEADERBOARD_SUPABASE_SERVICE_ROLE_KEY`

---

## 💳 Stripe
- `STRIPE_PUBLIC_KEY`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`

---

## 📊 Leaderboard
- `LEADERBOARD_BASIC_AUTH`

---

## 🔒 FGA (Fine-Grained Authorization)
- `FGA_API_URL`
- `FGA_STORE_ID`
- `FGA_MODEL_ID`

---

## ✉️ Invites
- `INVITATION_JWT_SECRET`

---

## 📈 Analytics
- `NEXT_PUBLIC_POSTHOG_HOST`
- `NEXT_PUBLIC_POSTHOG_KEY`

---

## 🧪 Sample Models
- `SAMPLE_MODEL_API_KEY`
- `SAMPLE_MODEL_PASSWORD`
- `SAMPLE_REPORTS_USER_ID`

---

## Notes
- Do **not** commit `.env` with actual values.
- For local development, copy `.env.example` and fill in required fields.


