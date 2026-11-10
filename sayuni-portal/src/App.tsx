import { useState, useEffect } from 'react';
import { Header } from './components/Header';
import { MobileNav } from './components/MobileNav';
import { Dashboard } from './components/Dashboard';
import { ChurchHealth } from './components/ChurchHealth';
import { FinanceModule } from './components/FinanceModule';
import { JumuiyaModule } from './components/JumuiyaModule';
import { CertificateStudio } from './components/CertificateStudio';
import { BibleReader } from './components/BibleReader';
import { DailyDevotional } from './components/DailyDevotional';
import { MembersModule } from './components/MembersModule';
import { PastorsPortal } from './components/PastorsPortal';
import { SecretaryPortal } from './components/SecretaryPortal';
import { EldersPortal } from './components/EldersPortal';
import { ChoirPortal } from './components/ChoirPortal';
import { DepartmentsPortal } from './components/DepartmentsPortal';
import { DeaconsPortal } from './components/DeaconsPortal';
import { MediaContentStudio } from './components/MediaContentStudio';
import { LeadershipAnalyticsView } from './components/LeadershipAnalyticsView';

import type { UserRole, Language, FinancialRecord, FinancialProject, ChurchExpense, JumuiyaReport, JumuiyaGroup } from './types';
import { AuthService, type PortalUser } from './services/authService';
import { PrivacyAnalyticsService } from './services/privacyAnalyticsService';
import { FirebaseChurchService } from './services/firebaseChurchService';
import { churchSync } from './services/churchSyncService';
import { loadStored, saveStored, STORAGE_KEYS } from './utils/storage';
import { AuthModal } from './components/AuthModal';
import { 
  CHURCH_PROFILE, 
  INITIAL_FINANCES, 
  INITIAL_PROJECTS, 
  INITIAL_EXPENSES, 
  INITIAL_JUMUIYA_GROUPS, 
  INITIAL_JUMUIYA_REPORTS 
} from './data/mockData';

