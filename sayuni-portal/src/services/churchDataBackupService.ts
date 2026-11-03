import { 
  CHURCH_PROFILE, 
  INITIAL_FINANCES, 
  INITIAL_PROJECTS, 
  INITIAL_EXPENSES, 
  INITIAL_JUMUIYA_GROUPS, 
  INITIAL_JUMUIYA_REPORTS,
  INITIAL_MEMBERS
} from '../data/mockData';
import { churchSync } from './churchSyncService';
import { loadStored, STORAGE_KEYS } from '../utils/storage';

export interface ChurchDataSnapshot {
  timestamp: string;
  churchProfile: typeof CHURCH_PROFILE;
  finances: {
    records: any[];
    projects: any[];
    expenses: any[];
  };
  members: any[];
  jumuiya: {
    groups: any[];
    reports: any[];
  };
  sermons: any[];
  notices: any[];
  systemVersion: string;
}

const AUTO_BACKUP_STORAGE_KEY = 'zion_auto_backup_vault';
const LAST_BACKUP_TIME_KEY = 'zion_last_auto_backup_timestamp';

export class ChurchDataBackupService {
  /**
   * Generates a complete comprehensive JSON snapshot of all church data
   */
  public static createFullBackupSnapshot(): ChurchDataSnapshot {
    // Collect local and synced data
    const sermons = churchSync.getSermons();
    const notices = churchSync.getNotices();

    return {
      timestamp: new Date().toISOString(),
      churchProfile: CHURCH_PROFILE,
      finances: {
        records: loadStored(STORAGE_KEYS.finances, INITIAL_FINANCES),
        projects: loadStored(STORAGE_KEYS.projects, INITIAL_PROJECTS),
        expenses: loadStored(STORAGE_KEYS.expenses, INITIAL_EXPENSES)
      },
      members: loadStored(STORAGE_KEYS.members, INITIAL_MEMBERS),
      jumuiya: {
        groups: INITIAL_JUMUIYA_GROUPS,
        reports: loadStored(STORAGE_KEYS.jumuiyaReports, INITIAL_JUMUIYA_REPORTS)
      },
      sermons,
      notices,
      systemVersion: 'Zion-Jerusalem-v2.0-Antigravity'
    };
  }

  /**
   * AUTOMATIC BACKUP ENGINE:
   * Periodically & automatically creates snapshots of the database into the browser's persistent storage.
   * If last backup was > 24 hours ago (or on significant updates), it automatically saves a new snapshot.
   */
  public static performAutoBackup(): { success: boolean; timestamp: string; isNew: boolean } {
    try {
      const now = Date.now();
      const lastBackupStr = localStorage.getItem(LAST_BACKUP_TIME_KEY);
      const lastBackup = lastBackupStr ? parseInt(lastBackupStr, 10) : 0;
      
      // Auto backup threshold: Every 6 hours or upon first run
      const SIX_HOURS = 6 * 60 * 60 * 1000;
      const isDue = (now - lastBackup) > SIX_HOURS || !localStorage.getItem(AUTO_BACKUP_STORAGE_KEY);

      if (isDue) {
        const snapshot = this.createFullBackupSnapshot();
        const json = JSON.stringify(snapshot);
        
        // Save to dedicated persistent vault
        localStorage.setItem(AUTO_BACKUP_STORAGE_KEY, json);
        localStorage.setItem(LAST_BACKUP_TIME_KEY, now.toString());
        
        console.log(`[AutoBackup] ✓ Automatic church snapshot saved successfully at ${snapshot.timestamp}`);
        return { success: true, timestamp: snapshot.timestamp, isNew: true };
      }

      const existingDate = new Date(lastBackup).toISOString();
      return { success: true, timestamp: existingDate, isNew: false };
    } catch (e) {
      console.warn('[AutoBackup] Error during automated backup:', e);
      return { success: false, timestamp: new Date().toISOString(), isNew: false };
    }
  }

  /**
   * Returns the last automatic backup timestamp
   */
  public static getLastAutoBackupDate(): string | null {
    try {
      const lastBackupStr = localStorage.getItem(LAST_BACKUP_TIME_KEY);
      if (!lastBackupStr) return null;
      return new Date(parseInt(lastBackupStr, 10)).toLocaleString();
    } catch {
      return null;
    }
  }

