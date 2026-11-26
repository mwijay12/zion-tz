import React, { useEffect, useId, useRef } from 'react';
import { X } from 'lucide-react';

interface ModalProps {
  open: boolean;
  title: React.ReactNode;
  subtitle?: React.ReactNode;
  onClose: () => void;
  children: React.ReactNode;
  /** Rendered inside a flex footer with equal-width action buttons. */
  footer?: React.ReactNode;
  /** Max width in px. Defaults to 540. */
  width?: number;
  closeLabel?: string;
  /** Set false for destructive flows where a stray backdrop click is costly. */
  closeOnBackdrop?: boolean;
}

/**
 * Accessible dialog used by every admin surface.
 *
 * Why this exists: the modules each rolled their own fixed-position overlay
 * with inline styles. They could not be dismissed with Escape, they leaked a
 * scrollable background on iOS, and they had no focus management, which made
 * data-entry forms awkward on a phone — the main device for most leaders.
 */
export const Modal: React.FC<ModalProps> = ({
  open,
  title,
  subtitle,
  onClose,
  children,
  footer,
  width = 540,
  closeLabel = 'Funga',
  closeOnBackdrop = true,
}) => {
  const titleId = useId();
  const cardRef = useRef<HTMLDivElement>(null);

  // Escape to dismiss + lock background scroll while open.
  useEffect(() => {
    if (!open) return;

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.stopPropagation();
        onClose();
      }
    };

    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    document.addEventListener('keydown', onKeyDown);

    // Move focus into the dialog so keyboard and screen-reader users start
    // inside it rather than at the top of the page behind the overlay.
    const focusTimer = window.setTimeout(() => {
      const first = cardRef.current?.querySelector<HTMLElement>(
        'input, select, textarea, button, [href], [tabindex]:not([tabindex="-1"])'
      );
      first?.focus();
    }, 30);

    return () => {
      document.body.style.overflow = previousOverflow;
      document.removeEventListener('keydown', onKeyDown);
      window.clearTimeout(focusTimer);
    };
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      className="ui-modal-overlay no-print"
      onClick={closeOnBackdrop ? onClose : undefined}
    >
      <div
        ref={cardRef}
        className="ui-modal-card"
        style={{ maxWidth: `${width}px` }}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(event) => event.stopPropagation()}
      >
        <div className="ui-modal-header">
          <h3 id={titleId} className="ui-modal-title">
            {title}
          </h3>
          <button
            type="button"
            className="ui-modal-close"
            onClick={onClose}
            aria-label={closeLabel}
            title={closeLabel}
          >
            <X size={16} />
          </button>
        </div>

        {subtitle && <p className="ui-modal-subtitle">{subtitle}</p>}

        {children}

        {footer && <div className="ui-modal-footer">{footer}</div>}
      </div>
    </div>
  );
};

export default Modal;
