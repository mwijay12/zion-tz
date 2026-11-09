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
  /**
   * True when this session is a LOCAL demo only — it never touched Firebase
   * Auth and must never be treated as authenticated for Firestore writes.
   * The UI must show a DEMO banner whenever this is true.
   */
  isDemo?: boolean;
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

/**
 * Demo mode is opt-in and local-only:
 * - `npm run dev` (Vite DEV) → demo buttons visible for localhost showcase.
 * - Deployed builds → demo buttons hidden unless `VITE_DEMO_MODE=true`
 *   is set in the deployment environment (e.g. Vercel env vars).
 * Demo sessions NEVER call Firebase Auth and NEVER write to Firestore.
 */
export const DEMO_MODE_ENABLED: boolean =
  import.meta.env.DEV || import.meta.env.VITE_DEMO_MODE === 'true';

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
    try {
      await firebaseSignOut(auth);
    } catch {}
  }

  static getStoredDemoUser(): PortalUser | null {
    if (!DEMO_MODE_ENABLED) return null;
    try {
      const raw = sessionStorage.getItem('zion_demo_user');
      if (!raw) return null;
      const parsed = JSON.parse(raw) as PortalUser;
      // Only honour sessions explicitly marked as demo — never trust a
      // stored object that claims a real Firebase uid.
      if (!parsed.isDemo) return null;
      return parsed;
    } catch {
      return null;
    }
  }

  /**
   * LOCAL DEMO ONLY — creates a fake leader session in sessionStorage.
   * It does NOT sign in to Firebase, does NOT use any password, and
   * Firestore writes will be blocked (see FirebaseChurchService.requireAuth).
   * Use it for localhost showcase / UI walkthroughs, never for real data.
   */
  static async loginAsDemo(role: UserRole = 'super_admin'): Promise<PortalUser> {
    if (!DEMO_MODE_ENABLED) {
      throw new Error(
        'Demo mode imezimwa kwenye build hii. Weka VITE_DEMO_MODE=true au tumia akaunti halisi ya Firebase.'
      );
    }

    const demoUser: PortalUser = {
      id: `demo-${role}`,
      name: role === 'pastor' ? 'Mchungaji na Askofu Mercy James (DEMO)' : (role === 'secretary' ? 'Katibu Mkuu (DEMO)' : 'Super Admin Zion (DEMO)'),
      email: `${role}@demo.local`,
      role,
      isRoot: role === 'admin' || role === 'super_admin',
      branch: 'Mbagala Kwa Matope (HQ)',
      titleSw: ROLE_TITLES[role] || 'Kiongozi wa Kanisa',
      isDemo: true,
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
    // Privileged portal access requires a verified email. Unverified
    // accounts must not gain leader roles even if claims were mis-set.
    if (!firebaseUser.emailVerified) {
      return null;
    }

    const token = await firebaseUser.getIdTokenResult(true);
    const claims = token.claims as Record<string, unknown>;
    const role = claims.role as UserRole | undefined;

    // Role comes ONLY from Firebase custom claims (set by
    // functions/setUserRole via Admin SDK). No email allowlist fallback —
    // a hardcoded email list would let anyone who registers that email
    // become admin. The `admin: true` legacy claim is still honoured for
    // backwards compatibility with already-provisioned accounts.
    let effectiveRole = role;
    if (!effectiveRole && claims.admin === true) {
      effectiveRole = 'super_admin';
    }

    if (!effectiveRole || !isPortalRole(effectiveRole)) return null;

    return {
      id: firebaseUser.uid,
      name: firebaseUser.displayName || (effectiveRole === 'pastor' ? 'Mchungaji na Askofu Mercy James' : (effectiveRole === 'secretary' ? 'Katibu Mkuu' : 'Super Admin Zion')),
      email: firebaseUser.email || '',
      role: effectiveRole,
      isRoot: effectiveRole === 'admin' || effectiveRole === 'super_admin',
      branch: typeof claims.branch === 'string' ? claims.branch : 'Mbagala Kwa Matope (HQ)',
      titleSw: ROLE_TITLES[effectiveRole],
      isDemo: false,
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
