import React, { useState, useEffect } from 'react';
import { 
  Church, 
  Wallet, 
  Home, 
  ShieldCheck,
  Megaphone,
  Music,
  Users,
  UserCheck,
  BarChart3,
  Sparkles
} from 'lucide-react';
import type { Language, UserRole } from '../types';
import { AuthService, type PortalUser } from '../services/authService';

interface MobileNavProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  language: Language;
  userRole?: UserRole;
  currentUser?: PortalUser | null;
}

export const MobileNav: React.FC<MobileNavProps> = ({
  activeTab,
  setActiveTab,
  language,
  userRole = 'guest',
  currentUser
}) => {
  const isSw = language === 'sw';
  const [isScrollingDown, setIsScrollingDown] = useState(false);

  useEffect(() => {
    let lastScrollY = window.scrollY;
    const handleScroll = () => {
      const currentScrollY = window.scrollY;
      const delta = currentScrollY - lastScrollY;
      if (currentScrollY > 64 && delta > 8) {
        setIsScrollingDown(true);
      } else if (delta < -6 || currentScrollY <= 24) {
        setIsScrollingDown(false);
      }
      lastScrollY = currentScrollY;
    };
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Get active role portal info
  const getRolePortalTab = () => {
    switch (userRole) {
      case 'pastor':
        return { tab: 'pastor_portal', tooltip: isSw ? 'Pastoral Studio' : 'Pastoral Studio', icon: ShieldCheck };
      case 'secretary':
        return { tab: 'secretary_portal', tooltip: isSw ? 'Ofisi ya Katibu' : 'Secretary Office', icon: Megaphone };
      case 'deacon':
        return { tab: 'deacons_portal', tooltip: isSw ? 'Mashemasi & Wageni' : 'Deacons & Visitors', icon: UserCheck };
      case 'choir_leader':
        return { tab: 'choir_portal', tooltip: isSw ? 'Kwaya & Muziki' : 'Choir & Music', icon: Music };
      case 'children_teacher':
        return { tab: 'departments_portal', tooltip: isSw ? 'Idara za Kanisa' : 'Church Departments', icon: Users };
      case 'treasurer':
        return { tab: 'finance', tooltip: isSw ? 'Hazina & Sadaka' : 'Treasury & Giving', icon: Wallet };
      case 'jumuiya_leader':
        return { tab: 'jumuiya', tooltip: isSw ? 'Jumuiya' : 'Home Cells', icon: Home };
      default:
        return { tab: 'analytics', tooltip: isSw ? 'Afya ya Kanisa' : 'Church Health', icon: BarChart3 };
    }
  };

  const roleTab = getRolePortalTab();
  const RoleIcon = roleTab.icon;

  // Ordered priority list for leaders on mobile; deduplicated & capped at MAX 5 icons
  // (All 14 modules remain accessible in the left Sidebar Drawer)
  const candidateItems = [
    { id: 'dashboard', icon: Church, tooltip: isSw ? 'Dashibodi ya Utawala' : 'Admin Dashboard' },
    { id: roleTab.tab, icon: RoleIcon, tooltip: roleTab.tooltip },
    { id: 'secretary_portal', icon: Megaphone, tooltip: isSw ? 'Ofisi ya Katibu' : 'Secretary Office' },
    { id: 'finance', icon: Wallet, tooltip: isSw ? 'Hazina & Sadaka' : 'Treasury & Offerings' },
    { id: 'media_studio', icon: Sparkles, tooltip: isSw ? 'Studio ya App Sync' : 'App Sync Studio' },
    { id: 'jumuiya', icon: Home, tooltip: isSw ? 'Jumuiya za Nyumbani' : 'Home Cells' },
  ];

  const seenIds = new Set<string>();
  const visibleNavItems = candidateItems
    .filter((item) => {
      if (seenIds.has(item.id)) return false;
      if (!AuthService.canAccessTab(currentUser, item.id)) return false;
      seenIds.add(item.id);
      return true;
    })
    .slice(0, 5);

  return (
    <nav
      className={`mobile-dock-wrapper no-print ${isScrollingDown ? 'dock-scrolling-down' : ''}`}
      aria-label="Mobile Navigation Dock"
    >
      <div className="mobile-dock-container">
        {visibleNavItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => {
                setIsScrollingDown(false);
                setActiveTab(item.id);
              }}
              className={`mobile-dock-btn ${isActive ? 'active' : ''}`}
              title={item.tooltip}
              aria-label={item.tooltip}
            >
              <div className="mobile-dock-icon-wrap">
                <Icon size={21} strokeWidth={isActive ? 2.3 : 1.85} />
                {isActive && <span className="mobile-dock-active-glow" />}
              </div>
            </button>
          );
        })}
      </div>
    </nav>
  );
};

