import React from 'react';
import { AlertTriangle } from 'lucide-react';
import { Modal } from './Modal';
import type { ConfirmOptions } from './confirmTypes';

export type { ConfirmOptions } from './confirmTypes';

interface ConfirmDialogProps extends ConfirmOptions {
  open: boolean;
  busy?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

/**
 * In-app replacement for `window.confirm`.
 *
 * Native confirm dialogs are blocking, unstyled, and on several mobile
 * browsers (and inside an installed PWA) they render with the page's origin
 * rather than the church's branding — which reads as a scam prompt to a
 * non-technical leader. This keeps destructive confirmations on-brand.
 */
export const ConfirmDialog: React.FC<ConfirmDialogProps> = ({
  open,
  title,
  message,
  confirmLabel = 'Thibitisha',
  cancelLabel = 'Ghairi',
  tone = 'danger',
  busy = false,
  onConfirm,
  onCancel,
}) => (
  <Modal
    open={open}
    onClose={busy ? () => {} : onCancel}
    title={title}
    width={430}
    closeOnBackdrop={!busy}
    footer={
      <>
        <button
          type="button"
          className={tone === 'danger' ? 'btn-danger' : 'btn-primary'}
          onClick={onConfirm}
          disabled={busy}
          aria-busy={busy}
        >
          {busy ? '…' : confirmLabel}
        </button>
        <button type="button" className="btn-secondary" onClick={onCancel} disabled={busy}>
          {cancelLabel}
        </button>
      </>
    }
  >
    {message && (
      <div style={{ display: 'flex', gap: '0.6rem', alignItems: 'flex-start' }}>
        {tone === 'danger' && (
          <AlertTriangle size={17} style={{ color: 'var(--error)', flexShrink: 0, marginTop: 3 }} />
        )}
        <p style={{ margin: 0, fontSize: '0.86rem', lineHeight: 1.6, color: 'var(--text-muted)' }}>
          {message}
        </p>
      </div>
    )}
  </Modal>
);

export default ConfirmDialog;
