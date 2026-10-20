import { useState, useEffect } from 'react';
import { Header } from './components/Header';
import { MobileNav } from './components/MobileNav';
import { Dashboard } from './components/Dashboard';
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

import type { UserRole, Language, FinancialRecord, FinancialProject, ChurchExpense, JumuiyaReport, JumuiyaGroup } from './types';
import { AuthService, type PortalUser } from './services/authService';
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
  const [currentUser, setCurrentUser] = useState<PortalUser | null>(() => AuthService.getCurrentUser());
  const [showAuthModal, setShowAuthModal] = useState<boolean>(() => !AuthService.getCurrentUser());
  const [activeTab, setActiveTab] = useState<string>('dashboard');
  const [userRole, setUserRole] = useState<UserRole>(() => AuthService.getCurrentUser()?.role || 'member');
  const [language, setLanguage] = useState<Language>('sw');
  const [isDarkMode, setIsDarkMode] = useState<boolean>(false);

  // Shared Application State
  const [finances, setFinances] = useState<FinancialRecord[]>(INITIAL_FINANCES);
  const [projects, setProjects] = useState<FinancialProject[]>(INITIAL_PROJECTS);
  const [expenses, setExpenses] = useState<ChurchExpense[]>(INITIAL_EXPENSES);
  const [groups] = useState<JumuiyaGroup[]>(INITIAL_JUMUIYA_GROUPS);
  const [reports, setReports] = useState<JumuiyaReport[]>(INITIAL_JUMUIYA_REPORTS);

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

  const totalIncome = finances.reduce((acc, curr) => acc + curr.amount, 0);

  const handleRoleChange = (newRole: UserRole) => {
    setUserRole(newRole);
    if (currentUser) {
      const updated: PortalUser = { ...currentUser, role: newRole };
      setCurrentUser(updated);
      AuthService.setCurrentUser(updated);
    }
  };

  const handleLogout = () => {
    AuthService.logout();
    setCurrentUser(null);
    setUserRole('member');
    setShowAuthModal(true);
  };

  const handleLoginSuccess = (user: PortalUser) => {
    setCurrentUser(user);
    setUserRole(user.role);
    setShowAuthModal(false);
  };

  if (!currentUser) {
    return <AuthModal language={language} onLoginSuccess={handleLoginSuccess} />;
  }

  return (
    <div className="portal-root">
      {/* App Header Navigation (Sidebar + Topbar) */}
      <Header
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        userRole={userRole}
        setUserRole={handleRoleChange}
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
          />
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
