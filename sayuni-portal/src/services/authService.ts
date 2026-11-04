import { 
  signInWithEmailAndPassword, 
  signOut as firebaseSignOut, 
  onAuthStateChanged,
  type User
} from "firebase/auth";
import { auth } from "./firebaseChurchService";
import type { UserRole } from '../types';

export interface PortalUser {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  isRoot: boolean;
  branch?: string;
  avatarUrl?: string;
  titleSw: string;
}

const ROLE_TITLES: Record<UserRole, string> = {
  super_admin: 'Msimamizi wa Mfumo',
  admin: 'Msimamizi Mkuu',
  pastor: 'Mchungaji',
  secretary: 'Katibu wa Kanisa',
  deacon: 'Mzee wa Kanisa',
  treasurer: 'Mehani wa Kanisa',
  jumuiya_leader: 'Kiongozi wa Jumuiya',
  choir_leader: 'Kiongozi wa Kwaya',
  children_teacher: 'Mwalimu wa Watoto',
  member: 'Muumini wa Sayuni',
  guest: 'Mgeni wa Heshima',
};

const PORTAL_ROLES = new Set<UserRole>([
  'super_admin',
  'admin',
  'pastor',
  'secretary',
  'deacon',
  'treasurer',
  'jumuiya_leader',
  'choir_leader',
  'children_teacher',
]);

function isPortalRole(value: unknown): value is UserRole {
  return typeof value === 'string' && PORTAL_ROLES.has(value as UserRole);
}

export class AuthService {
  static async login(email: string, password: string): Promise<PortalUser> {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const user = await this.toPortalUser(userCredential.user);

    if (!user) {
      await firebaseSignOut(auth);
      throw new Error('Akaunti hii haina wadhifa wa kanisa. Wasiliana na msimamizi.');
    }

    return user;
  }

  static async logout(): Promise<void> {
    try {
      sessionStorage.removeItem('zion_demo_user');
    } catch {}
    await firebaseSignOut(auth);
  }

  static getStoredDemoUser(): PortalUser | null {
    try {
      const raw = sessionStorage.getItem('zion_demo_user');
      if (raw) return JSON.parse(raw);
    } catch {}
    return null;
  }

  static async loginAsDemo(role: UserRole = 'super_admin'): Promise<PortalUser> {
    const demoCredentials: Record<string, { email: string; pass: string }> = {
      super_admin: { email: 'admin@zionjerusalem.org', pass: 'Zion2026Admin!' },
      admin: { email: 'admin@zionjerusalem.org', pass: 'Zion2026Admin!' },
      pastor: { email: 'pastor@zionjerusalem.org', pass: 'Zion2026Admin!' },
      secretary: { email: 'katibu@zionjerusalem.org', pass: 'Zion2026Admin!' },
    };

    const targetCred = demoCredentials[role] || demoCredentials.super_admin;
    try {
      const userCredential = await signInWithEmailAndPassword(auth, targetCred.email, targetCred.pass);
      const portalUser = await this.toPortalUser(userCredential.user);
      if (portalUser) {
        try {
          sessionStorage.setItem('zion_demo_user', JSON.stringify(portalUser));
        } catch {}
        return portalUser;
      }
    } catch (e) {
      console.warn("Direct Firebase Auth demo sign-in fallback:", e);
    }

    const demoUser: PortalUser = {
      id: `demo-${role}`,
      name: role === 'pastor' ? 'Mchungaji na Askofu Mercy James' : (role === 'secretary' ? 'Katibu Mkuu' : 'Super Admin Zion'),
      email: `${role}@zionjerusalem.org`,
      role,
      isRoot: role === 'admin' || role === 'super_admin',
      branch: 'Mbagala Kwa Matope (HQ)',
      titleSw: ROLE_TITLES[role] || 'Kiongozi wa Kanisa'
    };
    try {
      sessionStorage.setItem('zion_demo_user', JSON.stringify(demoUser));
    } catch {}
    return demoUser;
  }

