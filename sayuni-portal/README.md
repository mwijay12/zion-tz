# Zion Leadership Portal

The React and Vite web portal for Sayuni Jerusalem Church leaders. It is the publishing, care, media, reporting, and certificate workspace for the church.

## Run

```bash
npm install
cp .env.example .env.local
npm run dev
```

On PowerShell, use `Copy-Item .env.example .env.local`.

```bash
npm run build
npm run lint
```

## Environment

Copy `.env.example` to `.env.local` and fill in local values. Never commit `.env.local` or real API keys.

- `VITE_CLOUDINARY_CLOUD_NAME` and `VITE_CLOUDINARY_UPLOAD_PRESET` configure unsigned media uploads.
- `VITE_GEMINI_TTS_KEYS` is a local TTS prototype only. Browser variables are visible in the shipped bundle; production must use a server-side proxy.

## Status

The portal builds, but it is a prototype. Authentication is currently a local demo, Firestore writes are not reliably authenticated, and reports and certificates use browser print views. Do not use it with real member data until the P0 security work is complete.

See the root [README](../README.md) and [PLAN.md](../PLAN.md).
