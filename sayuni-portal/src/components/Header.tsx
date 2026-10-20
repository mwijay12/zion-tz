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
  LogIn
} from 'lucide-react';
import type { UserRole, Language } from '../types';
import type { PortalUser } from '../services/authService';

interface HeaderProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  userRole: UserRole;
  setUserRole: (role: UserRole) => void;
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
    description: 'Askofu Messi Mgala ameweka mistari na mada ya somo la Jumapili: "Kutembea Katika Imani".',
    time: 'Jana',
    read: true,
    type: 'pastoral',
    targetTab: 'pastor_portal'
  }
];

export const Header: React.FC<HeaderProps> = ({
  activeTab,
  setActiveTab,
  userRole,
  setUserRole,
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
  
  const notifDropdownRef = useRef<HTMLDivElement>(null);
  const userMenuRef = useRef<HTMLDivElement>(null);
  const isSw = language === 'sw';

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

  const handleRoleChange = (role: UserRole) => {
    setUserRole(role);
    if (role === 'pastor') setActiveTab('pastor_portal');
    else if (role === 'secretary') setActiveTab('secretary_portal');
    else if (role === 'elder') setActiveTab('elders_portal');
    else if (role === 'deacon') setActiveTab('deacons_portal');
    else if (role === 'choir_leader') setActiveTab('choir_portal');
    else if (role === 'departments' || role === 'children_teacher') setActiveTab('departments_portal');
    else if (role === 'treasurer') setActiveTab('finance');
    else if (role === 'cell_leader') setActiveTab('jumuiya');
  };

  const markAllAsRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })));
  };

  const handleNotificationClick = (notif: ChurchNotification) => {
    setNotifications(prev => prev.map(n => n.id === notif.id ? { ...n, read: true } : n));
    if (notif.targetTab) {
      setActiveTab(notif.targetTab);
    }
    setNotificationsOpen(false);
  };

  const unreadCount = notifications.filter(n => !n.read).length;

  const navItems = [
    { id: 'dashboard', label: isSw ? 'Dashibodi Kuu' : 'Dashboard', icon: Church },
    { id: 'pastor_portal', label: isSw ? 'Pastoral Studio' : 'Pastoral Studio', icon: ShieldCheck },
    { id: 'secretary_portal', label: isSw ? 'Ofisi ya Katibu' : 'Secretary Office', icon: Megaphone },
    { id: 'deacons_portal', label: isSw ? 'Mashemasi & Wageni' : 'Deacons & Visitors', icon: UserCheck },
    { id: 'choir_portal', label: isSw ? 'Kwaya & Muziki' : 'Choirs & Music', icon: Music },
    { id: 'finance', label: isSw ? 'Fedha na Sadaka' : 'Finances & Tithes', icon: Wallet },
    { id: 'departments_portal', label: isSw ? 'Idara za Kanisa' : 'Departments', icon: Heart },
    { id: 'jumuiya', label: isSw ? 'Home Cells / Vikundi' : 'Home Cells', icon: Users },
    { id: 'bible', label: isSw ? 'Biblia & Daftari' : 'Bible & Notes', icon: BookOpen },
    { id: 'certificates', label: isSw ? 'Vyeti Studio' : 'Certificates', icon: Award },
  ];

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
        <div className="portal-sidebar-top">
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
              <span className="brand-title">Zion Fellowship</span>
              <span className="brand-subtitle">{isSw ? 'Dar es Salaam • Mbagala' : 'Dar es Salaam • Mbagala'}</span>
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
                <span className="label-sub">{isSw ? 'UONGOZI MKUU' : 'LEADERSHIP'}</span>
                <span className="name-sub">Bishop Mercy &amp; Pst James</span>
              </div>
              <CheckCircle2 size={18} style={{ color: 'var(--primary)' }} />
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="portal-nav-list" aria-label="Main Navigation">
            {navItems.map((item) => {
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
          </nav>
        </div>

        {/* Sidebar Footer */}
        <div className="portal-sidebar-footer" style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: '0.45rem', fontSize: '0.78rem', color: 'var(--on-surface-variant)' }}>
              <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#10b981', display: 'inline-block', boxShadow: '0 0 6px rgba(16, 185, 129, 0.6)' }} />
              <span>{isSw ? 'Mtandaoni (Live Sync)' : 'Connected'}</span>
            </span>
            <span style={{ fontWeight: 700, color: 'var(--primary)', fontSize: '0.74rem' }}>Kwa Matope HQ</span>
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

      {/* Stitch Fixed Top Bar */}
      <header className="portal-topbar">
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flex: 1, maxWidth: '520px' }}>
          {/* Mobile hamburger button: ONLY visible on screens < 1025px */}
          <button 
            className="icon-btn portal-hamburger-btn"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Toggle Navigation Menu"
            title={isSw ? 'Fungua Menyu ya Pembeni' : 'Open Navigation Menu'}
          >
            {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>

          {/* Search bar */}
          <div className="portal-search-wrap">
            <Search className="portal-search-icon" size={16} />
            <input 
              type="text" 
              className="portal-search-input"
              placeholder={isSw ? 'Tafuta waumini, mahubiri, vikao, matangazo...' : 'Search members, sermons, notices...'}
            />
          </div>
        </div>

        {/* Top bar Right Actions */}
        <div className="portal-topbar-actions">
          {/* Fast Role Switcher Segmented Pills */}
          <div className="role-switcher-segmented">
            <button
              onClick={() => handleRoleChange('pastor')}
              className={`role-btn-pill ${userRole === 'pastor' ? 'active' : ''}`}
              title={isSw ? 'Mtazamo wa Mchungaji' : 'Pastor View'}
            >
              {isSw ? 'Mchungaji' : 'Pastor'}
            </button>
            <button
              onClick={() => handleRoleChange('secretary')}
              className={`role-btn-pill ${userRole === 'secretary' ? 'active' : ''}`}
              title={isSw ? 'Mtazamo wa Katibu' : 'Secretary View'}
            >
              {isSw ? 'Katibu' : 'Secretary'}
            </button>
            <button
              onClick={() => handleRoleChange('deacon')}
              className={`role-btn-pill ${userRole === 'deacon' ? 'active' : ''}`}
              title={isSw ? 'Mtazamo wa Mashemasi' : 'Deacons View'}
            >
              {isSw ? 'Mashemasi' : 'Deacons'}
            </button>
            <button
              onClick={() => handleRoleChange('choir_leader')}
              className={`role-btn-pill ${userRole === 'choir_leader' ? 'active' : ''}`}
              title={isSw ? 'Mtazamo wa Kwaya' : 'Choir View'}
            >
              {isSw ? 'Kwaya' : 'Choir'}
            </button>
          </div>

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
                  <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.65rem', color: currentUser.isSuperAdmin ? '#b45309' : 'var(--on-surface-variant)', fontWeight: currentUser.isSuperAdmin ? 700 : 500 }}>
                    {currentUser.isSuperAdmin && <ShieldCheck size={11} style={{ color: '#d97706' }} />}
                    <span>{currentUser.isSuperAdmin ? 'Super Admin' : currentUser.titleSw}</span>
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
                      <span className={`badge ${currentUser.isSuperAdmin ? 'badge-gold' : 'badge-purple'}`} style={{ fontSize: '0.65rem' }}>
                        {currentUser.isSuperAdmin ? '👑 Super Administrator' : currentUser.titleSw}
                      </span>
                    </div>
                  </div>

                  <div style={{ height: '1px', background: 'var(--border-subtle)' }} />

                  {/* Fast Switch Role shortcuts */}
                  <div>
                    <div style={{ fontSize: '0.68rem', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '0.4rem', fontWeight: 700 }}>
                      {isSw ? 'Wadhifa Unaotumika' : 'Active Role View'}
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
                      <button
                        onClick={() => {
                          handleRoleChange('pastor');
                          setUserMenuOpen(false);
                        }}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.5rem',
                          padding: '0.4rem 0.6rem',
                          borderRadius: '8px',
                          border: 'none',
                          background: userRole === 'pastor' ? 'var(--surface-container)' : 'transparent',
                          color: 'var(--text-headline)',
                          fontSize: '0.78rem',
                          cursor: 'pointer',
                          fontWeight: userRole === 'pastor' ? 700 : 500
                        }}
                      >
                        <ShieldCheck size={14} style={{ color: 'var(--primary)' }} />
                        <span>Mchungaji (Pastor)</span>
                      </button>

                      <button
                        onClick={() => {
                          handleRoleChange('secretary');
                          setUserMenuOpen(false);
                        }}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.5rem',
                          padding: '0.4rem 0.6rem',
                          borderRadius: '8px',
                          border: 'none',
                          background: userRole === 'secretary' ? 'var(--surface-container)' : 'transparent',
                          color: 'var(--text-headline)',
                          fontSize: '0.78rem',
                          cursor: 'pointer',
                          fontWeight: userRole === 'secretary' ? 700 : 500
                        }}
                      >
                        <UserCheck size={14} style={{ color: 'var(--primary)' }} />
                        <span>Katibu (Secretary)</span>
                      </button>

                      <button
                        onClick={() => {
                          handleRoleChange('choir_leader');
                          setUserMenuOpen(false);
                        }}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.5rem',
                          padding: '0.4rem 0.6rem',
                          borderRadius: '8px',
                          border: 'none',
                          background: userRole === 'choir_leader' ? 'var(--surface-container)' : 'transparent',
                          color: 'var(--text-headline)',
                          fontSize: '0.78rem',
                          cursor: 'pointer',
                          fontWeight: userRole === 'choir_leader' ? 700 : 500
                        }}
                      >
                        <Music size={14} style={{ color: 'var(--primary)' }} />
                        <span>Kiongozi Kwaya (Choir)</span>
                      </button>
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
    </>
  );
};

export default Header;
