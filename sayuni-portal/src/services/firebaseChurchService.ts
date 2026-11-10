import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import {
  getFirestore,
  collection,
  doc,
  setDoc,
  updateDoc,
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
export const app = initializeApp(firebaseConfig);
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
  targetAudience: 'all' | 'leaders' | 'elders' | 'choir' | 'jumuiya' | 'member';
  targetUid?: string;
  targetJumuiya?: string;
  authorRole: string;
  authorEmail: string;
  author?: string;
  createdAt?: any;
  priority?: 'high' | 'normal';
  /** Optional poster-request metadata (leaders may ask for a design). */
  posterRequest?: boolean;
  posterStatus?: 'none' | 'requested' | 'ready';
  posterTheme?: string;
  posterAuthor?: string;
  posterGeneratedAt?: any;
  /** Optional structured event details for poster generation. */
  eventDate?: string;
  eventTime?: string;
  venue?: string;
  themeVerse?: string;
}

/**
 * A structured event / poster request written by church workers (ushers,
 * department leaders, secretary, pastors) from the leadership portal or the
 * member app. Super admins turn these into poster designs in the Poster Desk.
 * Single source of truth: Cloud Firestore `events` collection.
 */
export interface ChurchEvent {
  id?: string;
  title: string;
  description: string;
  category: string;
  /** ISO date yyyy-mm-dd — kept as a string so offline/demo writes work too. */
  eventDate?: string;
  eventTime?: string;
  venue?: string;
  themeVerse?: string;
  branch?: string;
  needsPoster?: boolean;
  posterStatus?: 'none' | 'requested' | 'ready';
  posterTheme?: string;
  posterFormat?: '9:16' | '1:1';
  posterCaption?: string;
  posterAuthor?: string;
  posterGeneratedAt?: any;
  requestedBy?: string;
  requestedByRole?: string;
  requestedByEmail?: string;
  createdAt?: any;
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
        ...(announcement.targetUid ? { targetUid: announcement.targetUid } : {}),
        ...(announcement.targetJumuiya ? { targetJumuiya: announcement.targetJumuiya } : {}),
        ...(announcement.posterRequest ? { posterRequest: true } : {}),
        posterStatus: announcement.posterRequest ? 'requested' : (announcement.posterStatus || 'none'),
        ...(announcement.eventDate ? { eventDate: announcement.eventDate } : {}),
        ...(announcement.eventTime ? { eventTime: announcement.eventTime } : {}),
        ...(announcement.venue ? { venue: announcement.venue } : {}),
        ...(announcement.themeVerse ? { themeVerse: announcement.themeVerse } : {}),
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

  // 2b. EVENTS / POSTER REQUESTS (leaders write, super admin designs)
  static async publishEvent(event: ChurchEvent): Promise<string> {
    const uid = this.requireAuth();
    const docRef = await addDoc(collection(db, "events"), {
      title: event.title.trim().slice(0, 300),
      description: event.description.trim().slice(0, 10000),
      category: event.category || 'Ibada',
      ...(event.eventDate ? { eventDate: event.eventDate.slice(0, 40) } : {}),
      ...(event.eventTime ? { eventTime: event.eventTime.slice(0, 80) } : {}),
      ...(event.venue ? { venue: event.venue.slice(0, 200) } : {}),
      ...(event.themeVerse ? { themeVerse: event.themeVerse.slice(0, 160) } : {}),
      branch: event.branch || 'Mbagala Kwa Matope (HQ)',
      needsPoster: event.needsPoster !== false,
      posterStatus: event.needsPoster === false ? 'none' : 'requested',
      requestedBy: event.requestedBy || auth.currentUser?.displayName || 'Kiongozi wa Kanisa',
      requestedByRole: event.requestedByRole || 'leader',
      requestedByEmail: event.requestedByEmail || auth.currentUser?.email || '',
      createdBy: uid,
      createdAt: serverTimestamp()
    });
    return docRef.id;
  }

  static subscribeToEvents(onUpdate: (items: ChurchEvent[]) => void): Unsubscribe {
    const q = query(collection(db, "events"), orderBy("createdAt", "desc"));
    return onSnapshot(q, (snapshot) => {
      onUpdate(snapshot.docs.map(d => ({ id: d.id, ...(d.data() as Omit<ChurchEvent, 'id'>) })));
    }, (error) => {
      console.error("Error listening to events:", error);
    });
  }

  /** Marks a generated poster as delivered. Secretariat/root roles only. */
  static async markEventPosterReady(eventId: string, patch: {
    posterTheme: string;
    posterFormat: '9:16' | '1:1';
    posterCaption: string;
    posterAuthor: string;
  }): Promise<void> {
    this.requireAuth();
    await updateDoc(doc(db, "events", eventId), {
      posterStatus: 'ready',
      posterTheme: patch.posterTheme,
      posterFormat: patch.posterFormat,
      posterCaption: patch.posterCaption,
      posterAuthor: patch.posterAuthor,
      posterGeneratedAt: serverTimestamp()
    });
  }

  /** Same sign-off for posters generated from an existing announcement. */
  static async markAnnouncementPosterReady(announcementId: string, patch: {
    posterTheme: string;
    posterCaption: string;
    posterAuthor: string;
  }): Promise<void> {
    this.requireAuth();
    await updateDoc(doc(db, "announcements", announcementId), {
      posterStatus: 'ready',
      posterTheme: patch.posterTheme,
      posterCaption: patch.posterCaption,
      posterAuthor: patch.posterAuthor,
      posterGeneratedAt: serverTimestamp()
    });
  }

  // 2c. LEADERSHIP PROFILE / PHOTO — shared with the member app via Firestore
  static async saveLeadershipSettings(data: {
    bishopName?: string;
    coLeaderName?: string;
    assistantPastor?: string;
    assistantPhone?: string;
    leadershipPhotoUrl?: string;
  }): Promise<void> {
    this.requireAuth();
    await setDoc(doc(db, "church_settings", "leadership"), {
      ...data,
      updatedAt: serverTimestamp()
    }, { merge: true });
  }

  static subscribeToLeadership(onUpdate: (data: Record<string, string>) => void): Unsubscribe {
    return onSnapshot(doc(db, "church_settings", "leadership"), (snapshot) => {
      const data = snapshot.data();
      if (!data) return;
      const clean: Record<string, string> = {};
      ['bishopName', 'coLeaderName', 'assistantPastor', 'assistantPhone', 'leadershipPhotoUrl']
        .forEach(key => {
          if (typeof data[key] === 'string' && data[key].trim()) clean[key] = data[key];
        });
      onUpdate(clean);
    }, (error) => {
      console.error("Error listening to leadership settings:", error);
    });
  }

  // 2d. VISITORS REGISTRY — connect-card applications from the member app
  static subscribeToVisitors(onUpdate: (items: any[]) => void): Unsubscribe {
    const q = query(collection(db, "visitors_registry"), orderBy("createdAt", "desc"));
    return onSnapshot(q, (snapshot) => {
      onUpdate(snapshot.docs.map(d => ({ id: d.id, ...d.data() })));
    }, (error) => {
      console.error("Error listening to visitors registry:", error);
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
