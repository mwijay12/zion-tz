import React from 'react';
import { 
  ShieldCheck, 
  UserCheck, 
  Music, 
  Wallet
} from 'lucide-react';
import { AuthService, type PortalUser } from '../services/authService';
import type { Language, UserRole } from '../types';

interface AuthModalProps {
  language: Language;
  onLoginSuccess: (user: PortalUser) => void;
  onClose?: () => void;
}

export const AuthModal: React.FC<AuthModalProps> = ({
  language,
  onLoginSuccess,
  onClose
}) => {
  const isSw = language === 'sw';

  const handleRoleQuickLogin = (role: UserRole) => {
    const user = AuthService.loginAsRole(role);
    onLoginSuccess(user);
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
        {/* Header Seal */}
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
              onError={(e) => {
                e.currentTarget.style.display = 'none';
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
            ? 'Hali ya majaribio: ingia kwa wadhifa ili kuona mfumo. Uthibitishaji halisi wa Firebase utawekwa kabla ya matumizi rasmi.'
            : 'Prototype access: choose a role to explore the portal. Real Firebase Authentication is required before production use.'}
        </div>

        <div style={{ marginBottom: '1.25rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.75rem' }}>
            <div style={{ flex: 1, height: '1px', background: 'var(--border-subtle)' }} />
            <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.8px', fontWeight: 700 }}>
              {isSw ? 'Chagua Wadhifa wa Kanisa' : 'Choose a Church Role'}
            </span>
            <div style={{ flex: 1, height: '1px', background: 'var(--border-subtle)' }} />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem' }}>
            <button
              onClick={() => handleRoleQuickLogin('pastor')}
              className="role-btn-pill"
              style={{ justifyContent: 'center', padding: '0.5rem' }}
            >
              <ShieldCheck size={14} />
              <span>{isSw ? 'Mchungaji' : 'Pastor'}</span>
            </button>
            <button
              onClick={() => handleRoleQuickLogin('secretary')}
              className="role-btn-pill"
              style={{ justifyContent: 'center', padding: '0.5rem' }}
            >
              <UserCheck size={14} />
              <span>{isSw ? 'Katibu' : 'Secretary'}</span>
            </button>
            <button
              onClick={() => handleRoleQuickLogin('treasurer')}
              className="role-btn-pill"
              style={{ justifyContent: 'center', padding: '0.5rem' }}
            >
              <Wallet size={14} />
              <span>{isSw ? 'Mweka Hazina' : 'Treasurer'}</span>
            </button>
            <button
              onClick={() => handleRoleQuickLogin('choir_leader')}
              className="role-btn-pill"
              style={{ justifyContent: 'center', padding: '0.5rem' }}
            >
              <Music size={14} />
              <span>{isSw ? 'Kiongozi Kwaya' : 'Choir Leader'}</span>
            </button>
          </div>
        </div>

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
