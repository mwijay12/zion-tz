import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { AlertTriangle, CheckCircle2, Info, X } from 'lucide-react';
import {
  ToastContext,
  type ToastInput,
  type ToastTone,
} from './toastStore';

interface ToastRecord extends ToastInput {
  id: string;
  tone: ToastTone;
}

const TONE_ICON: Record<ToastTone, React.ReactNode> = {
  info: <Info size={16} style={{ color: 'var(--primary)', flexShrink: 0 }} />,
  success: <CheckCircle2 size={16} style={{ color: 'var(--emerald)', flexShrink: 0 }} />,
  warning: <AlertTriangle size={16} style={{ color: 'var(--amber)', flexShrink: 0 }} />,
  error: <AlertTriangle size={16} style={{ color: 'var(--error)', flexShrink: 0 }} />,
};

/**
 * Lightweight feedback layer.
 *
 * The portal previously confirmed writes with `alert()` and with inline
 * banners that vanished on navigation, so a leader could not tell whether a
 * registration, payment or role grant had actually landed. Toasts keep the
 * result visible while the user keeps working.
 */
export const ToastProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [toasts, setToasts] = useState<ToastRecord[]>([]);
  const timers = useRef<Map<string, number>>(new Map());
  const counter = useRef(0);

  const dismiss = useCallback((id: string) => {
    setToasts((current) => current.filter((toast) => toast.id !== id));
    const timer = timers.current.get(id);
    if (timer) {
      window.clearTimeout(timer);
      timers.current.delete(id);
    }
  }, []);

  const push = useCallback((input: ToastInput) => {
    counter.current += 1;
    const id = `toast-${Date.now()}-${counter.current}`;
    const tone = input.tone || 'info';
    const durationMs = input.durationMs ?? (tone === 'error' ? 8000 : 4500);

    setToasts((current) => [...current.slice(-3), { ...input, id, tone }]);

    const timer = window.setTimeout(() => dismiss(id), durationMs);
    timers.current.set(id, timer);
  }, [dismiss]);

  // Clear pending timers if the provider unmounts (e.g. on sign-out).
  useEffect(() => {
    const map = timers.current;
    return () => {
      map.forEach((timer) => window.clearTimeout(timer));
      map.clear();
    };
  }, []);

  const value = useMemo(() => ({ push }), [push]);

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="ui-toast-stack no-print" role="status" aria-live="polite">
        {toasts.map((toast) => (
          <div key={toast.id} className="ui-toast" data-tone={toast.tone}>
            {TONE_ICON[toast.tone]}
            <div className="ui-toast-body">
              <div className="ui-toast-title">{toast.title}</div>
              {toast.message && <div className="ui-toast-msg">{toast.message}</div>}
            </div>
            <button
              type="button"
              onClick={() => dismiss(toast.id)}
              aria-label="Funga taarifa"
              style={{ color: 'var(--text-subtle)', flexShrink: 0, padding: 2 }}
            >
              <X size={14} />
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
};

export default ToastProvider;
