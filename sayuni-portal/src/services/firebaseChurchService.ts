import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import {
  getFirestore,
  collection,
  addDoc,
  query,
  orderBy,
  onSnapshot,
  serverTimestamp,
  type Unsubscribe
} from "firebase/firestore";

// Sayuni Jerusalem Church Firebase Configuration (Verified Live Project)
// NOTE: Firebase web API keys are client identifiers, not secrets — they are
// safe to ship in a web app. Security comes from Firestore rules + Auth,
// not from hiding these values. Restrict the key in Google Cloud Console
// (HTTP referrers + API restrictions) as defence in depth.
const firebaseConfig = {
  apiKey: "AIzaSyB4I1tmrPahB1OREVNyRYOtAwI8DMFBVJc",
  authDomain: "zion-mbagala-church.firebaseapp.com",
  projectId: "zion-mbagala-church",
  storageBucket: "zion-mbagala-church.firebasestorage.app",
  messagingSenderId: "295105770990",
  appId: "1:295105770990:web:41993a079016819590caff"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);

// Data Types for Realtime Sync
export interface ChurchAnnouncement {
  id?: string;
  title: string;
  body: string;
  content?: string;
  type: 'normal' | 'urgent' | 'bereavement';
  category: string;
  branch: string;
  targetAudience: 'all' | 'leaders' | 'elders' | 'choir';
  authorRole: string;
  authorEmail: string;
  author?: string;
  createdAt?: any;
  priority?: 'high' | 'normal';
}

export interface ChurchSermon {
  id?: string;
  title: string;
  preacher: string;
  scripture: string;
  duration?: string;
  type: 'video' | 'audio';
  category: string;
  mediaUrl: string;
  description?: string;
  createdAt?: any;
}

export interface JumuiyaWeeklyReport {
  id?: string;
  jumuiyaName: string;
  leaderName: string;
  leaderPhone: string;
  attendanceCount: number;
  offeringAmount: number;
  topicTaught: string;
  prayerNeeds: string;
  submittedAt?: any;
}

// Service Methods for Leaders & Portals
export class FirebaseChurchService {
  /**
   * Writes require a REAL signed-in Firebase user. Demo sessions
   * (sessionStorage `zion_demo_user`) are local-only and must never
   * write to Firestore — previously this auto-signed-in as a hardcoded
   * leader account, which is removed. Fail closed with a clear message.
   */
  private static requireAuth(): string {
    const user = auth.currentUser;
    if (!user) {
      throw new Error(
        'Huwezi kuandika kwenye wingu bila kuingia kwa akaunti halisi ya Firebase. ' +
        'Demo mode ni ya kuonyesha UI tu — data haihifadhiwi kwenye Firestore.'
      );
    }
    if (!user.emailVerified) {
      throw new Error('Thibitisha barua pepe yako kwanza kabla ya kuandika.');
    }
    return user.uid;
  }

  // 1. ANNOUNCEMENTS / POP-UP NOTICES (Firestore production single source of truth)
  static async publishAnnouncement(announcement: ChurchAnnouncement): Promise<string> {
    try {
      const uid = this.requireAuth();
      const docRef = await addDoc(collection(db, "announcements"), {
        title: announcement.title.trim(),
        body: announcement.body || announcement.content || '',
        content: announcement.body || announcement.content || '',
        type: announcement.type || 'normal',
        category: announcement.category || 'Taarifa Kuu',
        branch: announcement.branch || 'Zote',
        targetAudience: announcement.targetAudience || 'all',
        authorRole: announcement.authorRole || 'Ofisi ya Katibu Mkuu',
        authorEmail: announcement.authorEmail || auth.currentUser?.email || '',
        author: announcement.author || announcement.authorRole || 'Ofisi ya Katibu Mkuu',
        createdBy: uid,
        priority: announcement.type === 'urgent' ? 'high' : (announcement.priority || 'normal'),
        createdAt: serverTimestamp()
      });
      return docRef.id;
    } catch (error) {
      console.error("Error publishing announcement to Firebase:", error);
      throw error;
    }
  }

  static subscribeToAnnouncements(onUpdate: (items: ChurchAnnouncement[]) => void): Unsubscribe {
    const q = query(collection(db, "announcements"), orderBy("createdAt", "desc"));
    return onSnapshot(q, (snapshot) => {
      const items: ChurchAnnouncement[] = snapshot.docs.map(doc => ({
        id: doc.id,
        ...(doc.data() as Omit<ChurchAnnouncement, 'id'>)
      }));
      onUpdate(items);
    }, (error) => {
      console.error("Error listening to announcements:", error);
    });
  }

  // 2. SERMONS & MEDIA
  static async publishSermon(sermon: ChurchSermon): Promise<string> {
    try {
      const uid = this.requireAuth();
      const docRef = await addDoc(collection(db, "sermons"), {
        ...sermon,
        createdBy: uid,
        createdAt: serverTimestamp()
      });
      return docRef.id;
    } catch (error) {
      console.error("Error publishing sermon:", error);
      throw error;
    }
  }

  static subscribeToSermons(onUpdate: (items: ChurchSermon[]) => void): Unsubscribe {
    const q = query(collection(db, "sermons"), orderBy("createdAt", "desc"));
    return onSnapshot(q, (snapshot) => {
      const items: ChurchSermon[] = snapshot.docs.map(doc => ({
        id: doc.id,
        ...(doc.data() as Omit<ChurchSermon, 'id'>)
      }));
      onUpdate(items);
    }, (error) => {
      console.error("Error listening to sermons:", error);
    });
  }

  // 3. JUMUIYA REPORTS (Submitted from Mobile App or Web)
  static subscribeToJumuiyaReports(onUpdate: (reports: JumuiyaWeeklyReport[]) => void): Unsubscribe {
    const q = query(collection(db, "jumuiya_reports"), orderBy("submittedAt", "desc"));
    return onSnapshot(q, (snapshot) => {
      const reports: JumuiyaWeeklyReport[] = snapshot.docs.map(doc => ({
        id: doc.id,
        ...(doc.data() as Omit<JumuiyaWeeklyReport, 'id'>)
      }));
      onUpdate(reports);
    }, (error) => {
      console.error("Error listening to jumuiya reports:", error);
    });
  }

  static async submitJumuiyaReport(report: JumuiyaWeeklyReport): Promise<string> {
    try {
      const uid = this.requireAuth();
      const docRef = await addDoc(collection(db, "jumuiya_reports"), {
        ...report,
        submittedBy: uid,
        submittedAt: serverTimestamp()
      });
      return docRef.id;
    } catch (error) {
      console.error("Error submitting jumuiya report:", error);
      throw error;
    }
  }
}
