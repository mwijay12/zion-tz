import React from 'react';
import { 
  Church, 
  Wallet, 
  Home, 
  Award, 
  BookOpen, 
  ShieldCheck,
  Megaphone,
  Music,
  Users,
  UserCheck
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
        return { tab: 'jumuiya', tooltip: isSw ? 'Jumuiya' : 'Home Cells', icon: Users };
      default:
        return { tab: 'dashboard', tooltip: isSw ? 'Dashibodi Kuu' : 'Dashboard', icon: Church };
    }
  };

  const roleTab = getRolePortalTab();
  const RoleIcon = roleTab.icon;

  const navItems = [
    { id: 'dashboard', icon: Church, tooltip: isSw ? 'Dashibodi Kuu' : 'Dashboard' },
    { id: 'finance', icon: Wallet, tooltip: isSw ? 'Fedha na Sadaka' : 'Finances & Offerings' },
    { id: 'jumuiya', icon: Home, tooltip: isSw ? 'Jumuiya za Nyumbani' : 'Home Cells' },
    { id: 'certificates', icon: Award, tooltip: isSw ? 'Vyeti Studio' : 'Certificates' },
    { id: 'bible', icon: BookOpen, tooltip: isSw ? 'Biblia Takatifu' : 'Holy Bible' },
    { id: roleTab.tab, icon: RoleIcon, tooltip: roleTab.tooltip },
  ];

  const visibleNavItems = navItems.filter((item) => AuthService.canAccessTab(currentUser, item.id));

  return (
    <nav className="mobile-dock-wrapper no-print" aria-label="Mobile Navigation Dock">
      <div className="mobile-dock-container">
        {visibleNavItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`mobile-dock-btn ${isActive ? 'active' : ''}`}
              title={item.tooltip}
              aria-label={item.tooltip}
            >
              <div className="mobile-dock-icon-wrap">
                <Icon size={21} strokeWidth={isActive ? 2.3 : 1.8} />
                {isActive && <span className="mobile-dock-active-glow" />}
              </div>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
