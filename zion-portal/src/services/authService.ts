import type { UserRole } from '../types';

export interface PortalUser {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  isSuperAdmin: boolean;
  avatarUrl?: string;
  titleSw: string;
}

export const INITIAL_PORTAL_USERS: PortalUser[] = [
  {
    id: 'demo-pastor',
    name: 'Mchungaji Kiongozi',
    email: 'mchungaji@zionjerusalem.org',
    role: 'pastor',
    isSuperAdmin: false,
    titleSw: 'Mchungaji Kiongozi'
  },
  {
    id: 'demo-secretary',
    name: 'Katibu wa Kanisa',
    email: 'katibu@zionjerusalem.org',
    role: 'secretary',
    isSuperAdmin: false,
    titleSw: 'Katibu Mkuu wa Kanisa'
  },
  {
    id: 'demo-deacon',
    name: 'Kiongozi wa Mashemasi',
    email: 'mashemasi@zionjerusalem.org',
    role: 'deacon',
    isSuperAdmin: false,
    titleSw: 'Kiongozi wa Mashemasi na Wageni'
  },
  {
    id: 'demo-treasurer',
    name: 'Mweka Hazina',
    email: 'hazina@zionjerusalem.org',
    role: 'treasurer',
    isSuperAdmin: false,
    titleSw: 'Mweka Hazina wa Kanisa'
  },
  {
    id: 'demo-choir',
    name: 'Kiongozi wa Kwaya',
    email: 'kwaya@zionjerusalem.org',
    role: 'choir_leader',
    isSuperAdmin: false,
    titleSw: 'Kiongozi wa Kwaya'
  }
];

const STORAGE_KEY_USER = 'zion_portal_current_user_v2';
const STORAGE_KEY_ALL_USERS = 'zion_portal_all_users_v2';

export class AuthService {
  static getAllUsers(): PortalUser[] {
    try {
      const saved = localStorage.getItem(STORAGE_KEY_ALL_USERS);
      if (saved) return JSON.parse(saved);
    } catch (_) {}
    return INITIAL_PORTAL_USERS;
  }

  static saveAllUsers(users: PortalUser[]): void {
    try {
      localStorage.setItem(STORAGE_KEY_ALL_USERS, JSON.stringify(users));
    } catch (_) {}
  }

  static getCurrentUser(): PortalUser | null {
    try {
      const saved = localStorage.getItem(STORAGE_KEY_USER);
      if (saved === 'LOGGED_OUT') return null;
      if (saved) return JSON.parse(saved);
    } catch (_) {}
    return null;
  }

  static setCurrentUser(user: PortalUser | null): void {
    try {
      if (user) {
        localStorage.setItem(STORAGE_KEY_USER, JSON.stringify(user));
      } else {
        localStorage.setItem(STORAGE_KEY_USER, 'LOGGED_OUT');
      }
    } catch (_) {}
  }

  static loginAsRole(role: UserRole): PortalUser {
    const seed = INITIAL_PORTAL_USERS.find((u) => u.role === role);
    const user = seed || {
      id: `demo-${role}`,
      name: `Kiongozi (${role})`,
      email: `${role}@zionjerusalem.org`,
      role,
      isSuperAdmin: false,
      titleSw: `Kiongozi wa ${role}`
    };
    this.setCurrentUser(user);
    return user;
  }

  static logout(): void {
    this.setCurrentUser(null);
  }

  static grantRole(
    email: string,
    role: UserRole,
    isSuperAdmin = false,
    name?: string
  ): PortalUser {
    const all = this.getAllUsers();
    let user = all.find((u) => u.email.toLowerCase() === email.toLowerCase());

    if (user) {
      user.role = role;
      user.isSuperAdmin = isSuperAdmin;
      if (name) user.name = name;
    } else {
      user = {
        id: `user-${Date.now()}`,
        name: name || email.split('@')[0],
        email: email.toLowerCase(),
        role,
        isSuperAdmin,
        titleSw: isSuperAdmin ? 'Msimamizi Mkuu (Admin)' : `Kiongozi wa ${role}`
      };
      all.push(user);
    }

    this.saveAllUsers(all);
    return user;
  }

  // RBAC Permission Gates
  static canEditSongs(user: PortalUser | null): boolean {
    if (!user) return false;
    return user.isSuperAdmin || user.role === 'choir_leader' || user.role === 'pastor';
  }

  static canManageFinances(user: PortalUser | null): boolean {
    if (!user) return false;
    return user.isSuperAdmin || user.role === 'treasurer' || user.role === 'pastor';
  }

  static canIssueCertificates(user: PortalUser | null): boolean {
    if (!user) return false;
    return user.isSuperAdmin || user.role === 'secretary' || user.role === 'pastor';
  }

  static canGrantRoles(user: PortalUser | null): boolean {
    if (!user) return false;
    return user.isSuperAdmin;
  }
}
