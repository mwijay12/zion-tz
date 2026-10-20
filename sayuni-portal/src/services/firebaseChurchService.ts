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
  // 1. ANNOUNCEMENTS / POP-UP NOTICES (Firestore production single source of truth)
  static async publishAnnouncement(announcement: ChurchAnnouncement): Promise<string> {
    try {
      const docRef = await addDoc(collection(db, "announcements"), {
        title: announcement.title.trim(),
        body: announcement.body || announcement.content || '',
        content: announcement.body || announcement.content || '',
        type: announcement.type || 'normal',
        category: announcement.category || 'Taarifa Kuu',
        branch: announcement.branch || 'Zote',
        targetAudience: announcement.targetAudience || 'all',
        authorRole: announcement.authorRole || 'Ofisi ya Katibu Mkuu',
        authorEmail: announcement.authorEmail || 'katibu@zionjerusalem.org',
        author: announcement.author || announcement.authorRole || 'Ofisi ya Katibu Mkuu',
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
      const docRef = await addDoc(collection(db, "sermons"), {
        ...sermon,
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
    const docRef = await addDoc(collection(db, "jumuiya_reports"), {
      ...report,
      submittedAt: serverTimestamp()
    });
    return docRef.id;
  }
}
