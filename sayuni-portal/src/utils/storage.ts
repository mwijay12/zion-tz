export const STORAGE_KEYS = {
  finances: 'zion_portal_finances',
  projects: 'zion_portal_projects',
  expenses: 'zion_portal_expenses',
  jumuiyaReports: 'zion_portal_jumuiya_reports',
  members: 'zion_portal_members',
  elderCases: 'zion_portal_elder_cases',
  departments: 'zion_portal_departments',
  pastoralPosters: 'zion_portal_pastoral_posters',
  certificateSettings: 'zion_portal_certificate_settings',
} as const;

export function loadStored<T>(key: string, fallback: T): T {
  if (typeof window === 'undefined') return fallback;

  try {
    const raw = window.localStorage.getItem(key);
    if (!raw) return fallback;

    const parsed = JSON.parse(raw) as T;
    if (Array.isArray(fallback) && !Array.isArray(parsed)) return fallback;

    return parsed ?? fallback;
  } catch {
    return fallback;
  }
}

export function saveStored<T>(key: string, value: T): void {
  try {
    window.localStorage.setItem(key, JSON.stringify(value));
  } catch (e) {
    console.warn(`Error saving ${key}:`, e);
  }
}
