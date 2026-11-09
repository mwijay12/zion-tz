import React, { useState } from 'react';
import { AlertCircle, Lock, LogIn, Mail } from 'lucide-react';
import { AuthService, DEMO_MODE_ENABLED, type PortalUser } from '../services/authService';
import type { Language } from '../types';

interface AuthModalProps {
  language: Language;
  onLoginSuccess: (user: PortalUser) => void;
  onClose?: () => void;
}

const inputStyle: React.CSSProperties = {
  width: '100%',
  padding: '0.72rem 0.85rem 0.72rem 2.35rem',
  borderRadius: '10px',
  border: '1.5px solid var(--border-subtle)',
  background: 'var(--surface-container)',
  color: 'var(--on-surface)',
  fontSize: '0.88rem',
  outline: 'none',
  boxSizing: 'border-box',
};

export const AuthModal: React.FC<AuthModalProps> = ({
  language,
  onLoginSuccess,
  onClose
}) => {
  const isSw = language === 'sw';
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError('');
    setLoading(true);

    try {
      const user = await AuthService.login(email.trim(), password);
      onLoginSuccess(user);
    } catch (err) {
      const code = (err as { code?: string })?.code;
      const message = (err as Error)?.message;

      if (message?.includes('wadhifa')) {
        setError(message);
      } else if (
        code === 'auth/invalid-credential' ||
        code === 'auth/wrong-password' ||
        code === 'auth/user-not-found'
      ) {
        setError(isSw ? 'Barua pepe au neno la siri si sahihi.' : 'Incorrect email or password.');
      } else if (code === 'auth/too-many-requests') {
        setError(isSw ? 'Majaribio mengi. Subiri kidogo kisha ujaribu tena.' : 'Too many attempts. Wait a moment and try again.');
      } else if (code === 'auth/invalid-email') {
        setError(isSw ? 'Barua pepe si sahihi.' : 'Invalid email address.');
      } else {
        setError(isSw ? 'Imeshindikana kuingia. Jaribu tena.' : 'Sign-in failed. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      position: 'fixed',
      inset: 0,
      backgroundColor: 'rgba(10, 37, 64, 0.75)',
      backdropFilter: 'blur(8px)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 9999,
      padding: '1rem'
    }}>
      <div 
        className="church-card"
        style={{
          maxWidth: '460px',
          width: '100%',
          padding: '2rem',
          borderRadius: '24px',
          background: 'var(--surface)',
          border: '1.5px solid var(--border-gold)',
          boxShadow: '0 20px 50px rgba(0, 0, 0, 0.35)',
          position: 'relative'
        }}
      >
        <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
          <div style={{
            width: '64px',
            height: '64px',
            borderRadius: '50%',
            margin: '0 auto 12px auto',
            overflow: 'hidden',
            border: '2px solid var(--primary-gold)',
            boxShadow: '0 4px 14px rgba(197, 155, 39, 0.3)'
          }}>
            <img 
              src="/zion_logo.png" 
              alt="Zion Jerusalem Logo" 
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
              onError={(event) => {
                event.currentTarget.style.display = 'none';
              }}
            />
          </div>
          <h2 style={{ fontFamily: 'var(--font-cinzel)', fontSize: '1.4rem', fontWeight: 800, color: 'var(--text-headline)', margin: '0 0 4px 0' }}>
            Zion Jerusalem Portal
          </h2>
          <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', margin: 0 }}>
            {isSw ? 'Ufikiaji wa Mfumo wa Uongozi & Utawala wa Kanisa' : 'Church Leadership & Governance Portal Access'}
          </p>
        </div>

        <div style={{
          padding: '0.75rem 0.9rem',
          marginBottom: '1.25rem',
          borderRadius: '12px',
          backgroundColor: 'rgba(197, 155, 39, 0.09)',
          border: '1px solid rgba(197, 155, 39, 0.3)',
          fontSize: '0.78rem',
          color: 'var(--text-muted)',
          lineHeight: 1.5
        }}>
          {isSw
            ? 'Ingia kwa akaunti ya kiongozi iliyothibitishwa na kanisa. Wadhifa wako unatoka kwenye custom claims za Firebase.'
            : 'Sign in with a church-verified leader account. Your role comes from Firebase custom claims.'}
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '0.9rem' }}>
          <label style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
            <span style={{ fontSize: '0.76rem', fontWeight: 700, color: 'var(--text-headline)' }}>
              {isSw ? 'Barua Pepe' : 'Email'}
            </span>
            <span style={{ position: 'relative', display: 'block' }}>
              <Mail size={16} style={{ position: 'absolute', left: '0.8rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
              <input
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                required
                autoComplete="email"
                placeholder="kiongozi@zionjerusalem.org"
                style={inputStyle}
              />
            </span>
          </label>

          <label style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
            <span style={{ fontSize: '0.76rem', fontWeight: 700, color: 'var(--text-headline)' }}>
              {isSw ? 'Neno la Siri' : 'Password'}
            </span>
            <span style={{ position: 'relative', display: 'block' }}>
              <Lock size={16} style={{ position: 'absolute', left: '0.8rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
              <input
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                required
                autoComplete="current-password"
                placeholder="••••••••"
                style={inputStyle}
              />
            </span>
          </label>

          {error && (
            <div style={{
              display: 'flex',
              alignItems: 'flex-start',
              gap: '0.45rem',
              padding: '0.65rem 0.75rem',
              borderRadius: '10px',
              backgroundColor: 'rgba(220, 38, 38, 0.08)',
              border: '1px solid rgba(220, 38, 38, 0.25)',
              color: '#b91c1c',
              fontSize: '0.78rem',
              lineHeight: 1.4
            }}>
              <AlertCircle size={15} style={{ flexShrink: 0, marginTop: '1px' }} />
              <span>{error}</span>
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '0.5rem',
              width: '100%',
              padding: '0.75rem',
              borderRadius: '10px',
              border: 'none',
              background: 'var(--primary-gold)',
              color: '#1a1a1a',
              fontSize: '0.9rem',
              fontWeight: 800,
              cursor: loading ? 'wait' : 'pointer',
              opacity: loading ? 0.7 : 1
            }}
          >
            <LogIn size={16} />
            <span>{loading ? (isSw ? 'Inaingia...' : 'Signing in...') : (isSw ? 'Ingia Portal' : 'Sign In')}</span>
          </button>
        </form>

        {/* Local demo only — never touches Firebase Auth, never writes to Firestore */}
        {DEMO_MODE_ENABLED && (
        <div style={{ marginTop: '1.25rem', paddingTop: '1rem', borderTop: '1px solid var(--border-subtle)', textAlign: 'center' }}>
          <span style={{ fontSize: '0.74rem', color: 'var(--text-muted)', display: 'block', marginBottom: '0.6rem', fontWeight: 700 }}>
            {isSw ? '⚡ Onyesho la Ndani Tu (Local Demo — haina uhusiano na wingu):' : '⚡ Local Demo Only (no cloud sync):'}
          </span>
          <div style={{ display: 'flex', gap: '0.45rem', justifyContent: 'center', flexWrap: 'wrap' }}>
            <button
              type="button"
              onClick={async () => {
                const u = await AuthService.loginAsDemo('super_admin');
                onLoginSuccess(u);
              }}
              style={{
                padding: '0.4rem 0.75rem',
                borderRadius: '8px',
                border: '1px solid var(--border-color)',
                backgroundColor: 'var(--surface-variant)',
                color: 'var(--text-main)',
                fontSize: '0.75rem',
                fontWeight: 700,
                cursor: 'pointer'
              }}
              title="Super Admin na Mamlaka Kamili"
            >
              👑 Super Admin
            </button>
            <button
              type="button"
              onClick={async () => {
                const u = await AuthService.loginAsDemo('pastor');
                onLoginSuccess(u);
              }}
              style={{
                padding: '0.4rem 0.75rem',
                borderRadius: '8px',
                border: '1px solid var(--border-color)',
                backgroundColor: 'var(--surface-variant)',
                color: 'var(--text-main)',
                fontSize: '0.75rem',
                fontWeight: 700,
                cursor: 'pointer'
              }}
              title="Mchungaji na Askofu Mercy James"
            >
              ✝️ Askofu Mercy
            </button>
            <button
              type="button"
              onClick={async () => {
                const u = await AuthService.loginAsDemo('secretary');
                onLoginSuccess(u);
              }}
              style={{
                padding: '0.4rem 0.75rem',
                borderRadius: '8px',
                border: '1px solid var(--border-color)',
                backgroundColor: 'var(--surface-variant)',
                color: 'var(--text-main)',
                fontSize: '0.75rem',
                fontWeight: 700,
                cursor: 'pointer'
              }}
              title="Katibu Mkuu wa Kanisa"
            >
              📜 Katibu Mkuu
            </button>
          </div>
          <p style={{ margin: '0.6rem 0 0 0', fontSize: '0.72rem', color: 'var(--text-muted)', lineHeight: 1.5 }}>
            {isSw
              ? 'Demo hii ni ya kuonyesha UI tu. Haina password, haiingii Firebase, na haihifadhi data kwenye wingu.'
              : 'This demo is UI-only. It has no password, never signs in to Firebase, and never saves data to the cloud.'}
          </p>
        </div>
        )}

        {!DEMO_MODE_ENABLED && (
        <p style={{ margin: '0.85rem 0 0 0', fontSize: '0.74rem', color: 'var(--text-muted)', textAlign: 'center', lineHeight: 1.5 }}>
          {isSw
            ? 'Ikiwa huna akaunti, wasiliana na msimamizi wa mfumo ili kupewa wadhifa.'
            : 'No account? Contact the system administrator to be granted a role.'}
        </p>
        )}

        {onClose && (
          <button
            onClick={onClose}
            style={{
              position: 'absolute',
              top: '16px',
              right: '16px',
              background: 'transparent',
              border: 'none',
              cursor: 'pointer',
              color: 'var(--text-muted)'
            }}
          >
            ✕
          </button>
        )}
      </div>
    </div>
  );
};
