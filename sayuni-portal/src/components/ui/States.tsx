import React from 'react';
import { Inbox } from 'lucide-react';

interface EmptyStateProps {
  title: string;
  hint?: string;
  icon?: React.ReactNode;
  action?: React.ReactNode;
}

/** Consistent "there is nothing here yet" panel, instead of a blank table. */
export const EmptyState: React.FC<EmptyStateProps> = ({ title, hint, icon, action }) => (
  <div className="ui-empty">
    <div className="ui-empty-icon">{icon ?? <Inbox size={20} />}</div>
    <div style={{ fontWeight: 700, color: 'var(--text-headline)', fontSize: '0.9rem' }}>{title}</div>
    {hint && <div style={{ maxWidth: '44ch' }}>{hint}</div>}
    {action && <div style={{ marginTop: '0.5rem' }}>{action}</div>}
  </div>
);

interface SkeletonRowsProps {
  rows?: number;
  columns?: number;
}

/** Placeholder rows while a Firestore collection resolves. */
export const SkeletonRows: React.FC<SkeletonRowsProps> = ({ rows = 4, columns = 4 }) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem', padding: '0.35rem 0' }} aria-hidden="true">
    {Array.from({ length: rows }).map((_, rowIndex) => (
      <div
        key={rowIndex}
        style={{
          display: 'grid',
          gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))`,
          gap: '0.75rem',
          opacity: 1 - rowIndex * 0.16,
        }}
      >
        {Array.from({ length: columns }).map((__, columnIndex) => (
          <div
            key={columnIndex}
            className="ui-skeleton"
            style={{ height: '13px', width: columnIndex === 0 ? '82%' : '64%' }}
          />
        ))}
      </div>
    ))}
  </div>
);

/**
 * Marks a figure as illustrative rather than measured. The portal seeds
 * realistic sample numbers for demonstration; without a label a leader can
 * mistake them for live church data, which is the one thing an admin console
 * must never do.
 */
export const SampleDataBadge: React.FC<{ label: string }> = ({ label }) => (
  <span className="ui-data-notice" title={label}>
    {label}
  </span>
);

export default EmptyState;