export function App() {
  const [currentUser, setCurrentUser] = useState<PortalUser | null>(null);
  const [authReady, setAuthReady] = useState<boolean>(false);
  const [showAuthModal, setShowAuthModal] = useState<boolean>(true);
  const [activeTab, setActiveTab] = useState<string>('dashboard');
  const [userRole, setUserRole] = useState<UserRole>('guest');
  const [language, setLanguage] = useState<Language>('sw');
  const [isDarkMode, setIsDarkMode] = useState<boolean>(false);
  const [analyticsSubTab, setAnalyticsSubTab] = useState<'telemetry' | 'operations'>('telemetry');
  const isSw = language === 'sw';

  useEffect(() => {
    const unsubscribe = AuthService.onAuthChange((user) => {
      setCurrentUser(user);
      setUserRole(user?.role || 'guest');
      if (user) setShowAuthModal(false);
      setAuthReady(true);
    });

    return unsubscribe;
  }, []);

  useEffect(() => {
    PrivacyAnalyticsService.recordEvent('app_launch');
  }, []);

  // Leadership names & photo live in Cloud Firestore, not in one browser's
  // localStorage. Every signed-in leader device now renders the same profile.
  useEffect(() => {
    return FirebaseChurchService.subscribeToLeadership((data) => {
      churchSync.applyCloudLeadership(data);
    });
  }, []);

  // Shared Application State
  const [finances, setFinances] = useState<FinancialRecord[]>(() => loadStored(STORAGE_KEYS.finances, INITIAL_FINANCES));
  const [projects, setProjects] = useState<FinancialProject[]>(() => loadStored(STORAGE_KEYS.projects, INITIAL_PROJECTS));
  const [expenses, setExpenses] = useState<ChurchExpense[]>(() => loadStored(STORAGE_KEYS.expenses, INITIAL_EXPENSES));
  const [groups] = useState<JumuiyaGroup[]>(INITIAL_JUMUIYA_GROUPS);
  const [reports, setReports] = useState<JumuiyaReport[]>(() => loadStored(STORAGE_KEYS.jumuiyaReports, INITIAL_JUMUIYA_REPORTS));

  // Dark Mode & Automatic Church Vault Backup
  useEffect(() => {
    if (isDarkMode) {
      document.documentElement.setAttribute('data-theme', 'dark');
    } else {
      document.documentElement.removeAttribute('data-theme');
    }

    // Trigger automatic daily vault snapshot
    import('./services/churchDataBackupService').then(({ ChurchDataBackupService }) => {
      ChurchDataBackupService.performAutoBackup();
    }).catch(() => {});
  }, [isDarkMode]);

  useEffect(() => {
    saveStored(STORAGE_KEYS.finances, finances);
  }, [finances]);

  useEffect(() => {
    saveStored(STORAGE_KEYS.projects, projects);
  }, [projects]);

  useEffect(() => {
    saveStored(STORAGE_KEYS.expenses, expenses);
  }, [expenses]);

  useEffect(() => {
    saveStored(STORAGE_KEYS.jumuiyaReports, reports);
  }, [reports]);

  const totalIncome = finances.reduce((acc, curr) => acc + curr.amount, 0);

  const handleLogout = () => {
    void AuthService.logout();
    setCurrentUser(null);
    setUserRole('guest');
    setShowAuthModal(true);
  };

  const handleLoginSuccess = (user: PortalUser) => {
    setCurrentUser(user);
    setUserRole(user.role);
    setShowAuthModal(false);
  };

  if (!authReady) {
    return (
      <div style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'var(--surface)',
        color: 'var(--text-muted)',
        fontFamily: 'var(--font-cinzel)',
        fontSize: '0.95rem'
      }}>
        Zion Jerusalem Portal...
      </div>
    );
  }

  if (!currentUser) {
    return <AuthModal language={language} onLoginSuccess={handleLoginSuccess} />;
  }

  const canViewActiveTab = AuthService.canAccessTab(currentUser, activeTab);

  return (
    <div className="portal-root">
      {currentUser.isDemo && (
        <div style={{
          backgroundColor: '#fef3c7',
          borderBottom: '2px solid #f59e0b',
          color: '#92400e',
          padding: '0.6rem 1rem',
          textAlign: 'center',
          fontSize: '0.82rem',
          fontWeight: 700,
          lineHeight: 1.5,
        }}>
          {isSw
            ? '⚠️ HII NI DEMO YA NDANI TU — data yote ni ya sampuli, haihifadhiwi kwenye wingu, na haiwezi kuandika kwenye Firestore. Ingia kwa akaunti halisi ya Firebase kwa data halisi.'
            : '⚠️ LOCAL DEMO ONLY — all data is sample, nothing is saved to the cloud, and Firestore writes are disabled. Sign in with a real Firebase account for real data.'}
        </div>
      )}
      {/* App Header Navigation (Sidebar + Topbar) */}
      <Header
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        language={language}
        setLanguage={setLanguage}
        isDarkMode={isDarkMode}
        setIsDarkMode={setIsDarkMode}
        currentUser={currentUser}
        onLogout={handleLogout}
        onOpenLogin={() => setShowAuthModal(true)}
      />

      {/* Main Workspace Canvas */}
      <div className="portal-content-wrap">
        <main className="portal-main-area">
        {canViewActiveTab ? (
          <>
        {activeTab === 'dashboard' && (
          <Dashboard
            language={language}
            userRole={userRole}
            setActiveTab={setActiveTab}
            projects={projects}
            recentReports={reports}
            totalIncome={totalIncome}
          />
        )}

        {activeTab === 'analytics' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
            <div style={{ display: 'flex', gap: '0.65rem', flexWrap: 'wrap' }}>
              <button
                onClick={() => setAnalyticsSubTab('telemetry')}
                style={{
                  padding: '0.55rem 1.15rem',
                  borderRadius: '20px',
                  border: analyticsSubTab === 'telemetry' ? '2px solid #0D52CD' : '1px solid var(--border-color)',
                  backgroundColor: analyticsSubTab === 'telemetry' ? 'rgba(13, 82, 205, 0.12)' : 'var(--surface)',
                  color: analyticsSubTab === 'telemetry' ? '#0D52CD' : 'var(--text-main)',
                  fontWeight: 700,
                  fontSize: '0.85rem',
                  cursor: 'pointer'
                }}
              >
                {isSw ? 'Takwimu za Kiroho & Faragha' : 'Spiritual Pulse & Privacy'}
              </button>
              <button
                onClick={() => setAnalyticsSubTab('operations')}
                style={{
                  padding: '0.55rem 1.15rem',
                  borderRadius: '20px',
                  border: analyticsSubTab === 'operations' ? '2px solid #0D52CD' : '1px solid var(--border-color)',
                  backgroundColor: analyticsSubTab === 'operations' ? 'rgba(13, 82, 205, 0.12)' : 'var(--surface)',
                  color: analyticsSubTab === 'operations' ? '#0D52CD' : 'var(--text-main)',
                  fontWeight: 700,
                  fontSize: '0.85rem',
                  cursor: 'pointer'
                }}
              >
                {isSw ? 'Afya ya Kiutawala, Fedha & Jumuiya' : 'Church Operations & Finance Health'}
              </button>
            </div>

            {analyticsSubTab === 'telemetry' ? (
              <LeadershipAnalyticsView language={language} reports={reports} />
            ) : (
              <ChurchHealth
                language={language}
                reports={reports}
                finances={finances}
                expenses={expenses}
                projects={projects}
                groups={groups}
              />
            )}
          </div>
        )}

        {activeTab === 'media_studio' && (
          <MediaContentStudio language={language} currentUser={currentUser} />
        )}

        {activeTab === 'pastor_portal' && (
          <PastorsPortal
            language={language}
            recentReports={reports}
          />
        )}

        {activeTab === 'secretary_portal' && (
          <SecretaryPortal
            language={language}
            reports={reports}
            groups={groups}
            setActiveTab={setActiveTab}
          />
        )}

        {activeTab === 'elders_portal' && (
          <EldersPortal
            language={language}
          />
        )}

        {activeTab === 'deacons_portal' && (
          <DeaconsPortal
            language={language}
          />
        )}

        {activeTab === 'choir_portal' && (
          <ChoirPortal
            language={language}
            currentUser={currentUser}
          />
        )}

        {activeTab === 'departments_portal' && (
          <DepartmentsPortal
            language={language}
          />
        )}

        {activeTab === 'finance' && (
          <FinanceModule
            language={language}
            userRole={userRole}
            finances={finances}
            setFinances={setFinances}
            projects={projects}
            setProjects={setProjects}
            expenses={expenses}
            setExpenses={setExpenses}
          />
        )}

        {activeTab === 'jumuiya' && (
          <JumuiyaModule
            language={language}
            userRole={userRole}
            groups={groups}
            reports={reports}
            setReports={setReports}
            setFinances={setFinances}
          />
        )}

        {activeTab === 'certificates' && (
          <CertificateStudio
            language={language}
            userRole={userRole}
          />
        )}

        {activeTab === 'bible' && (
          <BibleReader
            language={language}
            userRole={userRole}
          />
        )}

        {activeTab === 'devotional' && (
          <DailyDevotional
            language={language}
            userRole={userRole}
          />
        )}

        {activeTab === 'members' && (
          <MembersModule
            language={language}
            userRole={userRole}
            currentUser={currentUser}
          />
        )}
          </>
        ) : (
          <div className="church-card" style={{ padding: '2.5rem', textAlign: 'center', maxWidth: '620px', margin: '2rem auto' }}>
            <h2 style={{ fontFamily: 'var(--font-cinzel)', fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-headline)', marginBottom: '0.6rem' }}>
              {isSw ? 'Huna Ruhusa ya Kufikia Sehemu Hii' : 'Access Denied'}
            </h2>
            <p style={{ color: 'var(--text-muted)', lineHeight: 1.6, marginBottom: '1.25rem' }}>
              {isSw
                ? 'Wadhifa wako hauruhusu kufungua moduli hii. Wasiliana na msimamizi wa mfumo kama unahitaji ruhusa.'
                : 'Your role does not allow access to this module. Contact the system administrator if you need access.'}
            </p>
            <button onClick={() => setActiveTab('dashboard')} className="btn-primary">
              {isSw ? 'Rudi Dashibodi' : 'Back to Dashboard'}
            </button>
          </div>
        )}
        </main>

        {/* Ultra-Premium Minimalist Footer */}
        <footer className="no-print portal-sleek-footer">
          <div className="portal-footer-inner">
            <div className="portal-footer-brand">
              <div className="portal-footer-pill">
                <span className="footer-status-dot" />
                <span>Zion Jerusalem • Sayuni Hekalu Kuu</span>
              </div>
              <p className="portal-footer-motto">{CHURCH_PROFILE.motto}</p>
            </div>
            <div className="portal-footer-actions">
              <span className="portal-footer-meta">
                {CHURCH_PROFILE.location} • {CHURCH_PROFILE.phone} • © {new Date().getFullYear()}
              </span>
            </div>
          </div>
        </footer>
      </div>

      {/* Mobile Bottom Navigation */}
      <MobileNav
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        language={language}
        userRole={userRole}
        currentUser={currentUser}
      />

      {/* Liturgical Authentication Modal */}
      {showAuthModal && (
        <AuthModal
          language={language}
          onLoginSuccess={handleLoginSuccess}
          onClose={() => setShowAuthModal(false)}
        />
      )}
    </div>
  );
}

export default App;