  /**
   * Initiates instant client-side file download of the backup
   */
  public static downloadJsonBackup(): void {
    const data = this.createFullBackupSnapshot();
    const jsonString = JSON.stringify(data, null, 2);
    const blob = new Blob([jsonString], { type: 'application/json;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    
    const dateStr = new Date().toISOString().slice(0, 10);
    const link = document.createElement('a');
    link.href = url;
    link.download = `Zion_Jerusalem_Church_Backup_${dateStr}.json`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    // Also update auto-backup timestamp
    localStorage.setItem(LAST_BACKUP_TIME_KEY, Date.now().toString());
  }

  /**
   * Generates a CSV export of church members for Excel or pastoral contact book
   */
  public static downloadMembersCsv(): void {
    const headers = ['ID', 'Jina Kamili', 'Namba ya Simu', 'Jumuiya ID', 'Nafasi', 'Ubatizo'];
    const members = loadStored(STORAGE_KEYS.members, INITIAL_MEMBERS);
    const rows = members.map(m => [
      m.id,
      `"${m.fullName}"`,
      `"${m.phone}"`,
      `"${m.jumuiyaId}"`,
      `"${m.role}"`,
      m.isBaptized ? 'Ndiyo' : 'Hapana'
    ]);

    const csvContent = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);

    const dateStr = new Date().toISOString().slice(0, 10);
    const link = document.createElement('a');
    link.href = url;
    link.download = `Zion_Members_Registry_${dateStr}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }

  /**
   * Generates a CSV export of finances and tithes for Excel or Google Sheets
   */
  public static downloadFinancesCsv(): void {
    const headers = ['Tarehe', 'Aina', 'Kundi / Mradi', 'Maelezo / Notes', 'Kiasi (TZS)', 'Njia ya Malipo', 'Mtoaji / Reference'];
    const finances = loadStored(STORAGE_KEYS.finances, INITIAL_FINANCES);
    const rows = finances.map(f => [
      `"${f.date || ''}"`,
      `"${f.type || ''}"`,
      `"${f.category || ''}"`,
      `"${(f.notes || '').replace(/"/g, '""')}"`,
      f.amount || 0,
      `"${f.paymentMethod || ''}"`,
      `"${(f.isAnonymous ? 'Binafsi (Anonymous)' : f.donorName || f.referenceNumber || '').replace(/"/g, '""')}"`
    ]);

    const csvContent = '\uFEFF' + [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);

    const dateStr = new Date().toISOString().slice(0, 10);
    const link = document.createElement('a');
    link.href = url;
    link.download = `Zion_Fedha_na_Sadaka_${dateStr}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }

  /**
   * Generates a CSV export of Jumuiya weekly fellowship reports for Excel or Google Sheets
   */
  public static downloadJumuiyaReportsCsv(): void {
    const headers = ['Tarehe ya Ripoti', 'Jumuiya', 'Wanaume', 'Wanawake', 'Vijana', 'Watoto', 'Jumla ya Waumini', 'Wageni Wapya', 'Sadaka (TZS)', 'Mada ya Biblia', 'Imewasilishwa Na'];
    const reports = loadStored(STORAGE_KEYS.jumuiyaReports, INITIAL_JUMUIYA_REPORTS);
    const rows = reports.map(r => {
      const total = (r.attendeesMen || 0) + (r.attendeesWomen || 0) + (r.attendeesYouth || 0) + (r.attendeesChildren || 0);
      return [
        `"${r.reportDate || ''}"`,
        `"${r.jumuiyaName || r.jumuiyaId || ''}"`,
        r.attendeesMen || 0,
        r.attendeesWomen || 0,
        r.attendeesYouth || 0,
        r.attendeesChildren || 0,
        total,
        r.newVisitors || 0,
        r.offeringAmount || 0,
        `"${(r.scriptureTopic || '').replace(/"/g, '""')}"`,
        `"${r.submittedBy || ''}"`
      ];
    });

    const csvContent = '\uFEFF' + [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);

    const dateStr = new Date().toISOString().slice(0, 10);
    const link = document.createElement('a');
    link.href = url;
    link.download = `Zion_Ripoti_za_Jumuiya_${dateStr}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }
}
