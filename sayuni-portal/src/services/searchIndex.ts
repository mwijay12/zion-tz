import type { UserRole } from '../types';
import { AuthService } from './authService';
import { readMembers } from './memberStore';
import { CHURCH_CHOIRS, INITIAL_JUMUIYA_GROUPS, INITIAL_SERMONS } from '../data/mockData';

export interface SearchHit {
  id: string;
  label: string;
  context: string;
  tab: string;
  group: 'people' | 'modules' | 'jumuiya' | 'media';
}

interface ModuleEntry {
  id: string;
  sw: string;
  en: string;
  keywords: string[];
}

/**
 * Every destination a leader can reach, with Kiswahili + English words so a
 * search for "misaada"/"welfare" or "fedha"/"finance" both land correctly.
 */
const MODULES: ModuleEntry[] = [
  { id: 'dashboard', sw: 'Dashibodi ya Utawala', en: 'Admin Dashboard', keywords: ['home', 'nyumbani', 'muhtasari'] },
  { id: 'analytics', sw: 'Afya na Takwimu za Kanisa', en: 'Church Health & Analytics', keywords: ['takwimu', 'statistics', 'ripoti'] },
  { id: 'pastor_portal', sw: 'Ofisi ya Askofu na Mchungaji', en: 'Pastoral Studio', keywords: ['askofu', 'bishop', 'mahubiri', 'sermon', 'makala'] },
  { id: 'secretary_portal', sw: 'Ofisi ya Katibu Mkuu', en: 'Secretary Office', keywords: ['katibu', 'secretary', 'matangazo', 'notice', 'bulletin'] },
  { id: 'members', sw: 'Daftari la Waumini', en: 'Members Registry', keywords: ['waumini', 'members', 'akaunti', 'roles', 'wadhifa'] },
  { id: 'deacons_portal', sw: 'Mashemasi na Wageni', en: 'Deacons & Visitors', keywords: ['wageni', 'visitors', 'usher', 'mapokezi'] },
  { id: 'elders_portal', sw: 'Baraza la Wazee', en: 'Elders Board', keywords: ['wazee', 'elders', 'kesi', 'ushauri'] },
  { id: 'finance', sw: 'Hazina na Sadaka', en: 'Finances & Tithes', keywords: ['fedha', 'finance', 'zaka', 'sadaka', 'michango', 'matumizi'] },
  { id: 'jumuiya', sw: 'Jumuiya za Nyumbani', en: 'Home Cells', keywords: ['jumuiya', 'cells', 'vikundi', 'mahudhurio'] },
  { id: 'certificates', sw: 'Vyeti na Nyaraka', en: 'Certificates Studio', keywords: ['vyeti', 'certificate', 'ubatizo', 'harusi', 'nyaraka'] },
  { id: 'choir_portal', sw: 'Kwaya na Muziki', en: 'Choirs & Music', keywords: ['kwaya', 'choir', 'nyimbo', 'muziki', 'tenzi'] },
  { id: 'departments_portal', sw: 'Idara na Shule ya Jumapili', en: 'Departments & Sunday School', keywords: ['idara', 'departments', 'watoto', 'shule'] },
  { id: 'media_studio', sw: 'Studio ya Poster na Matukio', en: 'Poster & Events Studio', keywords: ['poster', 'matukio', 'events', 'picha', 'tangazo'] },
  { id: 'bible', sw: 'Biblia na Madokezo', en: 'Bible & Notes', keywords: ['biblia', 'bible', 'maandiko', 'mada'] },
  { id: 'devotional', sw: 'Neno la Siku', en: 'Daily Devotional', keywords: ['neno', 'devotional', 'tafakari', 'siku'] },
];

function matches(haystack: string, needle: string): boolean {
  return haystack.toLowerCase().includes(needle);
}

/**
 * Client-side search across the modules, the member register and the
 * published content. The topbar field used to be decorative; leaders typed
 * a name, nothing happened, and they assumed the record was missing.
 */
export function searchPortal(query: string, role: UserRole, limit = 8): SearchHit[] {
  const needle = query.trim().toLowerCase();
  if (needle.length < 2) return [];

  const hits: SearchHit[] = [];

  // Modules the signed-in role may actually open — never link to a dead end.
  for (const module of MODULES) {
    if (!AuthService.canRoleAccessTab(role, module.id)) continue;
    if (
      matches(module.sw, needle) ||
      matches(module.en, needle) ||
      module.keywords.some((keyword) => matches(keyword, needle))
    ) {
      hits.push({
        id: `module-${module.id}`,
        label: module.sw,
        context: module.en,
        tab: module.id,
        group: 'modules',
      });
    }
  }

  // People, but only for roles allowed to see the member register.
  if (AuthService.canRoleAccessTab(role, 'members')) {
    for (const member of readMembers()) {
      if (matches(member.fullName, needle) || member.phone.replace(/\s/g, '').includes(needle)) {
        hits.push({
          id: `member-${member.id}`,
          label: member.fullName,
          context: member.phone,
          tab: 'members',
          group: 'people',
        });
      }
      if (hits.filter((hit) => hit.group === 'people').length >= 4) break;
    }
  }

  for (const group of INITIAL_JUMUIYA_GROUPS) {
    if (matches(group.name, needle) || matches(group.location, needle) || matches(group.leaderName, needle)) {
      hits.push({
        id: `jumuiya-${group.id}`,
        label: group.name,
        context: group.leaderName,
        tab: 'jumuiya',
        group: 'jumuiya',
      });
    }
  }

  for (const choir of CHURCH_CHOIRS) {
    if (matches(choir.name ?? '', needle)) {
      hits.push({
        id: `choir-${choir.name}`,
        label: choir.name,
        context: 'Kwaya',
        tab: 'choir_portal',
        group: 'media',
      });
    }
  }

  for (const sermon of INITIAL_SERMONS) {
    if (matches(sermon.title, needle) || matches(sermon.preacher, needle)) {
      hits.push({
        id: `sermon-${sermon.id}`,
        label: sermon.title,
        context: sermon.preacher,
        tab: 'media_studio',
        group: 'media',
      });
    }
  }

  // Prefer modules over long lists, then cap.
  const order: Record<SearchHit['group'], number> = { modules: 0, people: 1, jumuiya: 2, media: 3 };
  return hits.sort((a, b) => order[a.group] - order[b.group]).slice(0, limit);
}
