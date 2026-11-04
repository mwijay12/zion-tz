import React, { useState, useEffect, useRef } from 'react';
import { 
  Church, 
  Wallet, 
  Award, 
  BookOpen, 
  Heart, 
  Users, 
  Sun, 
  Moon, 
  Languages, 
  ShieldCheck,
  Megaphone,
  Music,
  Search,
  Menu,
  X,
  CheckCircle2,
  Bell,
  CheckCheck,
  Clock,
  UserCheck,
  LogOut,
  LogIn,
  BarChart3,
  Sparkles,
  Download,
  Smartphone
} from 'lucide-react';
import type { Language } from '../types';
import { AuthService, type PortalUser } from '../services/authService';

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

interface HeaderProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  language: Language;
  setLanguage: (lang: Language) => void;
  isDarkMode: boolean;
  setIsDarkMode: (dark: boolean) => void;
  currentUser: PortalUser | null;
  onLogout: () => void;
  onOpenLogin: () => void;
}

interface ChurchNotification {
  id: string;
  title: string;
  description: string;
  time: string;
  read: boolean;
  type: 'finance' | 'admin' | 'jumuiya' | 'choir' | 'pastoral';
  targetTab?: string;
}

const INITIAL_NOTIFICATIONS: ChurchNotification[] = [
  {
    id: 'notif-1',
    title: 'Sadaka ya Ujenzi Imepokelewa',
    description: 'Mchango mpya wa TSh 250,000 umepokelewa kupitia M-Pesa (Namba ya Kumbukumbu #MP-9821).',
    time: 'Dakika 15 zilizopita',
    read: false,
    type: 'finance',
    targetTab: 'finance'
  },
  {
    id: 'notif-2',
    title: 'Kikao cha Baraza la Wazee',
    description: 'Kikao rasmi cha Baraza la Wazee kitafanyika Alhamisi hii saa 10:00 Jioni ukumbini.',
    time: 'Saa 1 iliyopita',
    read: false,
    type: 'admin',
    targetTab: 'secretary_portal'
  },
  {
    id: 'notif-3',
    title: 'Ripoti ya Jumuiya ya Chamazi',
    description: 'Mzee wa Jumuiya ametuma ripoti ya mahudhurio na maombi ya wiki hii (Waumini 42).',
    time: 'Saa 3 zilizopita',
    read: false,
    type: 'jumuiya',
    targetTab: 'jumuiya'
  },
  {
    id: 'notif-4',
    title: 'Mazoezi ya Kwaya ya Galilaya',
    description: 'Mazoezi ya kujiandaa na Ibada Kuu ya Jumapili yatakuwa Ijumaa saa 11:00 Jioni.',
    time: 'Jana',
    read: true,
    type: 'choir',
    targetTab: 'choir_portal'
  },
  {
    id: 'notif-5',
    title: 'Nukuu ya Mahubiri ya Askofu',
    description: 'Askofu Mercy James ameweka mistari na mada ya somo la Jumapili: "Kutembea Katika Imani".',
    time: 'Jana',
    read: true,
    type: 'pastoral',
    targetTab: 'pastor_portal'
  }
];