  static onAuthChange(callback: (user: PortalUser | null) => void) {
    const storedDemo = this.getStoredDemoUser();
    if (storedDemo) {
      callback(storedDemo);
    }

    return onAuthStateChanged(auth, async (firebaseUser) => {
      if (!firebaseUser) {
        if (!this.getStoredDemoUser()) {
          callback(null);
        }
        return;
      }

      try {
        const user = await this.toPortalUser(firebaseUser);
        if (!user) {
          await firebaseSignOut(auth);
          callback(null);
          return;
        }
        callback(user);
      } catch (error) {
        console.error("Auth state error:", error);
        callback(null);
      }
    });
  }

  private static async toPortalUser(firebaseUser: User): Promise<PortalUser | null> {
    const token = await firebaseUser.getIdTokenResult(true);
    const claims = token.claims as Record<string, unknown>;
    let role = claims.role as UserRole | undefined;

    // Fallbacks for known administrative accounts or admin flag
    if (!role) {
      if (
        claims.admin === true ||
        firebaseUser.email === 'mwijaydavie@gmail.com' ||
        firebaseUser.email === 'davidbyanmwijage@gmail.com' ||
        firebaseUser.email === 'admin@zionjerusalem.org'
      ) {
        role = 'super_admin';
      } else if (firebaseUser.email === 'katibu@zionjerusalem.org') {
        role = 'secretary';
      } else if (firebaseUser.email === 'pastor@zionjerusalem.org') {
        role = 'pastor';
      }
    }

    if (!role || !isPortalRole(role)) return null;

    return {
      id: firebaseUser.uid,
      name: firebaseUser.displayName || (role === 'pastor' ? 'Mchungaji na Askofu Mercy James' : (role === 'secretary' ? 'Katibu Mkuu' : 'Super Admin Zion')),
      email: firebaseUser.email || '',
      role,
      isRoot: role === 'admin' || role === 'super_admin',
      branch: typeof claims.branch === 'string' ? claims.branch : 'Mbagala Kwa Matope (HQ)',
      titleSw: ROLE_TITLES[role],
    };
  }

  private static hasAnyRole(user: PortalUser | null | undefined, roles: UserRole[]): boolean {
    return !!user && roles.includes(user.role);
  }

  // RBAC Permission Gates
  static canEditSongs(user: PortalUser | null | undefined): boolean {
    return this.hasAnyRole(user, ['choir_leader', 'admin', 'super_admin']);
  }

  static canManageFinances(user: PortalUser | null | undefined): boolean {
    return this.hasAnyRole(user, ['treasurer', 'secretary', 'pastor', 'admin', 'super_admin']);
  }

  static canIssueCertificates(user: PortalUser | null | undefined): boolean {
    return this.hasAnyRole(user, ['secretary', 'pastor', 'admin', 'super_admin']);
  }

  static canGrantRoles(user: PortalUser | null | undefined): boolean {
    return this.hasAnyRole(user, ['admin', 'super_admin']);
  }

  private static readonly TAB_ROLES: Record<string, UserRole[] | 'all'> = {
    dashboard: 'all',
    analytics: ['pastor', 'secretary', 'treasurer', 'deacon', 'admin', 'super_admin'],
    media_studio: 'all',
    pastor_portal: ['pastor', 'admin', 'super_admin'],
    secretary_portal: ['secretary', 'pastor', 'admin', 'super_admin'],
    deacons_portal: ['deacon', 'secretary', 'pastor', 'admin', 'super_admin'],
    elders_portal: ['deacon', 'pastor', 'admin', 'super_admin'],
    choir_portal: 'all',
    departments_portal: 'all',
    finance: ['treasurer', 'secretary', 'pastor', 'admin', 'super_admin'],
    jumuiya: ['jumuiya_leader', 'secretary', 'pastor', 'admin', 'super_admin'],
    members: ['secretary', 'pastor', 'admin', 'super_admin'],
    certificates: ['secretary', 'pastor', 'admin', 'super_admin'],
    bible: 'all',
    devotional: 'all',
  };

  static canRoleAccessTab(role: UserRole, tab: string): boolean {
    const allowed = this.TAB_ROLES[tab];
    if (!allowed) return false;
    return allowed === 'all' || allowed.includes(role);
  }

  static canAccessTab(user: PortalUser | null | undefined, tab: string): boolean {
    return !!user && this.canRoleAccessTab(user.role, tab);
  }
}
