import { useState } from 'react';
import type { ConfirmOptions } from './confirmTypes';
import { ConfirmDialog } from './ConfirmDialog';

interface PendingConfirm extends ConfirmOptions {
  resolve: (value: boolean) => void;
}

/**
 * Promise-based confirmation hook, so imperative handlers keep their shape:
 *
 *   const [confirm, dialog] = useConfirm();
 *   if (!await confirm({ title: '…' })) return;
 *   …
 *   return <>{content}{dialog}</>;
 */
export function useConfirm(): [
  (options: ConfirmOptions) => Promise<boolean>,
  React.ReactNode,
] {
  const [pending, setPending] = useState<PendingConfirm | null>(null);

  const confirm = (options: ConfirmOptions) =>
    new Promise<boolean>((resolve) => setPending({ ...options, resolve }));

  const settle = (value: boolean) => {
    pending?.resolve(value);
    setPending(null);
  };

  const dialog = (
    <ConfirmDialog
      open={!!pending}
      title={pending?.title ?? ''}
      message={pending?.message}
      confirmLabel={pending?.confirmLabel}
      cancelLabel={pending?.cancelLabel}
      tone={pending?.tone}
      onConfirm={() => settle(true)}
      onCancel={() => settle(false)}
    />
  );

  return [confirm, dialog];
}

export default useConfirm;