export const Header: React.FC<HeaderProps> = ({
  activeTab,
  setActiveTab,
  language,
  setLanguage,
  isDarkMode,
  setIsDarkMode,
  currentUser,
  onLogout,
  onOpenLogin
}) => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const [notifications, setNotifications] = useState<ChurchNotification[]>(INITIAL_NOTIFICATIONS);
  const [isTopbarHidden, setIsTopbarHidden] = useState(false);
  const [deferredInstallPrompt, setDeferredInstallPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [showPwaGuide, setShowPwaGuide] = useState(false);
  
  const notifDropdownRef = useRef<HTMLDivElement>(null);
  const userMenuRef = useRef<HTMLDivElement>(null);
  const isSw = language === 'sw';

  // Scroll-aware topbar hiding on mobile devices to maximize viewport
  useEffect(() => {
    let lastScrollY = window.scrollY;
    const handleScroll = () => {
      const currentScrollY = window.scrollY;
      const delta = currentScrollY - lastScrollY;
      if (currentScrollY > 56 && delta > 7 && !mobileMenuOpen && !notificationsOpen && !userMenuOpen) {
        setIsTopbarHidden(true);
      } else if (delta < -6 || currentScrollY <= 24) {
        setIsTopbarHidden(false);
      }
      lastScrollY = currentScrollY;
    };
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, [mobileMenuOpen, notificationsOpen, userMenuOpen]);

  // Capture PWA beforeinstallprompt event
  useEffect(() => {
    const handleBeforeInstallPrompt = (e: Event) => {
      e.preventDefault();
      setDeferredInstallPrompt(e as BeforeInstallPromptEvent);
    };
    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    return () => window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
  }, []);

  const handleInstallPwaClick = async () => {
    if (deferredInstallPrompt) {
      await deferredInstallPrompt.prompt();
      await deferredInstallPrompt.userChoice;
      setDeferredInstallPrompt(null);
    } else {
      setShowPwaGuide(true);
    }
  };

  // Click outside to close dropdowns
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (notifDropdownRef.current && !notifDropdownRef.current.contains(event.target as Node)) {
        setNotificationsOpen(false);
      }
      if (userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
        setUserMenuOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  const markAllAsRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })));
  };

  const handleNotificationClick = (notif: ChurchNotification) => {
    setNotifications(prev => prev.map(n => n.id === notif.id ? { ...n, read: true } : n));
    if (notif.targetTab && AuthService.canAccessTab(currentUser, notif.targetTab)) {
      setActiveTab(notif.targetTab);
    }
    setNotificationsOpen(false);
  };

  const unreadCount = notifications.filter(n => !n.read).length;

  const adminOfficeItems = [
    { id: 'dashboard', label: isSw ? 'Dashibodi ya Utawala' : 'Admin Dashboard', icon: Church },
    { id: 'analytics', label: isSw ? 'Afya & Takwimu za Kanisa' : 'Church Health & Analytics', icon: BarChart3 },
    { id: 'pastor_portal', label: isSw ? 'Ofisi ya Askofu & Mchungaji' : 'Pastoral Studio', icon: ShieldCheck },
    { id: 'secretary_portal', label: isSw ? 'Ofisi ya Katibu Mkuu' : 'Secretary Office', icon: Megaphone },
    { id: 'members', label: isSw ? 'Daftari la Waumini' : 'Members Registry', icon: Users },
    { id: 'deacons_portal', label: isSw ? 'Mashemasi & Wageni' : 'Deacons & Visitors', icon: UserCheck },
    { id: 'elders_portal', label: isSw ? 'Baraza la Wazee' : 'Elders Board', icon: ShieldCheck },
    { id: 'finance', label: isSw ? 'Hazina & Sadaka' : 'Finances & Tithes', icon: Wallet },
    { id: 'certificates', label: isSw ? 'Vyeti & Nyaraka' : 'Certificates Studio', icon: Award },
  ];

  const memberAppSyncItems = [
    { id: 'media_studio', label: isSw ? 'Studio ya App Sync (Media)' : 'Mobile App Sync Studio', icon: Sparkles },
    { id: 'jumuiya', label: isSw ? 'Jumuiya za Nyumbani' : 'Home Cells', icon: Users },
    { id: 'choir_portal', label: isSw ? 'Kwaya & Sifa' : 'Choirs & Music', icon: Music },
    { id: 'departments_portal', label: isSw ? 'Idara & Shule ya Jumapili' : 'Departments', icon: Heart },
    { id: 'bible', label: isSw ? 'Biblia & Madokezo' : 'Bible & Notes', icon: BookOpen },
  ];

  const visibleAdminItems = adminOfficeItems.filter((item) => AuthService.canAccessTab(currentUser, item.id));
  const visibleSyncItems = memberAppSyncItems.filter((item) => AuthService.canAccessTab(currentUser, item.id));

  const getNotifIcon = (type: ChurchNotification['type']) => {
    switch(type) {
      case 'finance': return <Wallet size={16} style={{ color: '#059669' }} />;
      case 'admin': return <Megaphone size={16} style={{ color: '#0D52CD' }} />;
      case 'jumuiya': return <Users size={16} style={{ color: '#d97706' }} />;
      case 'choir': return <Music size={16} style={{ color: '#2563eb' }} />;
      case 'pastoral': return <ShieldCheck size={16} style={{ color: '#c59b27' }} />;
    }
  };

  return (
    <>
      {/* Mobile Backdrop Overlay when Drawer is Open */}
      {mobileMenuOpen && (
        <div 
          className="portal-sidebar-backdrop" 
          onClick={() => setMobileMenuOpen(false)}
          aria-hidden="true"
        />
      )}

      {/* Stitch Left Sidebar (Fixed on Desktop, Drawer on Mobile) */}
      <aside className={`portal-sidebar ${mobileMenuOpen ? 'open' : ''}`}>
        <div className="portal-sidebar-top" style={{ overflowY: 'auto', flex: 1 }}>
          {/* Brand Header */}
          <div className="portal-sidebar-brand">
            <img 
              src="/zion_logo.png" 
              alt="Zion Fellowship Logo" 
              onError={(e) => {
                e.currentTarget.style.display = 'none';
              }} 
            />
            <div className="brand-text">
              <span className="brand-title">Sayuni Admin</span>
              <span className="brand-subtitle">{isSw ? 'Mfumo wa Viongozi • PWA' : 'Leadership Portal • PWA'}</span>
            </div>
            {mobileMenuOpen && (
              <button 
                onClick={() => setMobileMenuOpen(false)}
                className="icon-btn sidebar-close-btn"
                style={{ marginLeft: 'auto', padding: '0.25rem' }}
                aria-label="Funga menyu"
              >
                <X size={20} />
              </button>
            )}
          </div>

          {/* Leadership Authority Card */}
          <div className="portal-leadership-card">
            <div className="portal-leadership-box">
              <div>
                <span className="label-sub">{isSw ? 'UTAWALA WA VIONGOZI PEKEE' : 'LEADERS ONLY PORTAL'}</span>
                <span className="name-sub">Bishop Mercy &amp; Pst James</span>
              </div>
              <CheckCircle2 size={18} style={{ color: 'var(--primary)' }} />
            </div>
          </div>

          {/* Grouped Navigation Links: Clear separation between Admin Offices & Member App Sync */}
          <nav className="portal-nav-list" aria-label="Main Navigation">
            {visibleAdminItems.length > 0 && (
              <>
                <div className="portal-nav-section-label">
                  <ShieldCheck size={12} />
                  <span>{isSw ? 'Ofisi za Viongozi (Admin)' : 'Leadership Offices'}</span>
                </div>
                {visibleAdminItems.map((item) => {
                  const Icon = item.icon;
                  const isActive = activeTab === item.id;
                  return (
                    <button
                      key={item.id}
                      onClick={() => {
                        setActiveTab(item.id);
                        setMobileMenuOpen(false);
                      }}
                      className={`portal-nav-item ${isActive ? 'active' : ''}`}
                    >
                      <Icon size={18} />
                      <span>{item.label}</span>
                    </button>
                  );
                })}
              </>
            )}

            {visibleSyncItems.length > 0 && (
              <>
                <div className="portal-nav-section-label" style={{ marginTop: '0.45rem' }}>
                  <Smartphone size={12} />
                  <span>{isSw ? 'Usawazishaji wa App ya Waumini' : 'Member Mobile App Sync'}</span>
                </div>
                {visibleSyncItems.map((item) => {
                  const Icon = item.icon;
                  const isActive = activeTab === item.id;
                  return (
                    <button
                      key={item.id}
                      onClick={() => {
                        setActiveTab(item.id);
                        setMobileMenuOpen(false);
                      }}
                      className={`portal-nav-item ${isActive ? 'active' : ''}`}
                    >
                      <Icon size={18} />
                      <span>{item.label}</span>
                    </button>
                  );
                })}
              </>
            )}
          </nav>
        </div>

        {/* Sidebar Footer */}
        <div className="portal-sidebar-footer" style={{ display: 'flex', flexDirection: 'column', gap: '0.55rem' }}>
          <button
            onClick={handleInstallPwaClick}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '0.45rem',
              width: '100%',
              padding: '0.48rem',
              borderRadius: '8px',
              border: '1px solid rgba(13, 82, 205, 0.28)',
              backgroundColor: 'rgba(13, 82, 205, 0.08)',
              color: 'var(--primary)',
              fontSize: '0.76rem',
              fontWeight: 700,
              cursor: 'pointer'
            }}
            title={isSw ? 'Sakinisha Mfumo wa Viongozi kwenye Simu (PWA)' : 'Install Admin Portal PWA'}
          >
            <Download size={13} />
            <span>{isSw ? 'Sakinisha App ya Viongozi (PWA)' : 'Install Admin PWA'}</span>
          </button>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: '0.45rem', fontSize: '0.75rem', color: 'var(--on-surface-variant)' }}>
              <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#10b981', display: 'inline-block', boxShadow: '0 0 6px rgba(16, 185, 129, 0.6)' }} />
              <span>{isSw ? 'Firebase Sync Active' : 'Firebase Sync Active'}</span>
            </span>
            <span style={{ fontWeight: 700, color: 'var(--primary)', fontSize: '0.72rem' }}>Kwa Matope HQ</span>
          </div>

          {currentUser && (
            <button
              onClick={onLogout}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '0.45rem',
                width: '100%',
                padding: '0.45rem',
                borderRadius: '8px',
                border: '1px solid rgba(220, 38, 38, 0.25)',
                backgroundColor: 'rgba(220, 38, 38, 0.06)',
                color: '#dc2626',
                fontSize: '0.76rem',
                fontWeight: 700,
                cursor: 'pointer',
                transition: 'all 0.2s ease'
              }}
              title={isSw ? 'Toka kwenye akaunti' : 'Sign out'}
            >
              <LogOut size={13} />
              <span>{isSw ? 'Toka (Log Out)' : 'Log Out'}</span>
            </button>
          )}
        </div>
      </aside>

      {/* Stitch Fixed Top Bar (Auto-hides on scroll down on mobile to expand viewport) */}
      <header className={`portal-topbar ${isTopbarHidden ? 'topbar-hidden-mobile' : ''}`}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem', flex: 1, maxWidth: '520px' }}>
          {/* Mobile hamburger button: ONLY visible on screens < 1025px */}
          <button 
            className="icon-btn portal-hamburger-btn"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Toggle Navigation Menu"
            title={isSw ? 'Fungua Menyu ya Viongozi' : 'Open Leadership Menu'}
          >
            {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>

          {/* Search bar */}
          <div className="portal-search-wrap">
            <Search className="portal-search-icon" size={16} />
            <input 
              type="text" 
              className="portal-search-input"
              placeholder={isSw ? 'Tafuta waumini, mahubiri, matangazo...' : 'Search members, sermons, notices...'}
            />
          </div>
        </div>

        {/* Top bar Right Actions */}
        <div className="portal-topbar-actions">
          {/* PWA Install Quick Action */}
          <button
            onClick={handleInstallPwaClick}
            className="icon-btn"
            title={isSw ? 'Sakinisha Sayuni Admin PWA kwenye Simu' : 'Install Sayuni Admin PWA'}
            aria-label="Install Admin PWA"
            style={{ color: 'var(--primary)' }}
          >
            <Download size={17} />
          </button>

          {/* Language Toggle */}
          <button
            onClick={() => setLanguage(language === 'sw' ? 'en' : 'sw')}
            className="icon-btn"
            title={isSw ? 'Badili Lugha kuwa Kiingereza' : 'Switch to Kiswahili'}
          >
            <Languages size={17} />
          </button>

          {/* Dark / Light Toggle */}
          <button
            onClick={() => setIsDarkMode(!isDarkMode)}
            className="icon-btn"
            title={isDarkMode ? 'Badili kwenda Mwanga' : 'Badili kwenda Giza'}
          >
            {isDarkMode ? <Sun size={17} style={{ color: '#f59e0b' }} /> : <Moon size={17} />}
          </button>

          {/* Interactive Notifications Bell & Dropdown */}
          <div style={{ position: 'relative' }} ref={notifDropdownRef}>
            <button 
              className={`icon-btn ${notificationsOpen ? 'active' : ''}`}
              onClick={() => setNotificationsOpen(!notificationsOpen)}
              title={isSw ? 'Taarifa Mpya za Kanisa' : 'Church Notifications'}
              aria-label="Notifications"
              aria-expanded={notificationsOpen}
              style={{ position: 'relative' }}
            >
              <Bell size={18} />
              {unreadCount > 0 && (
                <span 
                  className="portal-notif-badge"
                  style={{ 
                    position: 'absolute', 
                    top: '4px', 
                    right: '4px', 
                    minWidth: '17px',
                    height: '17px',
                    padding: '0 4px',
                    backgroundColor: '#dc2626',
                    color: '#ffffff',
                    fontSize: '0.62rem',
                    fontWeight: 800,
                    borderRadius: '9999px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    lineHeight: 1,
                    boxShadow: '0 0 0 2px var(--surface-container-lowest)'
                  }}
                >
                  {unreadCount}
                </span>
              )}
            </button>

            {/* Notification Popover Dropdown */}
            {notificationsOpen && (
              <div className="portal-notifications-dropdown" role="dialog" aria-label="Taarifa za Kanisa">
                {/* Header */}
                <div className="portal-notif-header">
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span style={{ fontWeight: 700, fontSize: '0.88rem', color: 'var(--on-surface)' }}>
                      {isSw ? 'Taarifa za Kanisa' : 'Notifications'}
                    </span>
                    {unreadCount > 0 && (
                      <span className="badge badge-purple" style={{ fontSize: '0.65rem', padding: '0.15rem 0.5rem' }}>
                        {unreadCount} {isSw ? 'Mpya' : 'New'}
                      </span>
                    )}
                  </div>
                  {unreadCount > 0 && (
                    <button
                      onClick={markAllAsRead}
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.3rem',
                        fontSize: '0.72rem',
                        color: 'var(--primary)',
                        fontWeight: 600,
                        cursor: 'pointer'
                      }}
                      title={isSw ? 'Soma Zote' : 'Mark all as read'}
                    >
                      <CheckCheck size={14} />
                      <span>{isSw ? 'Soma Zote' : 'Mark All Read'}</span>
                    </button>
                  )}
                </div>

                {/* Notifications List */}
                <div className="portal-notif-list">
                  {notifications.map((notif) => (
                    <button
                      key={notif.id}
                      onClick={() => handleNotificationClick(notif)}
                      className={`portal-notif-item ${!notif.read ? 'unread' : ''}`}
                    >
                      <div 
                        className="portal-notif-icon"
                        style={{
                          backgroundColor: !notif.read ? 'var(--surface-container)' : 'var(--surface-container-low)'
                        }}
                      >
                        {getNotifIcon(notif.type)}
                      </div>
                      <div className="portal-notif-content">
                        <div className="portal-notif-title">
                          <span>{notif.title}</span>
                          {!notif.read && (
                            <span 
                              style={{ 
                                width: '7px', 
                                height: '7px', 
                                borderRadius: '50%', 
                                backgroundColor: '#dc2626', 
                                display: 'inline-block',
                                flexShrink: 0
                              }} 
                              title="Haijasomwa"
                            />
                          )}
                        </div>
                        <p className="portal-notif-desc">{notif.description}</p>
                        <div className="portal-notif-meta">
                          <Clock size={12} />
                          <span>{notif.time}</span>
                        </div>
                      </div>
                    </button>
                  ))}
                </div>

                {/* Footer */}
                <div className="portal-notif-footer">
                  <span>Zion Jerusalem • Kwa Matope</span>
                  <button 
                    onClick={() => {
                      setActiveTab('secretary_portal');
                      setNotificationsOpen(false);
                    }}
                    style={{ color: 'var(--primary)', fontWeight: 600, cursor: 'pointer' }}
                  >
                    {isSw ? 'Matangazo Yote →' : 'All Notices →'}
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* User Session Profile & Logout */}
          {currentUser ? (
            <div style={{ position: 'relative' }} ref={userMenuRef}>
              <button
                onClick={() => setUserMenuOpen(!userMenuOpen)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.65rem',
                  paddingLeft: '0.5rem',
                  borderLeft: '1px solid var(--border-subtle)',
                  background: 'transparent',
                  border: 'none',
                  cursor: 'pointer',
                  textAlign: 'left'
                }}
                title={isSw ? 'Akaunti na Mipangilio' : 'User Account & Roles'}
              >
                <div style={{
                  width: '34px',
                  height: '34px',
                  borderRadius: '50%',
                  overflow: 'hidden',
                  backgroundColor: 'var(--primary)',
                  color: '#ffffff',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: 800,
                  fontSize: '0.82rem',
                  flexShrink: 0
                }}>
                  {currentUser.avatarUrl ? (
                    <img 
                      src={currentUser.avatarUrl} 
                      alt={currentUser.name} 
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    />
                  ) : (
                    currentUser.name.charAt(0)
                  )}
                </div>
                <div style={{ display: 'none' }} className="d-md-block">
                  <span style={{ display: 'block', fontSize: '0.78rem', fontWeight: 700, color: 'var(--on-surface)', lineHeight: 1.2 }}>
                    {currentUser.name}
                  </span>
                  <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.65rem', color: currentUser.isRoot ? '#b45309' : 'var(--on-surface-variant)', fontWeight: currentUser.isRoot ? 700 : 500 }}>
                    {currentUser.isRoot && <ShieldCheck size={11} style={{ color: '#d97706' }} />}
                    <span>{currentUser.role === 'super_admin' ? 'Super Admin' : currentUser.titleSw}</span>
                  </span>
                </div>
              </button>

              {/* User Dropdown Menu */}
              {userMenuOpen && (
                <div 
                  className="church-card"
                  style={{
                    position: 'absolute',
                    top: 'calc(100% + 10px)',
                    right: 0,
                    width: '260px',
                    padding: '1rem',
                    borderRadius: '16px',
                    background: 'var(--surface)',
                    boxShadow: '0 12px 36px rgba(0,0,0,0.18)',
                    border: '1.5px solid var(--border-subtle)',
                    zIndex: 1000,
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '0.75rem'
                  }}
                >
                  <div>
                    <div style={{ fontWeight: 800, fontSize: '0.9rem', color: 'var(--text-headline)' }}>
                      {currentUser.name}
                    </div>
                    <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)', wordBreak: 'break-all' }}>
                      {currentUser.email}
                    </div>
                    <div style={{ marginTop: '0.35rem' }}>
                      <span className={`badge ${currentUser.isRoot ? 'badge-gold' : 'badge-purple'}`} style={{ fontSize: '0.65rem' }}>
                        <ShieldCheck size={11} />
                        <span>{currentUser.role === 'super_admin' ? 'Super Administrator' : currentUser.titleSw}</span>
                      </span>
                    </div>
                  </div>

                  <div style={{ height: '1px', background: 'var(--border-subtle)' }} />

                  {/* Explicit Log Out Button */}
                  <button
                    onClick={() => {
                      setUserMenuOpen(false);
                      onLogout();
                    }}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '0.5rem',
                      padding: '0.55rem',
                      borderRadius: '8px',
                      border: '1px solid #fecaca',
                      backgroundColor: '#fef2f2',
                      color: '#dc2626',
                      fontWeight: 700,
                      fontSize: '0.82rem',
                      cursor: 'pointer'
                    }}
                  >
                    <LogOut size={15} />
                    <span>{isSw ? 'Toka (Log Out)' : 'Log Out'}</span>
                  </button>
                </div>
              )}
            </div>
          ) : (
            <button
              onClick={onOpenLogin}
              className="btn-primary"
              style={{ padding: '0.45rem 1rem', fontSize: '0.82rem' }}
            >
              <LogIn size={15} />
              <span>{isSw ? 'Ingia' : 'Sign In'}</span>
            </button>
          )}

          {currentUser && (
            <button
              onClick={onLogout}
              className="icon-btn"
              style={{ color: '#dc2626', borderColor: 'rgba(220, 38, 38, 0.25)' }}
              title={isSw ? 'Toka kwenye mfumo (Log Out)' : 'Log Out'}
              aria-label="Log Out"
            >
              <LogOut size={16} />
            </button>
          )}
        </div>
      </header>

      {/* PWA Installation Guide Modal for Mobile Leaders */}
      {showPwaGuide && (
        <div
          className="portal-modal-overlay"
          onClick={() => setShowPwaGuide(false)}
          role="dialog"
          aria-modal="true"
        >
          <div
            className="portal-modal-box"
            style={{ maxWidth: '430px' }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="portal-modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                <Smartphone size={20} style={{ color: 'var(--primary)' }} />
                <h3>{isSw ? 'Sakinisha Sayuni Admin (PWA)' : 'Install Sayuni Admin (PWA)'}</h3>
              </div>
              <button className="close-btn" onClick={() => setShowPwaGuide(false)} aria-label="Close">
                <X size={18} />
              </button>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem', fontSize: '0.85rem', color: 'var(--text-body)' }}>
              <p style={{ margin: 0 }}>
                {isSw
                  ? 'Huu ni Mfumo Maalum wa Viongozi wa Sayuni (tofauti na App ya Waumini). Unaweza kuusakinisha kwenye simu yako kama App kamili:'
                  : 'This is the dedicated Sayuni Leadership Portal (separate from the Member App). Install it on your phone home screen:'}
              </p>
              <div className="stitch-card-low" style={{ padding: '0.85rem', borderRadius: '12px' }}>
                <strong style={{ display: 'block', marginBottom: '0.25rem', color: 'var(--text-headline)' }}>
                  Android (Chrome / Edge):
                </strong>
                <span>
                  {isSw
                    ? 'Bonyeza vitufe vitatu (⋮) juu kulia kwenye browser kisha chagua "Install app" au "Add to Home screen".'
                    : 'Tap the browser menu (⋮) and select "Install app" or "Add to Home screen".'}
                </span>
              </div>
              <div className="stitch-card-low" style={{ padding: '0.85rem', borderRadius: '12px' }}>
                <strong style={{ display: 'block', marginBottom: '0.25rem', color: 'var(--text-headline)' }}>
                  iPhone / iPad (Safari):
                </strong>
                <span>
                  {isSw
                    ? 'Bonyeza kitufe cha Share chini kisha chagua "Add to Home Screen".'
                    : 'Tap the Share button at the bottom and choose "Add to Home Screen".'}
                </span>
              </div>
              <button
                className="btn-primary"
                onClick={() => setShowPwaGuide(false)}
                style={{ width: '100%', marginTop: '0.25rem' }}
              >
                {isSw ? 'Nimeelewa, Sawa' : 'Got It'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default Header;

