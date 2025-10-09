# Guardrails Environment Variables

This service requires the following environment variables.  
Values are stored in remote secrets (`dev/enkryptai/guardrails`).

---

## 🤖 AI & Model Providers
- `HF_TOKEN` – HuggingFace access token
- `OPENAI_API_KEY` – OpenAI API key
- `GEMINI_API_KEY` – Google Gemini API key

---

## ⚖️ Guardrails Configuration
- `DEBIAS_MODE` – Mode for debiasing (e.g., `strict`, `lenient`)
- `POLICY` – Policy config for model outputs

---

## 📡 Beam Integration
- `BEAM_URL` – Beam service endpoint
- `BEAM_API_KEY` – API key for Beam service

---

## Notes
- Keep all secrets in **Vault / AWS Secrets Manager**.
- Never commit `.env` files with actual values.
- For local development, create a `.env.example` with these keys and fill them manually.


