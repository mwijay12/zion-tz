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
    await firebaseSignOut(auth);
  }

  static onAuthChange(callback: (user: PortalUser | null) => void) {
    return onAuthStateChanged(auth, async (firebaseUser) => {
      if (!firebaseUser) {
        callback(null);
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
    const role = claims.role;

    if (!isPortalRole(role)) return null;

    return {
      id: firebaseUser.uid,
      name: firebaseUser.displayName || firebaseUser.email?.split('@')[0] || 'Kiongozi',
      email: firebaseUser.email || '',
      role,
      isRoot: role === 'admin' || role === 'super_admin',
      branch: typeof claims.branch === 'string' ? claims.branch : undefined,
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
