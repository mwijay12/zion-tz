import React, { useState } from 'react';
import { AlertCircle, Check, Copy, KeyRound, Lock, LogIn, Mail } from 'lucide-react';
import {
  AuthService,
  DEMO_CREDENTIALS,
  DEMO_MODE_ENABLED,
  type PortalUser,
} from '../services/authService';
import type { Language, UserRole } from '../types';

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
  const [demoRole, setDemoRole] = useState<UserRole>('super_admin');
  const [copiedDemo, setCopiedDemo] = useState(false);

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError('');

    if (email.trim().toLowerCase() === DEMO_CREDENTIALS.email && !DEMO_MODE_ENABLED) {
      setError(isSw
        ? 'Demo mode imezimwa kwenye build hii. Weka VITE_DEMO_MODE=true kwenye mazingira ya deployment.'
        : 'Demo mode is disabled in this build. Set VITE_DEMO_MODE=true in the deployment environment.');
      return;
    }

    setLoading(true);

    try {
      const user = await AuthService.login(email.trim(), password, demoRole);
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

        {/* ===== DEMO CREDENTIALS =====
            A local-only, explicitly labelled showcase login. The credential
            pair is checked in the browser and NEVER reaches Firebase Auth;
            the resulting session is isDemo=true and cannot write to Firestore. */}
        {DEMO_MODE_ENABLED ? (
        <div style={{ marginTop: '1.25rem', paddingTop: '1rem', borderTop: '1px solid var(--border-subtle)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.45rem', marginBottom: '0.6rem' }}>
            <KeyRound size={15} style={{ color: 'var(--primary-gold)' }} />
            <span style={{ fontSize: '0.8rem', fontWeight: 800, color: 'var(--text-headline)' }}>
              {isSw ? 'Demo credentials — maonyesho tu' : 'Demo credentials — showcase only'}
            </span>
          </div>

          <div style={{
            padding: '0.7rem 0.85rem', borderRadius: 12,
            backgroundColor: 'rgba(197, 155, 39, 0.09)',
            border: '1px solid rgba(197, 155, 39, 0.32)'
          }}>
            {[
              { label: isSw ? 'Barua pepe' : 'Email', value: DEMO_CREDENTIALS.email },
              { label: isSw ? 'Neno la siri' : 'Password', value: DEMO_CREDENTIALS.password },
            ].map(row => (
              <div key={row.label} style={{
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                gap: '0.5rem', flexWrap: 'wrap', padding: '0.22rem 0'
              }}>
                <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{row.label}</span>
                <code style={{
                  fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-headline)',
                  wordBreak: 'break-all'
                }}>{row.value}</code>
              </div>
            ))}

            <div style={{ display: 'flex', gap: '0.45rem', flexWrap: 'wrap', marginTop: '0.65rem' }}>
              <button
                type="button"
                onClick={() => {
                  setEmail(DEMO_CREDENTIALS.email);
                  setPassword(DEMO_CREDENTIALS.password);
                  setError('');
                }}
                style={{
                  padding: '0.4rem 0.75rem', borderRadius: 8, border: 'none',
                  backgroundColor: 'var(--primary-gold)', color: '#1a1a1a',
                  fontSize: '0.75rem', fontWeight: 800, cursor: 'pointer'
                }}
              >
                {isSw ? '📝 Jaza fomu' : '📝 Fill sign-in form'}
              </button>
              <button
                type="button"
                onClick={() => {
                  void navigator.clipboard.writeText(
                    `${DEMO_CREDENTIALS.email}\n${DEMO_CREDENTIALS.password}`
                  );
                  setCopiedDemo(true);
                  setTimeout(() => setCopiedDemo(false), 2200);
                }}
                style={{
                  display: 'flex', alignItems: 'center', gap: '0.35rem',
                  padding: '0.4rem 0.75rem', borderRadius: 8,
                  border: '1px solid var(--border-color)',
                  backgroundColor: 'var(--surface-variant)', color: 'var(--text-main)',
                  fontSize: '0.75rem', fontWeight: 700, cursor: 'pointer'
                }}
              >
                {copiedDemo ? <Check size={13} /> : <Copy size={13} />}
                {copiedDemo ? (isSw ? 'Imenakiliwa!' : 'Copied!') : (isSw ? 'Nakili' : 'Copy')}
              </button>
            </div>
          </div>

          <label style={{
            display: 'flex', alignItems: 'center', gap: '0.5rem', flexWrap: 'wrap',
            marginTop: '0.7rem', fontSize: '0.73rem', color: 'var(--text-muted)'
          }}>
            {isSw ? 'Wadhifa ukichapa credentials:' : 'Role when typing credentials:'}
            <select
              value={demoRole}
              onChange={event => setDemoRole(event.target.value as UserRole)}
              style={{
                padding: '0.35rem 0.5rem', borderRadius: 8,
                border: '1px solid var(--border-color)',
                background: 'var(--surface-variant)', color: 'var(--text-main)',
                fontSize: '0.75rem', fontWeight: 700
              }}
            >
              <option value="super_admin">👑 Super Admin</option>
              <option value="pastor">✝️ Mchungaji / Askofu</option>
              <option value="secretary">📜 Katibu Mkuu</option>
              <option value="deacon">🕊️ Mzee / Shemasi</option>
              <option value="usher">🙌 Mkaribishaji (Usher)</option>
              <option value="treasurer">💰 Mehani</option>
              <option value="choir_leader">🎵 Kiongozi wa Kwaya</option>
              <option value="jumuiya_leader">🏠 Kiongozi wa Jumuiya</option>
              <option value="children_teacher">🧒 Mwalimu wa Watoto</option>
            </select>
          </label>

          <div style={{ display: 'flex', gap: '0.45rem', justifyContent: 'center', flexWrap: 'wrap', marginTop: '0.7rem' }}>
            {([
              { role: 'super_admin', label: '👑 Super Admin', title: 'Super Admin na Mamlaka Kamili' },
              { role: 'pastor', label: '✝️ Askofu Mercy', title: 'Mchungaji na Askofu Mercy James' },
              { role: 'secretary', label: '📜 Katibu Mkuu', title: 'Katibu Mkuu wa Kanisa' },
            ] as const).map(item => (
              <button
                key={item.role}
                type="button"
                title={item.title}
                onClick={async () => {
                  const u = await AuthService.loginAsDemo(item.role);
                  onLoginSuccess(u);
                }}
                style={{
                  padding: '0.4rem 0.75rem', borderRadius: 8,
                  border: '1px solid var(--border-color)',
                  backgroundColor: 'var(--surface-variant)', color: 'var(--text-main)',
                  fontSize: '0.75rem', fontWeight: 700, cursor: 'pointer'
                }}
              >
                {item.label}
              </button>
            ))}
          </div>

          <p style={{ margin: '0.65rem 0 0 0', fontSize: '0.71rem', color: 'var(--text-muted)', lineHeight: 1.5, textAlign: 'center' }}>
            {isSw
              ? '⚠️ Hizi SI akaunti za Firebase. Data yote ni ya sampuli, haihifadhiwi kwenye wingu, na haiwezi kuandika Firestore. Usizitumie kwa data halisi ya wanachama.'
              : '⚠️ These are NOT Firebase accounts. All data is sample, nothing is saved to the cloud, and Firestore writes are blocked. Never use with real member data.'}
          </p>
        </div>
        ) : (
        <p style={{ margin: '0.85rem 0 0 0', fontSize: '0.74rem', color: 'var(--text-muted)', textAlign: 'center', lineHeight: 1.5 }}>
          {isSw
            ? 'Ikiwa huna akaunti, wasiliana na msimamizi wa mfumo ili kupewa wadhifa. (Demo huwezeshwa kwa VITE_DEMO_MODE=true.)'
            : 'No account? Contact the system administrator to be granted a role. (Demo is enabled with VITE_DEMO_MODE=true.)'}
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
