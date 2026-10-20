import { 
  signInWithEmailAndPassword, 
  signOut as firebaseSignOut, 
  onAuthStateChanged
} from "firebase/auth";
import { auth } from "./firebaseChurchService";
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

const STORAGE_KEY_USER = 'zion_portal_current_user_v2';

export class AuthService {
  static async login(email: string, password: string): Promise<PortalUser> {
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const firebaseUser = userCredential.user;
      
      // Map Firebase user to PortalUser
      // In a real production app, role and isSuperAdmin would come from custom claims or a 'users' collection
      const user: PortalUser = {
        id: firebaseUser.uid,
        name: firebaseUser.displayName || email.split('@')[0],
        email: firebaseUser.email || email,
        role: this.inferRoleFromEmail(email),
        isSuperAdmin: email.includes('admin') || email.includes('pastor'),
        titleSw: 'Kiongozi wa Kanisa'
      };
      
      this.setCurrentUser(user);
      return user;
    } catch (error) {
      console.error("Login error:", error);
      throw error;
    }
  }

  private static inferRoleFromEmail(email: string): UserRole {
    if (email.includes('pastor')) return 'pastor';
    if (email.includes('katibu') || email.includes('secretary')) return 'secretary';
    if (email.includes('hazina') || email.includes('treasurer')) return 'treasurer';
    if (email.includes('choir') || email.includes('kwaya')) return 'choir_leader';
    return 'deacon';
  }

  static getCurrentUser(): PortalUser | null {
    try {
      const saved = localStorage.getItem(STORAGE_KEY_USER);
      if (saved && saved !== 'LOGGED_OUT') return JSON.parse(saved);
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

  static async logout(): Promise<void> {
    await firebaseSignOut(auth);
    this.setCurrentUser(null);
  }

  static onAuthChange(callback: (user: PortalUser | null) => void) {
    return onAuthStateChanged(auth, (firebaseUser) => {
      if (firebaseUser) {
        const currentUser = this.getCurrentUser();
        if (currentUser && currentUser.id === firebaseUser.uid) {
          callback(currentUser);
        } else {
          // Fallback or fetch from Firestore
          const newUser: PortalUser = {
            id: firebaseUser.uid,
            name: firebaseUser.displayName || firebaseUser.email?.split('@')[0] || 'User',
            email: firebaseUser.email || '',
            role: this.inferRoleFromEmail(firebaseUser.email || ''),
            isSuperAdmin: firebaseUser.email?.includes('admin') || false,
            titleSw: 'Kiongozi'
          };
          this.setCurrentUser(newUser);
          callback(newUser);
        }
      } else {
        this.setCurrentUser(null);
        callback(null);
      }
    });
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

  // Quick Login for Testing
  static loginAsRole(role: UserRole): PortalUser {
    const mockUser: PortalUser = {
      id: `test-${role}`,
      name: `Test ${role.charAt(0).toUpperCase() + role.slice(1)}`,
      email: `${role}@zion-test.com`,
      role: role,
      isSuperAdmin: role === 'pastor',
      titleSw: `Kiongozi (${role})`
    };
    this.setCurrentUser(mockUser);
    return mockUser;
  }
}
