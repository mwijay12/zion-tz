/**
 * Notification centre feed for the leadership portal.
 *
 * WHY THIS EXISTS
 * ---------------
 * The bell in `Header.tsx` used to be hardcoded seed data: five invented
 * notifications ("Mchango mpya wa TSh 250,000 umepokelewa...") that every
 * leader saw on every device, forever, with an unread badge that said
 * "5 new" on a fresh browser. Nothing in the portal ever produced a
 * notification and nothing ever consumed one. It looked alive and was not.
 *
 * This module replaces the seed with a feed derived from the collections the
 * portal already owns and already writes to Firestore:
 *
 *   announcements  → published notices (urgent ones rank first)
 *   events         → submitted events, and poster requests waiting on admin
 *   sermons        → newly published teachings
 *
 * DESIGN RULES
 * ------------
 *  - Read-only, derived. No new Firestore collection, no schema migration,
 *    no rules change: everything here is a projection of data that already
 *    exists, so the bell cannot drift out of sync with the real records.
 *  - Every notification points at the record that produced it (`targetTab`)
 *    so clicking it takes the leader to the thing that needs attention.
 *  - `createdAt` is the Firestore server timestamp, so the audience of the
 *    notification matches the audience of the underlying document. A leader
 *    on another device sees the same feed.
 *  - Empty is a valid answer. When nothing has happened, the bell shows
 *    nothing rather than inventing activity.
 */

import type { UserRole } from '../types';
import { AuthService } from './authService';
import type { ChurchAnnouncement, ChurchEvent, ChurchSermon } from './firebaseChurchService';

export type NotificationType = 'finance' | 'admin' | 'jumuiya' | 'choir' | 'pastoral';

export interface PortalNotification {
  /** Stable across re-renders so read-state can be persisted. */
  id: string;
  title: string;
  description: string;
  /** Human "x minutes ago", computed at build time. */
  time: string;
  /** Machine timestamp for the "mark read" cut-off. */
  timestampMs: number;
  read: boolean;
  type: NotificationType;
  /** Sidebar tab to open when clicked. */
  targetTab?: string;
  /**
   * Public information: shown to every role even when the role cannot open
   * `targetTab`. A deacon should still learn that a funeral notice went out.
   * Tapping it marks it read without navigating.
   */
  alwaysVisible?: boolean;
  /** Localised source label, e.g. "Matangazo" / "Announcements". */
  sourceSw: string;
  sourceEn: string;
}

export interface NotificationInputs {
  announcements: ChurchAnnouncement[];
  events: ChurchEvent[];
  sermons: ChurchSermon[];
  /** Most recent time the leader pressed "mark all read", in epoch ms. */
  readAllBefore: number;
  /** Ids the leader dismissed individually. */
  readIds: Set<string>;
  isSw: boolean;
}

function toMillis(value: unknown): number {
  if (!value) return 0;
  if (typeof value === 'number') return value;
  // Firestore Timestamp
  const maybeTimestamp = value as { toMillis?: () => number; seconds?: number };
  if (typeof maybeTimestamp.toMillis === 'function') {
    try {
      return maybeTimestamp.toMillis();
    } catch {
      return 0;
    }
  }
  if (typeof maybeTimestamp.seconds === 'number') return maybeTimestamp.seconds * 1000;
  if (value instanceof Date) return value.getTime();
  if (typeof value === 'string') {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? 0 : parsed;
  }
  return 0;
}

/**
 * "Dakika 12 zilizopita" / "12 minutes ago", or a date once it is old.
 *
 * `0` means "no timestamp yet": the document was written with
 * `serverTimestamp()` and the listener's local echo carries `null` until the
 * server acknowledges it. Saying "Recently" there is a lie with a visible
 * symptom — the same record showed "Sasa hivi" for a moment and then jumped to
 * "Dakika 3 zilizopita". Say what is actually true instead.
 */
export function relativeTime(ms: number, isSw: boolean, now = Date.now()): string {
  if (!ms) return isSw ? 'Inathibitishwa' : 'Pending';
  const diff = Math.max(0, now - ms);
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return isSw ? 'Sasa hivi' : 'Just now';
  if (minutes < 60) {
    return isSw ? `Dakika ${minutes} zilizopita` : `${minutes} min ago`;
  }
  const hours = Math.floor(minutes / 60);
  if (hours < 24) {
    return isSw
      ? `Saa ${hours} ${hours === 1 ? 'iliyopita' : 'zilizopita'}`
      : `${hours} ${hours === 1 ? 'hour' : 'hours'} ago`;
  }
  const days = Math.floor(hours / 24);
  if (days < 7) {
    return isSw ? `Siku ${days} zilizopita` : `${days} ${days === 1 ? 'day' : 'days'} ago`;
  }
  const date = new Date(ms);
  return date.toLocaleDateString(isSw ? 'sw-TZ' : 'en-US', {
    day: 'numeric',
    month: 'short',
  });
}

const truncate = (value: string, max = 160): string => {
  const clean = value.replace(/\s+/g, ' ').trim();
  return clean.length <= max ? clean : `${clean.slice(0, max - 1)}…`;
};

