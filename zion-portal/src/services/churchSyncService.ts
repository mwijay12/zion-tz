import type { SermonItem, BulletinNotice, VisitorRecord } from '../types';
import { INITIAL_SERMONS, INITIAL_BULLETIN_NOTICES, CHURCH_PROFILE } from '../data/mockData';

export interface WarRoomPrayerRequest {
  id: string;
  title: string;
  author: string;
  urgency: 'Critical' | 'High' | 'Normal';
  description: string;
  date: string;
  intercessors: number;
  hasJoined?: boolean;
  pastorInterceded?: boolean;
  timestamp?: number;
}

export const INITIAL_WAR_ROOM_PRAYERS: WarRoomPrayerRequest[] = [
  {
    id: 'prayer-1',
    title: 'Uombezi wa Mkutano Mkuu wa Uamsho',
    author: 'Askofu Mercy Mgalla',
    urgency: 'Critical',
    description: 'Tunaomba ulinzi wa kiroho na kufunguliwa kwa maelfu ya roho kwenye mkutano ujao. Vita vya kiroho ni vikali lakini ushindi ni wa Bwana.',
    date: 'Leo Saa 06:00',
    intercessors: 89,
    pastorInterceded: true,
  },
  {
    id: 'prayer-2',
    title: 'Kuponywa kwa Ndugu Walioko Hospitalini',
    author: 'Mwangalizi wa Maombi',
    urgency: 'High',
    description: 'Tuwaombee washirika wetu watatu waliolazwa hospitali ya Muhimbili na Temeke. Mungu wa Sayuni awanyooshee mkono wa uponyaji sasa.',
    date: 'Jana Saa 18:30',
    intercessors: 64,
    pastorInterceded: false,
  },
  {
    id: 'prayer-3',
    title: 'Ujenzi wa Hekalu Jipya la Sayuni',
    author: 'Kamati ya Maendeleo',
    urgency: 'Normal',
    description: 'Mungu afungue milango ya fedha, vifaa na neema ya kukamilisha ujenzi bila vikwazo vyovyote vya kifedha.',
    date: 'Juzi',
    intercessors: 112,
    pastorInterceded: true,
  },
];

export interface SyncedLeadership {
  bishopName: string;
  coLeaderName: string;
  assistantPastor: string;
  assistantPhone: string;
  leadershipPhotoUrl?: string;
}

export type SyncEventType = 
  | 'SERMON_ADDED' 
  | 'SERMONS_UPDATED' 
  | 'NOTICE_ADDED' 
  | 'NOTICES_UPDATED' 
  | 'LEADERSHIP_UPDATED'
  | 'MEMBER_ADDED'
  | 'VISITOR_ADDED'
  | 'VISITORS_UPDATED'
  | 'PRAYER_ADDED'
  | 'PRAYERS_UPDATED';

export interface SyncMessage {
  type: SyncEventType;
  payload: any;
  source: 'web_portal' | 'mobile_app';
  timestamp: number;
}

type SyncListener = (message: SyncMessage) => void;

class ChurchSyncService {
  private static instance: ChurchSyncService;
  private channel: BroadcastChannel | null = null;
  private listeners: Set<SyncListener> = new Set();

  private constructor() {
    this.initChannel();
  }

  public static getInstance(): ChurchSyncService {
    if (!ChurchSyncService.instance) {
      ChurchSyncService.instance = new ChurchSyncService();
    }
    return ChurchSyncService.instance;
  }

  private initChannel() {
    if (typeof window !== 'undefined' && 'BroadcastChannel' in window) {
      try {
        this.channel = new BroadcastChannel('zion_church_sync');
        this.channel.onmessage = (event: MessageEvent<SyncMessage>) => {
          if (event.data && event.data.type) {
            this.handleIncomingMessage(event.data);
          }
        };
      } catch (err) {
        console.warn('BroadcastChannel initialization fallback:', err);
      }

      // Storage event listener fallback for cross-tab / cross-port
      window.addEventListener('storage', (e) => {
        if (e.key?.startsWith('zion_') || e.key?.startsWith('flutter.')) {
          this.handleIncomingMessage({
            type: 'SERMONS_UPDATED',
            payload: null,
            source: 'mobile_app',
            timestamp: Date.now()
          });
        }
      });
    }
  }

