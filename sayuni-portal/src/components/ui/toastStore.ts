import { createContext, useContext } from 'react';

export type ToastTone = 'info' | 'success' | 'warning' | 'error';

export interface ToastInput {
  title: string;
  message?: string;
  tone?: ToastTone;
  /** Milliseconds before auto-dismiss. Errors stay longer by default. */
  durationMs?: number;
}

export interface ToastContextValue {
  push: (toast: ToastInput) => void;
}

export const ToastContext = createContext<ToastContextValue | null>(null);

/**
 * Access the toast queue. Falls back to a no-op so components stay usable in
 * tests and in any tree rendered without the provider.
 */
export function useToast(): ToastContextValue {
  return useContext(ToastContext) ?? { push: () => {} };
}