/**
 * Which tabs a notification may deep-link into.
 *
 * This used to be a second copy of the role matrix, and it drifted — the exact
 * failure mode this whole module exists to prevent. `media_studio` is
 * `'all'` in `AuthService.TAB_ROLES` but was a hand-copied nine-role list
 * here, so a `jumuiya_leader` tapping a poster notification was allowed
 * through by one gate and stopped by the other. Ask the real matrix instead of
 * remembering it.
 */
export function canNavigateTo(role: UserRole, tab: string | undefined): boolean {
  if (!tab) return false;
  return AuthService.canRoleAccessTab(role, tab);
}

/**
 * Builds the notification feed.
 *
 * Ordered newest-first, then filtered to what this role is allowed to act on:
 * a choir leader is not shown the secretary's poster queue, and only the
 * people who can approve posters see poster approvals.
 */
export function buildNotifications(input: NotificationInputs): PortalNotification[] {
  const {
    announcements, events, sermons, readAllBefore, readIds, isSw,
  } = input;
  const items: PortalNotification[] = [];

  const isRead = (id: string, ts: number) => readIds.has(id) || (ts > 0 && ts <= readAllBefore);

  for (const a of announcements) {
    const ts = toMillis(a.createdAt);
    const id = `ann-${a.id ?? a.title}`;
    const urgent = a.type === 'urgent' || a.priority === 'high';
    items.push({
      id,
      title: urgent
        ? (isSw ? `Dharura: ${a.title}` : `Urgent: ${a.title}`)
        : a.title,
      description: truncate(a.body || a.content || ''),
      time: relativeTime(ts, isSw),
      timestampMs: ts,
      read: isRead(id, ts),
      type: a.type === 'bereavement' ? 'pastoral' : 'admin',
      // Announcements are managed in the Secretary Office, not on a page of
      // their own: `announcements` is not a route this portal has.
      targetTab: 'secretary_portal',
      alwaysVisible: true,
      sourceSw: 'Tangazo',
      sourceEn: 'Announcement',
    });
  }

  for (const e of events) {
    const ts = toMillis(e.createdAt);
    const id = `evt-${e.id ?? e.title}`;
    const posterWaiting = e.posterStatus === 'requested';
    items.push({
      id,
      title: posterWaiting
        ? (isSw ? `Posta inahitajika: ${e.title}` : `Poster needed: ${e.title}`)
        : e.title,
      description: truncate(
        [e.eventDate, e.venue, e.description].filter(Boolean).join(' · ')
      ),
      time: relativeTime(ts, isSw),
      timestampMs: ts,
      read: isRead(id, ts),
      type: 'jumuiya',
      targetTab: 'media_studio',
      sourceSw: 'Tukio',
      sourceEn: 'Event',
    });
  }

  for (const s of sermons) {
    const ts = toMillis(s.createdAt);
    const id = `srm-${s.id ?? s.title}`;
    items.push({
      id,
      title: isSw ? `Mahubiri mapya: ${s.title}` : `New sermon: ${s.title}`,
      description: truncate(
        [s.preacher, s.scripture, s.description].filter(Boolean).join(' · ')
      ),
      time: relativeTime(ts, isSw),
      timestampMs: ts,
      read: isRead(id, ts),
      type: 'pastoral',
      targetTab: 'pastor_portal',
      sourceSw: 'Mahubiri',
      sourceEn: 'Sermon',
    });
  }

  // Un-timestamped records sort last but stay visible: `orderBy('createdAt')`
  // alone would drop them from the listener entirely.
  items.sort((a, b) => b.timestampMs - a.timestampMs);
  return items.slice(0, 30);
}

/**
 * Drops notifications whose deep link this role cannot open.
 * The announcement feed is public information and stays visible to everyone.
 */
export function filterForRole(
  items: PortalNotification[],
  role: UserRole | undefined
): PortalNotification[] {
  if (!role) return [];
  return items.filter((item) => {
    if (!item.targetTab) return true;
    if (item.alwaysVisible) return true;
    // A notification the role cannot act on is noise: it inflates the unread
    // badge, and tapping it closes the panel without going anywhere. Hide it.
    return canNavigateTo(role, item.targetTab);
  });
}

const READ_KEY = 'zion_portal_notifications_read';
const READ_ALL_KEY = 'zion_portal_notifications_read_all';

interface ReadState {
  ids: Set<string>;
  readAllBefore: number;
}

export function loadReadState(): ReadState {
  try {
    const rawIds = localStorage.getItem(READ_KEY);
    const ids = new Set<string>(rawIds ? (JSON.parse(rawIds) as string[]) : []);
    const rawAll = localStorage.getItem(READ_ALL_KEY);
    const readAllBefore = rawAll ? Number(rawAll) || 0 : 0;
    return { ids, readAllBefore };
  } catch {
    return { ids: new Set<string>(), readAllBefore: 0 };
  }
}

export function saveReadState(state: ReadState): void {
  try {
    // Cap the id list; the "read all" timestamp covers anything older.
    const ids = [...state.ids].slice(-300);
    localStorage.setItem(READ_KEY, JSON.stringify(ids));
    localStorage.setItem(READ_ALL_KEY, String(state.readAllBefore));
  } catch {
    // Persisting read-state is a convenience; never break the page over it.
  }
}