  private handleIncomingMessage(msg: SyncMessage) {
    // Notify all registered listeners in React components
    this.listeners.forEach((listener) => {
      try {
        listener(msg);
      } catch (e) {
        console.error('Error in sync listener:', e);
      }
    });
  }

  public subscribe(listener: SyncListener): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  public broadcast(type: SyncEventType, payload: any) {
    const message: SyncMessage = {
      type,
      payload,
      source: 'web_portal',
      timestamp: Date.now()
    };

    if (this.channel) {
      try {
        this.channel.postMessage(message);
      } catch (err) {
        console.warn('Error broadcasting sync message:', err);
      }
    }

    // Also notify local listeners
    this.handleIncomingMessage(message);
  }

  // ================= SERMONS SYNC =================

  public getSermons(): SermonItem[] {
    if (typeof window === 'undefined') return INITIAL_SERMONS;

    try {
      // 1. Check flutter-prefixed key first
      const rawFlutter = localStorage.getItem('flutter.zion_admin_uploaded_media');
      const rawStandard = localStorage.getItem('zion_admin_uploaded_media');
      const raw = rawFlutter || rawStandard;

      if (raw) {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed) && parsed.length > 0) {
          const mapped: SermonItem[] = parsed.map((item: any) => ({
            id: item.id || `sermon-${Date.now()}`,
            title: item.title || 'Mahubiri ya Sayuni',
            preacher: item.preacher || CHURCH_PROFILE.headPastor,
            date: item.date || 'Hivi karibuni',
            scripture: item.scripture || '',
            summary: item.description || item.summary || 'Mahubiri yaliyopakiwa na uongozi.',
            mediaType: item.type === 'audio' ? 'audio' : 'video',
            mediaUrl: item.videoUrl || item.audioUrl || item.mediaUrl || '',
            category: item.category || 'Mahubiri',
            likesCount: item.likesCount || 12
          }));

          // Merge with INITIAL_SERMONS without duplicates
          const seen = new Set(mapped.map(m => m.id));
          const combined = [...mapped, ...INITIAL_SERMONS.filter(s => !seen.has(s.id))];
          return combined;
        }
      }
    } catch (e) {
      console.warn('Error reading synced sermons:', e);
    }

    return INITIAL_SERMONS;
  }

  public addSermon(sermon: SermonItem): void {
    const current = this.getSermons();
    const updated = [sermon, ...current.filter(s => s.id !== sermon.id)];

    // Convert to mobile media format
    const mobileFormatList = updated.map(s => ({
      id: s.id,
      title: s.title,
      preacher: s.preacher,
      scripture: s.scripture,
      date: s.date,
      duration: '45 min',
      type: s.mediaType,
      category: s.category,
      description: s.summary,
      imageUrl: s.mediaType === 'video' ? 'assets/images/altar.jpg' : 'assets/images/church_front.jpg',
      audioUrl: s.mediaType === 'audio' ? s.mediaUrl : 'https://stream.zeno.fm/4v4e91y9sm8uv',
      videoUrl: s.mediaType === 'video' ? s.mediaUrl : '',
      isAdminUpload: true
    }));

    const jsonString = JSON.stringify(mobileFormatList);

    // Save under both keys so Flutter Web and standard web readers get it
    try {
      localStorage.setItem('zion_admin_uploaded_media', jsonString);
      localStorage.setItem('flutter.zion_admin_uploaded_media', jsonString);
    } catch (e) {
      console.warn('Error persisting sermon to localStorage:', e);
    }

    // Push to Firebase Firestore for Cloud Sync
    import('./firebaseChurchService').then(({ FirebaseChurchService }) => {
      FirebaseChurchService.publishSermon({
        title: sermon.title,
        preacher: sermon.preacher,
        scripture: sermon.scripture || '',
        type: sermon.mediaType === 'audio' ? 'audio' : 'video',
        category: sermon.category || 'Mahubiri',
        mediaUrl: sermon.mediaUrl || '',
        description: sermon.summary
      }).catch(err => console.warn('Could not post sermon to Firebase Firestore:', err));
    }).catch(() => {});

    // Broadcast
    this.broadcast('SERMON_ADDED', sermon);
  }

  // ================= NOTICES / BULLETIN SYNC =================

  public getNotices(): BulletinNotice[] {
    if (typeof window === 'undefined') return INITIAL_BULLETIN_NOTICES;

    try {
      const raw = localStorage.getItem('flutter.church_announcements') || localStorage.getItem('church_announcements');
      if (raw) {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed) && parsed.length > 0) {
          return parsed;
        }
      }
    } catch (e) {
      console.warn('Error reading synced notices:', e);
    }

    return INITIAL_BULLETIN_NOTICES;
  }

  public async addNotice(notice: BulletinNotice): Promise<string> {
    const current = this.getNotices();
    const updated = [notice, ...current.filter(n => n.id !== notice.id)];
    const jsonString = JSON.stringify(updated);

    try {
      localStorage.setItem('church_announcements', jsonString);
      localStorage.setItem('flutter.church_announcements', jsonString);
    } catch (e) {
      console.warn('Error saving notices:', e);
    }

    this.broadcast('NOTICE_ADDED', notice);

    // Primary Cloud Sync: Publish to Firestore
    try {
      const { FirebaseChurchService } = await import('./firebaseChurchService');
      const docId = await FirebaseChurchService.publishAnnouncement({
        title: notice.title,
        body: notice.content,
        content: notice.content,
        category: notice.category,
        type: notice.type || (notice.isUrgent ? 'urgent' : 'normal'),
        branch: notice.branch || 'Zote',
        targetAudience: notice.targetAudience || 'all',
        authorRole: notice.authorRole || 'Ofisi ya Katibu Mkuu',
        authorEmail: notice.authorEmail || 'katibu@zionjerusalem.org',
        priority: notice.isUrgent ? 'high' : 'normal'
      });
      return docId;
    } catch (error) {
      console.error('Error publishing to Firestore in addNotice:', error);
      throw error;
    }
  }

  // ================= LEADERSHIP SYNC =================

  public getLeadership(): SyncedLeadership {
    if (typeof window === 'undefined') {
      return {
        bishopName: CHURCH_PROFILE.headPastor,
        coLeaderName: CHURCH_PROFILE.bishopHusband,
        assistantPastor: 'Mch. Msaidizi Alex',
        assistantPhone: '+255 754 000 002',
        leadershipPhotoUrl: undefined
      };
    }

    return {
      bishopName: localStorage.getItem('flutter.custom_bishop') || localStorage.getItem('custom_bishop') || CHURCH_PROFILE.headPastor,
      coLeaderName: localStorage.getItem('flutter.custom_co_leader') || localStorage.getItem('custom_co_leader') || CHURCH_PROFILE.bishopHusband,
      assistantPastor: localStorage.getItem('flutter.custom_assistant') || localStorage.getItem('custom_assistant') || 'Mch. Msaidizi Alex',
      assistantPhone: localStorage.getItem('flutter.custom_assistant_phone') || localStorage.getItem('custom_assistant_phone') || '+255 754 000 002',
      leadershipPhotoUrl: localStorage.getItem('flutter.custom_leadership_photo') || localStorage.getItem('custom_leadership_photo') || undefined
    };
  }

  public updateLeadership(data: Partial<SyncedLeadership>): void {
    try {
      if (data.bishopName) {
        localStorage.setItem('flutter.custom_bishop', data.bishopName);
        localStorage.setItem('custom_bishop', data.bishopName);
      }
      if (data.coLeaderName) {
        localStorage.setItem('flutter.custom_co_leader', data.coLeaderName);
        localStorage.setItem('custom_co_leader', data.coLeaderName);
      }
      if (data.assistantPastor) {
        localStorage.setItem('flutter.custom_assistant', data.assistantPastor);
        localStorage.setItem('custom_assistant', data.assistantPastor);
      }
      if (data.assistantPhone) {
        localStorage.setItem('flutter.custom_assistant_phone', data.assistantPhone);
        localStorage.setItem('custom_assistant_phone', data.assistantPhone);
      }
      if (data.leadershipPhotoUrl) {
        localStorage.setItem('flutter.custom_leadership_photo', data.leadershipPhotoUrl);
        localStorage.setItem('custom_leadership_photo', data.leadershipPhotoUrl);
      }
    } catch (e) {
      console.warn('Error saving leadership:', e);
    }

    this.broadcast('LEADERSHIP_UPDATED', data);
  }

  // ================= WAR ROOM PRAYER REQUESTS SYNC =================

  public getPrayers(): WarRoomPrayerRequest[] {
    if (typeof window === 'undefined') return INITIAL_WAR_ROOM_PRAYERS;

    try {
      const raw = localStorage.getItem('flutter.zion_prayer_requests') || 
                  localStorage.getItem('zion_prayer_requests');
      if (raw) {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed) && parsed.length > 0) {
          const seen = new Set(parsed.map((p: any) => p.id));
          return [...parsed, ...INITIAL_WAR_ROOM_PRAYERS.filter(p => !seen.has(p.id))];
        }
      }
    } catch (e) {
      console.warn('Error reading synced prayers:', e);
    }

    return INITIAL_WAR_ROOM_PRAYERS;
  }

  public addPrayer(prayer: WarRoomPrayerRequest): void {
    const current = this.getPrayers();
    const updated = [prayer, ...current.filter(p => p.id !== prayer.id)];
    const jsonString = JSON.stringify(updated);

    try {
      localStorage.setItem('zion_prayer_requests', jsonString);
      localStorage.setItem('flutter.zion_prayer_requests', jsonString);
    } catch (e) {
      console.warn('Error saving prayers:', e);
    }

    // Push to Vite Sync API
    try {
      fetch('/api/sync/prayers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(prayer)
      }).catch(() => {});
    } catch (_) {}

    this.broadcast('PRAYER_ADDED', prayer);
  }

  public togglePastorIntercession(prayerId: string): void {
    const current = this.getPrayers();
    const updated = current.map(p => {
      if (p.id === prayerId) {
        const pastorInterceded = !p.pastorInterceded;
        return {
          ...p,
          pastorInterceded,
          intercessors: p.intercessors + (pastorInterceded ? 1 : -1)
        };
      }
      return p;
    });

    const jsonString = JSON.stringify(updated);
    try {
      localStorage.setItem('zion_prayer_requests', jsonString);
      localStorage.setItem('flutter.zion_prayer_requests', jsonString);
    } catch (e) {
      console.warn('Error saving prayers:', e);
    }

    this.broadcast('PRAYERS_UPDATED', updated);
  }

  // ================= VISITORS REGISTRY SYNC =================

  public getVisitors(): VisitorRecord[] {
    if (typeof window === 'undefined') return [];

    try {
      const raw = localStorage.getItem('flutter.zion_portal_visitors') || 
                  localStorage.getItem('zion_portal_visitors');
      if (raw) {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed) && parsed.length > 0) {
          return parsed;
        }
      }
    } catch (e) {
      console.warn('Error reading synced visitors:', e);
    }

    return [];
  }

  public addVisitor(visitor: VisitorRecord): void {
    const current = this.getVisitors();
    const updated = [visitor, ...current.filter(v => v.id !== visitor.id)];
    const jsonString = JSON.stringify(updated);

    try {
      localStorage.setItem('zion_portal_visitors', jsonString);
      localStorage.setItem('flutter.zion_portal_visitors', jsonString);
    } catch (e) {
      console.warn('Error saving visitor:', e);
    }

    // Push to Vite Sync API
    try {
      fetch('/api/sync/visitors', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(visitor)
      }).catch(() => {});
    } catch (_) {}

    this.broadcast('VISITOR_ADDED', visitor);
  }

  public updateVisitorStatus(id: string, status: VisitorRecord['followUpStatus']): void {
    const current = this.getVisitors();
    const updated = current.map(v => v.id === id ? { ...v, followUpStatus: status } : v);
    const jsonString = JSON.stringify(updated);

    try {
      localStorage.setItem('zion_portal_visitors', jsonString);
      localStorage.setItem('flutter.zion_portal_visitors', jsonString);
    } catch (e) {
      console.warn('Error updating visitor status:', e);
    }

    this.broadcast('VISITORS_UPDATED', updated);
  }
}

export const churchSync = ChurchSyncService.getInstance();
