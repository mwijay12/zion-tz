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
- `VITE_DEMO_MODE` enables the local demo sign-in on deployed builds (`npm run dev` enables it automatically).

## Testing

```bash
npm run test:rules   # rules ⇄ portal role contract (part of npm test)
```

Verifying that Firebase really works — including the in-app **Kagua Wingu** probe, deploying rules/functions, and running the full emulator suite — is documented in [`docs/VERIFY_FIREBASE.md`](./docs/VERIFY_FIREBASE.md).

## Status

The portal builds, but it is a prototype. Firestore writes require a real, verified Firebase account with a `role` custom claim; the demo session (`isDemo: true`) can never write to Firestore. Do not use it with real member data until the P0 security work is complete.

See the root [README](../README.md) and [PLAN.md](../PLAN.md).

## UI kit (`src/components/ui/`)

Shared, dependency-free building blocks. Prefer these over new inline overlays so behaviour stays consistent across the fourteen office modules.

| Module | What it does |
|---|---|
| `Modal.tsx` | Accessible dialog: `role="dialog"`, focus on open, Escape to close, background scroll lock, mobile bottom-sheet layout. |
| `useConfirm.tsx` + `ConfirmDialog.tsx` | Promise-based confirmation for destructive actions (`const [confirm, dialog] = useConfirm()`), replacing `window.confirm`. |
| `Toast.tsx` + `toastStore.ts` | `useToast()` feedback after a write, replacing `alert()` and disappearing banners. |
| `States.tsx` | `EmptyState`, `SkeletonRows`, `SampleDataBadge` for honest empty/loading/demo states. |
| `ErrorBoundary.tsx` | Contains a module crash to that module and offers a retry, instead of blanking the portal. |
| `CloudHealthPanel.tsx` | Sidebar **Kagua Wingu** probe: proves whether this account can actually write to Firestore. |

Design tokens live at the top of `src/index.css`. Any custom property a component reads (`--font-cinzel`, `--primary-700`, `--text-main`, …) must be declared there for both light and dark themes; an undefined property silently drops the whole declaration.

## Conventions worth keeping

- **Data honesty.** Figures shown to leaders must come from a store (`memberStore`, `churchSync`) or carry a `SampleDataBadge`. Never print a literal head-count next to a live register.
- **Demo sessions are visible.** Anything a demo session cannot really do must say so, in the UI copy, not just in the docs.
- **Never swallow a Firestore error.** `catch` blocks around a cloud write must surface it (`useToast` + `describeFirebaseError`). A write that fails quietly is worse than one that fails loudly: the leader walks away believing the church has the record.
- **UI permissions must match `firestore.rules`.** `npm test` enforces this for the main collections; add a `WRITE_PATHS` entry when a module starts writing to a new collection.
- **Code splitting.** Browser-only heavy libraries (jsPDF, html2canvas) are imported inside the handler that needs them, and office modules are `lazy()`-loaded from `App.tsx`.
