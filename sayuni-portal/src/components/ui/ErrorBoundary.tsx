import React from 'react';
import { AlertTriangle, RotateCcw } from 'lucide-react';
import type { Language } from '../../types';

interface Props {
  children: React.ReactNode;
  /** Shown in the fallback so leaders know which module failed. */
  moduleName?: string;
  language?: Language;
  /** Remount the boundary when this changes (e.g. the active tab). */
  resetKey?: string | number;
}

interface State {
  error: Error | null;
}

/**
 * Contains a render failure to one module.
 *
 * Before this, any exception inside a module (a malformed Firestore record,
 * a bad date, an unexpected null) unmounted the whole React tree and left a
 * blank page — with no way back except a hard refresh, and no clue about what
 * broke. The portal is the church's operations desk; a crash there must be
 * visible and recoverable, not silent.
 */
export class ErrorBoundary extends React.Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    // Keep the console diagnostic; there is no error-reporting backend yet.
    console.error(`[portal] module crashed${this.props.moduleName ? `: ${this.props.moduleName}` : ''}`, error, info.componentStack);
  }

  componentDidUpdate(previous: Props) {
    if (this.state.error && previous.resetKey !== this.props.resetKey) {
      this.setState({ error: null });
    }
  }

  private handleRetry = () => this.setState({ error: null });

  render() {
    const { error } = this.state;
    if (!error) return this.props.children;

    const isSw = (this.props.language ?? 'sw') === 'sw';

    return (
      <div className="church-card" style={{ padding: '2rem', maxWidth: '640px', margin: '1.5rem auto', textAlign: 'center' }}>
        <div style={{
          width: '48px',
          height: '48px',
          margin: '0 auto 0.85rem auto',
          borderRadius: '50%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'var(--error-container)',
          color: 'var(--on-error-container)',
        }}>
          <AlertTriangle size={22} />
        </div>

        <h2 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-headline)', marginBottom: '0.4rem' }}>
          {isSw ? 'Sehemu hii imeshindikana kupakia' : 'This section failed to load'}
        </h2>
        <p style={{ color: 'var(--text-muted)', fontSize: '0.86rem', lineHeight: 1.6, marginBottom: '1rem' }}>
          {isSw
            ? 'Hitilafu imetokea ndani ya moduli hii. Data yako haijabadilishwa. Unaweza kujaribu tena au kurudi kwenye dashibodi.'
            : 'An error occurred inside this module. Your data was not changed. You can retry, or go back to the dashboard.'}
        </p>

        {this.props.moduleName && (
          <code style={{
            display: 'inline-block',
            padding: '0.2rem 0.55rem',
            marginBottom: '1rem',
            borderRadius: '6px',
            background: 'var(--surface-container-low)',
            fontSize: '0.72rem',
            color: 'var(--text-subtle)',
          }}>
            {this.props.moduleName}
          </code>
        )}

        <details style={{ textAlign: 'left', marginBottom: '1rem' }}>
          <summary style={{ cursor: 'pointer', fontSize: '0.78rem', color: 'var(--text-muted)', fontWeight: 600 }}>
            {isSw ? 'Maelezo ya kiufundi' : 'Technical details'}
          </summary>
          <pre style={{
            marginTop: '0.5rem',
            padding: '0.7rem',
            borderRadius: '8px',
            background: 'var(--surface-container-low)',
            border: '1px solid var(--border-subtle)',
            fontSize: '0.72rem',
            overflowX: 'auto',
            whiteSpace: 'pre-wrap',
            wordBreak: 'break-word',
            color: 'var(--text-muted)',
          }}>
            {error.message}
          </pre>
        </details>

        <button type="button" className="btn-primary" onClick={this.handleRetry}>
          <RotateCcw size={15} />
          <span>{isSw ? 'Jaribu Tena' : 'Try again'}</span>
        </button>
      </div>
    );
  }
}

export default ErrorBoundary;
