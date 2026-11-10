import React, { useState, useEffect } from 'react';
import { 
  FileText, 
  Printer, 
  Megaphone, 
  Plus, 
  CheckCircle2, 
  AlertTriangle,
  Award,
  Users,
  Download,
  Database,
  Calendar,
  Flame,
  Trash2,
  ShieldCheck,
  Briefcase,
  Check,
  Search
} from 'lucide-react';
import type { 
  Language, 
  BulletinNotice, 
  JumuiyaReport, 
  JumuiyaGroup,
  ChurchFastingCampaign,
  MemberSkillListing,
  VisitorRecord
} from '../types';
import { 
  CHURCH_PROFILE, 
  INITIAL_FASTING_CAMPAIGN, 
  INITIAL_MEMBER_SKILLS 
} from '../data/mockData';
import { churchSync } from '../services/churchSyncService';
import { ChurchDataBackupService } from '../services/churchDataBackupService';
import { FirebaseChurchService } from '../services/firebaseChurchService';
import { createId } from '../utils/id';

import { PrintableOfficialReport } from './PrintableOfficialReport';

interface SecretaryPortalProps {
  language: Language;
  reports: JumuiyaReport[];
  groups: JumuiyaGroup[];
  setActiveTab: (tab: string) => void;
}

export const SecretaryPortal: React.FC<SecretaryPortalProps> = ({
  language,
  reports,
  groups,
  setActiveTab
}) => {
  const isSw = language === 'sw';
  const [notices, setNotices] = useState<BulletinNotice[]>(() => churchSync.getNotices());
  const [showNoticeModal, setShowNoticeModal] = useState(false);
  const [activeReportModal, setActiveReportModal] = useState<'visitors' | 'groups' | 'bulletin' | null>(null);
  const [title, setTitle] = useState('');
  const [category, setCategory] = useState<any>('Taarifa Kuu');
  const [targetAudience, setTargetAudience] = useState<'all' | 'leaders' | 'elders' | 'choir' | 'jumuiya' | 'member'>('all');
  const [targetUid, setTargetUid] = useState('');
  const [targetJumuiya, setTargetJumuiya] = useState('');
  const [noticeType, setNoticeType] = useState<'normal' | 'urgent' | 'bereavement'>('normal');
  const [branch, setBranch] = useState<string>('Zote');
  const [content, setContent] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Load visitors from churchSync or localStorage
  const [visitors, setVisitors] = useState<VisitorRecord[]>(() => {
    const synced = churchSync.getVisitors();
    if (synced && synced.length > 0) return synced;
    try {
      const saved = localStorage.getItem('zion_portal_visitors');
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });

  // Fasting Campaign Management State
  const [fastingCampaign, setFastingCampaign] = useState<ChurchFastingCampaign>(() => {
    try {
      const saved = localStorage.getItem('zion_fasting_campaign');
      return saved ? JSON.parse(saved) : INITIAL_FASTING_CAMPAIGN;
    } catch {
      return INITIAL_FASTING_CAMPAIGN;
    }
  });
  const [isEditingFasting, setIsEditingFasting] = useState(false);
  const [fastingForm, setFastingForm] = useState(fastingCampaign);

  // Member Skills Directory Moderation State
  const [memberSkills, setMemberSkills] = useState<MemberSkillListing[]>(() => {
    try {
      const saved = localStorage.getItem('zion_member_skills');
      return saved ? JSON.parse(saved) : INITIAL_MEMBER_SKILLS;
    } catch {
      return INITIAL_MEMBER_SKILLS;
    }
  });
  const [skillSearch, setSkillSearch] = useState('');
  const [skillCategoryFilter, setSkillCategoryFilter] = useState('all');

  const filteredSkills = memberSkills.filter((s) => {
    const matchesSearch =
      s.fullName.toLowerCase().includes(skillSearch.toLowerCase()) ||
      s.profession.toLowerCase().includes(skillSearch.toLowerCase()) ||
      s.location.toLowerCase().includes(skillSearch.toLowerCase()) ||
      s.jumuiya.toLowerCase().includes(skillSearch.toLowerCase());
    const matchesCategory =
      skillCategoryFilter === 'all' || s.category.toLowerCase().includes(skillCategoryFilter.toLowerCase());
    return matchesSearch && matchesCategory;
  });

  useEffect(() => {
    try {
      localStorage.setItem('zion_fasting_campaign', JSON.stringify(fastingCampaign));
    } catch {}
  }, [fastingCampaign]);

  useEffect(() => {
    try {
      localStorage.setItem('zion_member_skills', JSON.stringify(memberSkills));
    } catch {}
  }, [memberSkills]);

  const handleDeleteNotice = (id: string) => {
    if (confirm(isSw ? 'Je, una uhakika unataka kufuta tangazo hili?' : 'Are you sure you want to delete this notice?')) {
      const updated = notices.filter(n => n.id !== id);
      setNotices(updated);
      try {
        localStorage.setItem('zion_bulletin_notices', JSON.stringify(updated));
      } catch {}
    }
  };

  const handleToggleNoticeUrgent = (id: string) => {
    const updated = notices.map(n => n.id === id ? { ...n, isUrgent: !n.isUrgent, type: (!n.isUrgent ? 'urgent' : 'normal') as any } : n);
    setNotices(updated);
    try {
      localStorage.setItem('zion_bulletin_notices', JSON.stringify(updated));
    } catch {}
  };

  const handleSaveFasting = (e: React.FormEvent) => {
    e.preventDefault();
    setFastingCampaign(fastingForm);
    setIsEditingFasting(false);
    setFeedback({
      type: 'success',
      message: isSw ? '✓ Taarifa za mfungo wa kanisa zimehifadhiwa na kusawazishwa!' : '✓ Fasting campaign saved and synced!'
    });
    setTimeout(() => setFeedback(null), 3000);
  };

  const handleToggleFastingActive = () => {
    setFastingCampaign(prev => ({ ...prev, isActive: !prev.isActive }));
  };

  const handleToggleApproveSkill = (id: string) => {
    setMemberSkills(prev => prev.map(s => s.id === id ? { ...s, isApproved: !s.isApproved } : s));
  };

  const handleToggleVerifySkillMember = (id: string) => {
    setMemberSkills(prev => prev.map(s => s.id === id ? { ...s, isVerifiedMember: !s.isVerifiedMember } : s));
  };

  const handleDeleteSkill = (id: string) => {
    if (confirm(isSw ? 'Je, una uhakika unataka kuondoa ujuzi huu kwenye orodha?' : 'Are you sure you want to remove this skill listing?')) {
      setMemberSkills(prev => prev.filter(s => s.id !== id));
    }
  };

  useEffect(() => {
    // 1. Live Firestore stream subscription
    const unsubscribeFirestore = FirebaseChurchService.subscribeToAnnouncements((firestoreItems) => {
      if (firestoreItems && firestoreItems.length > 0) {
        const mapped: BulletinNotice[] = firestoreItems.map(item => ({
          id: item.id || createId('doc'),
          title: item.title,
          category: (item.category as any) || 'Taarifa Kuu',
          content: item.body || item.content || '',
          date: item.createdAt?.toDate ? item.createdAt.toDate().toLocaleDateString(isSw ? 'sw-TZ' : 'en-US') : 'Hivi karibuni',
          isUrgent: item.type === 'urgent' || item.priority === 'high',
          type: item.type || 'normal',
          branch: item.branch || 'Zote',
          targetAudience: item.targetAudience || 'all',
          authorRole: item.authorRole || 'Ofisi ya Katibu Mkuu',
          authorEmail: item.authorEmail || ''
        }));
        setNotices(mapped);
      }
    });

    // 2. Local events
    const unsubscribeSync = churchSync.subscribe((msg) => {
      if (msg.type === 'VISITOR_ADDED' || msg.type === 'VISITORS_UPDATED') {
        setVisitors(churchSync.getVisitors());
      }
    });

    return () => {
      unsubscribeFirestore();
      unsubscribeSync();
    };
  }, [isSw]);

  const totalOfferings = reports.reduce((acc, r) => acc + r.offeringAmount, 0);
  const totalAttendees = reports.reduce((acc, r) => acc + r.attendeesMen + r.attendeesWomen + r.attendeesYouth + r.attendeesChildren, 0);

  const handleCreateNotice = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !content.trim() || isSubmitting) return;

    setIsSubmitting(true);
    setFeedback(null);

    const newNotice: BulletinNotice = {
      id: createId('bul'),
      title: title.trim(),
      category,
      content: content.trim(),
      date: new Date().toLocaleDateString(isSw ? 'sw-TZ' : 'en-US', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }),
      isUrgent: noticeType === 'urgent',
      type: noticeType,
      branch,
      targetAudience,
      targetUid: targetAudience === 'member' && targetUid.trim() ? targetUid.trim() : undefined,
      targetJumuiya: targetAudience === 'jumuiya' && targetJumuiya.trim() ? targetJumuiya.trim() : undefined,
      authorRole: 'Ofisi ya Katibu Mkuu wa Kanisa',
      authorEmail: 'katibu@zionjerusalem.org'
    };

    try {
      await churchSync.addNotice(newNotice);
      setNotices(churchSync.getNotices());
      setFeedback({
        type: 'success',
        message: isSw
          ? '✓ Tangazo limechapishwa kwenye Cloud Firestore na litaonekana kwenye simu zote za waumini!'
          : '✓ Announcement published to Cloud Firestore and synced with member devices!'
      });

      setTimeout(() => {
        setShowNoticeModal(false);
        setFeedback(null);
        setTitle('');
        setContent('');
        setNoticeType('normal');
        setBranch('Zote');
        setTargetAudience('all');
        setTargetUid('');
        setTargetJumuiya('');
      }, 1400);
    } catch (err: any) {
      setNotices(churchSync.getNotices());
      setFeedback({
        type: 'error',
        message: isSw
          ? `Tangazo limehifadhiwa kwenye kifaa hiki, lakini halijasawazishwa na Cloud Firestore: ${err?.message || 'Kagua muunganisho wa internet au sheria za usalama.'}`
          : `The notice was saved on this device but not synced to Cloud Firestore: ${err?.message || 'Check network connection or Firestore security rules.'}`
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="secretary-portal-container" style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Secretariat Hero Banner - Sanctuary Navy & Electric Blue */}
      <div 
        className="dark-hero"
        style={{
          background: 'linear-gradient(135deg, #0A2540 0%, #082F70 55%, #0D52CD 100%)',
          color: '#ffffff',
          padding: '2rem',
          borderRadius: 'var(--radius-lg)',
          boxShadow: 'var(--shadow-lg)',
          border: '1px solid rgba(13, 82, 205, 0.35)'
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem', marginBottom: '0.45rem' }}>
              <span className="badge" style={{ background: 'rgba(219, 234, 254, 0.22)', color: '#dbeafe', border: '1px solid rgba(219, 234, 254, 0.45)' }}>
                <Megaphone size={13} />
                {isSw ? 'Sekretarieti Kuu ya Kanisa' : 'General Secretariat Portal'}
              </span>
              <span style={{ fontSize: '0.8rem', color: '#dbeafe' }}>
                {CHURCH_PROFILE.location}
              </span>
            </div>

            <h2 style={{ fontSize: '1.85rem', fontWeight: 800, margin: '0 0 0.4rem 0', letterSpacing: '-0.02em', color: '#ffffff' }}>
              {isSw ? 'Ofisi ya Katibu Mkuu wa Kanisa' : 'Office of the Church General Secretary'}
            </h2>

            <p style={{ fontSize: '0.88rem', color: '#dee1ff', margin: 0, maxWidth: '750px', lineHeight: 1.55 }}>
              {isSw 
                ? 'Kuratibu matangazo ya Jumapili, kuzalisha vijarida vya ubaoni (printable bulletin), na kukusanya ripoti zote za vikundi vya nyumba kwa nyumba.'
                : 'Managing church announcements, generating 1-page printable notice board bulletins, and consolidating home cell reports.'}
            </p>
          </div>

          <div style={{ display: 'flex', gap: '0.65rem', flexWrap: 'wrap' }}>
            <button 
              onClick={() => setShowNoticeModal(true)}
              className="btn-primary"
              style={{ padding: '0.6rem 1.25rem', background: '#0D52CD', color: '#ffffff' }}
            >
              <Plus size={16} />
              <span>{isSw ? '+ Tangazo Jipya' : '+ New Notice'}</span>
            </button>

            <button 
              onClick={() => setActiveReportModal('bulletin')}
              className="btn-secondary"
              title="Zalisha Kijarida Rasmi cha Ubaoni (PDF / Print)"
              style={{ padding: '0.6rem 1.25rem', background: 'rgba(255,255,255,0.14)', color: '#ffffff', borderColor: 'rgba(255,255,255,0.35)', backdropFilter: 'blur(8px)' }}
            >
              <Printer size={16} />
              <span>{isSw ? 'Print Kijarida (PDF)' : 'Print Bulletin (PDF)'}</span>
            </button>

            <button 
              onClick={() => setActiveReportModal('visitors')}
              className="btn-secondary"
              title="Zalisha Ripoti Rasmi ya Wageni ya Mwezi (PDF / Print)"
              style={{ padding: '0.6rem 1.15rem', background: 'rgba(219, 234, 254, 0.22)', color: '#ffffff', borderColor: '#93c5fd' }}
            >
              <FileText size={16} />
              <span>{isSw ? 'Ripoti ya Wageni (PDF)' : 'Visitors Report'}</span>
            </button>

            <button 
              onClick={() => setActiveReportModal('groups')}
              className="btn-secondary"
              title="Zalisha Ripoti Rasmi ya Vikundi & Jumuiya (PDF / Print)"
              style={{ padding: '0.6rem 1.15rem', background: 'rgba(245, 158, 11, 0.22)', color: '#fbbf24', borderColor: '#f59e0b' }}
            >
              <Users size={16} />
              <span>{isSw ? 'Ripoti ya Vikundi (PDF)' : 'Groups Report'}</span>
            </button>

            <button 
              onClick={() => ChurchDataBackupService.downloadJsonBackup()}
              className="btn-secondary"
              title={isSw ? 'Pakua backup kamili ya data ya kanisa (JSON)' : 'Download full church data backup (JSON)'}
              style={{ padding: '0.6rem 1.1rem', background: 'rgba(16, 185, 129, 0.22)', color: '#10b981', borderColor: 'rgba(16, 185, 129, 0.45)', backdropFilter: 'blur(8px)', fontWeight: 700 }}
            >
              <Database size={16} />
              <span>{isSw ? 'Backup Vault (JSON)' : 'Backup Vault'}</span>
            </button>

            <button 
              onClick={() => ChurchDataBackupService.downloadMembersCsv()}
              className="btn-secondary"
              title={isSw ? 'Pakua orodha ya waumini (Excel / CSV)' : 'Export members list to Excel/CSV'}
              style={{ padding: '0.6rem 1.1rem', background: 'rgba(255,255,255,0.1)', color: '#ffffff', borderColor: 'rgba(255,255,255,0.25)' }}
            >
              <Download size={16} />
              <span>{isSw ? 'Excel Daftari' : 'Export CSV'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* KPI Overview */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
        <div className="church-card" style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '8px', background: 'var(--primary-100)', color: 'var(--primary-700)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Megaphone size={24} />
          </div>
          <div>
            <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', fontWeight: 600 }}>{isSw ? 'MATANGAZO YA WIKI' : 'ACTIVE NOTICES'}</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-headline)' }}>{notices.length}</div>
          </div>
        </div>

        <div className="church-card" style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '8px', background: 'var(--gold-100)', color: 'var(--gold-700)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Users size={24} />
          </div>
          <div>
            <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', fontWeight: 600 }}>{isSw ? 'WALIOHUDHURIA JUMUIYA' : 'CELL ATTENDANCE'}</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-headline)' }}>{totalAttendees}</div>
          </div>
        </div>

        <div className="church-card" style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '8px', background: 'var(--emerald-100)', color: 'var(--emerald-600)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <FileText size={24} />
          </div>
          <div>
            <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', fontWeight: 600 }}>{isSw ? 'SADAKA ZA JUMUIYA' : 'CELL OFFERINGS'}</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-headline)' }}>Tsh {totalOfferings.toLocaleString()}</div>
          </div>
        </div>
      </div>

      {/* Announcements Manager */}
      <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem' }}>
          <div>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
              {isSw ? 'Injini ya Matangazo ya Kanisa (Digital & Board)' : 'Church Announcements Engine'}
            </h3>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
              {isSw ? 'Matangazo haya yanasawazishwa kwenye simu na kwenye kijarida cha kuchapishwa' : 'Synced live to congregant phones and printable 1-page paper bulletin'}
            </span>
          </div>

          <button 
            onClick={() => setShowNoticeModal(true)}
            className="btn-primary"
            style={{ fontSize: '0.85rem' }}
          >
            <Plus size={15} />
            <span>{isSw ? '+ Tangazo Jipya' : '+ New Announcement'}</span>
          </button>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
          {notices.map((notice) => (
            <div 
              key={notice.id}
              style={{
                background: 'var(--bg-app)',
                border: notice.isUrgent ? '1.5px solid #ef4444' : '1px solid var(--border-subtle)',
                borderRadius: 'var(--radius-sm)',
                padding: '1.1rem',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.5rem',
                borderLeft: notice.isUrgent ? '4px solid #ef4444' : '4px solid var(--primary-700)'
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '0.5rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  {notice.isUrgent && (
                    <span className="badge badge-red" style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                      <AlertTriangle size={12} /> {isSw ? 'Dharura' : 'Urgent'}
                    </span>
                  )}
                  <span className="badge badge-blue">
                    {notice.category}
                  </span>
                  <span 
                    className={`badge ${notice.targetAudience === 'leaders' || notice.targetAudience === 'elders' ? 'badge-gold' : 'badge-blue'}`}
                    style={{ fontSize: '0.72rem', fontWeight: 700 }}
                  >
                    {notice.targetAudience === 'leaders' 
                      ? '🔒 Viongozi Tu' 
                      : (notice.targetAudience === 'elders' 
                          ? '🔒 Wazee Tu' 
                          : (notice.targetAudience === 'choir' ? '🎵 Kwaya' : '📢 Waumini Wote'))}
                  </span>
                  <strong style={{ fontSize: '1.05rem', color: 'var(--text-headline)' }}>
                    {notice.title}
                  </strong>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                    {notice.date}
                  </span>
                  <button
                    onClick={() => handleToggleNoticeUrgent(notice.id)}
                    title={notice.isUrgent ? 'Ondoa dharura' : 'Weka kama dharura'}
                    style={{
                      background: 'none',
                      border: 'none',
                      cursor: 'pointer',
                      color: notice.isUrgent ? '#ef4444' : 'var(--text-muted)',
                      padding: '4px',
                      borderRadius: '4px'
                    }}
                  >
                    <AlertTriangle size={15} />
                  </button>
                  <button
                    onClick={() => handleDeleteNotice(notice.id)}
                    title="Futa Tangazo"
                    style={{
                      background: 'none',
                      border: 'none',
                      cursor: 'pointer',
                      color: 'var(--text-muted)',
                      padding: '4px',
                      borderRadius: '4px'
                    }}
                  >
                    <Trash2 size={15} />
                  </button>
                </div>
              </div>

              <p style={{ fontSize: '0.88rem', color: 'var(--text-body)', margin: 0, lineHeight: 1.5 }}>
                {notice.content}
              </p>
            </div>
          ))}
        </div>
      </div>

      {/* Udhibiti wa Mifungo ya Kanisa (Church Fasting Management) */}
      <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
              <Flame size={22} style={{ color: '#f59e0b' }} />
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, margin: 0, color: 'var(--text-headline)' }}>
                {isSw ? 'Mifungo na Maombi ya Kanisa' : 'Church Fasting & Prayer Programs'}
              </h3>
            </div>
            <p style={{ fontSize: '0.88rem', color: 'var(--text-muted)', margin: '0.35rem 0 0 0' }}>
              {isSw 
                ? 'Dhibiti ratiba ya mifungo, miongozo na mistari ya kiroho inayoonekana kwenye Chumba cha Maombi cha App ya Waumini.' 
                : 'Manage church fasting schedules, prayer guides, and scriptures displayed on member mobile apps.'}
            </p>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <button
              onClick={handleToggleFastingActive}
              className={`badge ${fastingCampaign.isActive ? 'badge-gold' : 'badge-blue'}`}
              style={{
                cursor: 'pointer',
                padding: '0.5rem 0.9rem',
                fontSize: '0.82rem',
                display: 'flex',
                alignItems: 'center',
                gap: '0.4rem',
                border: 'none'
              }}
            >
              <Flame size={14} />
              <span>{fastingCampaign.isActive ? (isSw ? 'Mfungo Unaendelea (Washa)' : 'Fasting Active') : (isSw ? 'Mfungo Umezimwa' : 'Fasting Paused')}</span>
            </button>
            <button
              onClick={() => setIsEditingFasting(!isEditingFasting)}
              className="btn-primary"
              style={{ fontSize: '0.85rem' }}
            >
              <Calendar size={15} />
              <span>{isEditingFasting ? (isSw ? 'Funga Fomu' : 'Close Form') : (isSw ? 'Badili Ratiba ya Mfungo' : 'Edit Fasting Campaign')}</span>
            </button>
          </div>
        </div>

        {/* Current Fasting Info Card */}
        <div style={{
          background: 'var(--bg-app)',
          border: '1.5px solid var(--gold-500)',
          borderRadius: 'var(--radius-sm)',
          padding: '1.2rem',
          display: 'flex',
          flexDirection: 'column',
          gap: '0.75rem'
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '0.5rem' }}>
            <div>
              <span className="badge badge-gold" style={{ marginBottom: '0.4rem', display: 'inline-block' }}>
                {fastingCampaign.fastType}
              </span>
              <h4 style={{ fontSize: '1.15rem', fontWeight: 700, margin: '0.2rem 0', color: 'var(--text-headline)' }}>
                {fastingCampaign.title}
              </h4>
              <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                {fastingCampaign.startDate} hadi {fastingCampaign.endDate}
              </span>
            </div>
            <div style={{ textAlign: 'right' }}>
              <span style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--gold-600)' }}>
                {fastingCampaign.participantsCount.toLocaleString()}
              </span>
              <span style={{ display: 'block', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                {isSw ? 'Washiriki Waliojiunga' : 'Joined Participants'}
              </span>
            </div>
          </div>

          <div style={{ background: 'rgba(212, 168, 71, 0.08)', padding: '0.75rem 1rem', borderRadius: '6px', borderLeft: '3px solid var(--gold-500)' }}>
            <strong style={{ fontSize: '0.85rem', color: 'var(--gold-700)', display: 'block', marginBottom: '0.2rem' }}>
              Neno la Kiroho & Maandiko:
            </strong>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-body)', margin: 0, fontStyle: 'italic' }}>
              {fastingCampaign.themeVerse}
            </p>
          </div>

          <p style={{ fontSize: '0.86rem', color: 'var(--text-body)', margin: 0 }}>
            <strong>Mwongozo:</strong> {fastingCampaign.guidelines}
          </p>
        </div>

        {/* Edit Fasting Form */}
        {isEditingFasting && (
          <form onSubmit={handleSaveFasting} style={{
            background: 'var(--bg-app)',
            border: '1px solid var(--border-subtle)',
            borderRadius: 'var(--radius-sm)',
            padding: '1.25rem',
            display: 'flex',
            flexDirection: 'column',
            gap: '1rem'
          }}>
            <h4 style={{ fontSize: '1rem', fontWeight: 700, margin: 0, color: 'var(--text-headline)' }}>
              {isSw ? 'Hariri Ratiba & Neno la Mfungo' : 'Update Fasting Campaign Details'}
            </h4>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1rem' }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, marginBottom: '0.35rem' }}>
                  Jina la Mfungo
                </label>
                <input
                  type="text"
                  required
                  value={fastingForm.title}
                  onChange={(e) => setFastingForm({ ...fastingForm, title: e.target.value })}
                  className="input-field"
                  style={{ width: '100%', padding: '0.55rem 0.75rem', borderRadius: '6px', border: '1px solid var(--border-subtle)' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, marginBottom: '0.35rem' }}>
                  Aina & Masaa ya Mfungo
                </label>
                <input
                  type="text"
                  required
                  placeholder="Mfano: Danieli (Saa 00:00 Usiku hadi Saa 12:00 Jioni)"
                  value={fastingForm.fastType}
                  onChange={(e) => setFastingForm({ ...fastingForm, fastType: e.target.value })}
                  className="input-field"
                  style={{ width: '100%', padding: '0.55rem 0.75rem', borderRadius: '6px', border: '1px solid var(--border-subtle)' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, marginBottom: '0.35rem' }}>
                  Tarehe ya Kuanza
                </label>
                <input
                  type="date"
                  required
                  value={fastingForm.startDate}
                  onChange={(e) => setFastingForm({ ...fastingForm, startDate: e.target.value })}
                  className="input-field"
                  style={{ width: '100%', padding: '0.55rem 0.75rem', borderRadius: '6px', border: '1px solid var(--border-subtle)' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, marginBottom: '0.35rem' }}>
                  Tarehe ya Kumaliza
                </label>
                <input
                  type="date"
                  required
                  value={fastingForm.endDate}
                  onChange={(e) => setFastingForm({ ...fastingForm, endDate: e.target.value })}
                  className="input-field"
                  style={{ width: '100%', padding: '0.55rem 0.75rem', borderRadius: '6px', border: '1px solid var(--border-subtle)' }}
                />
              </div>

              <div style={{ gridColumn: 'span 2' }}>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, marginBottom: '0.35rem' }}>
                  Mstari wa Kiroho & Maandiko (Theme Verse)
                </label>
                <input
                  type="text"
                  required
                  placeholder="Mfano: Isaya 58:6 — Je! mfungo niliouchagua si wa namna hii?..."
                  value={fastingForm.themeVerse}
                  onChange={(e) => setFastingForm({ ...fastingForm, themeVerse: e.target.value })}
                  className="input-field"
                  style={{ width: '100%', padding: '0.55rem 0.75rem', borderRadius: '6px', border: '1px solid var(--border-subtle)' }}
                />
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 600, marginBottom: '0.35rem' }}>
                Mwongozo wa Maombi na Maelekezo
              </label>
              <textarea
                required
                rows={3}
                value={fastingForm.guidelines}
                onChange={(e) => setFastingForm({ ...fastingForm, guidelines: e.target.value })}
                className="input-field"
                style={{ width: '100%', padding: '0.55rem 0.75rem', borderRadius: '6px', border: '1px solid var(--border-subtle)' }}
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                type="button"
                onClick={() => setIsEditingFasting(false)}
                className="btn-outline"
                style={{ fontSize: '0.85rem' }}
              >
                Ghairi
              </button>
              <button
                type="submit"
                className="btn-primary"
                style={{ fontSize: '0.85rem' }}
              >
                Hifadhi Mabadiliko ya Mfungo
              </button>
            </div>
          </form>
        )}
      </div>

      {/* Uhakiki wa Ujuzi & Biashara za Waumini (Member Skills Moderation) */}
      <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
              <Briefcase size={22} style={{ color: 'var(--gold-600)' }} />
              <h3 style={{ fontSize: '1.25rem', fontWeight: 700, margin: 0, color: 'var(--text-headline)' }}>
                {isSw ? 'Uhakiki wa Ujuzi & Biashara za Waumini' : 'Member Skills & Business Moderation'}
              </h3>
            </div>
            <p style={{ fontSize: '0.88rem', color: 'var(--text-muted)', margin: '0.35rem 0 0 0' }}>
              {isSw 
                ? 'Thibitisha na idhinisha ujuzi na biashara za waumini kabla ya kuonekana hadharani. Ulinzi wa namba za simu unazingatiwa kulingana na Sheria ya PDPA 2022.' 
                : 'Review, verify, and moderate church member professional listings in accordance with PDPA 2022.'}
            </p>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span className="badge badge-gold" style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
              <ShieldCheck size={14} />
              <span>PDPA 2022 Imelindwa</span>
            </span>
          </div>
        </div>

        {/* Filter & Search Bar */}
        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
          <div style={{ flex: 1, minWidth: '220px', position: 'relative' }}>
            <Search size={16} style={{ position: 'absolute', left: '10px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
            <input
              type="text"
              placeholder={isSw ? 'Tafuta kwa jina la muumini, ujuzi au tawi...' : 'Search by member name, skill or branch...'}
              value={skillSearch}
              onChange={(e) => setSkillSearch(e.target.value)}
              style={{
                width: '100%',
                padding: '0.55rem 0.75rem 0.55rem 2.2rem',
                borderRadius: '6px',
                border: '1px solid var(--border-subtle)',
                background: 'var(--bg-app)',
                color: 'var(--text-body)',
                fontSize: '0.85rem'
              }}
            />
          </div>

          <select
            value={skillCategoryFilter}
            onChange={(e) => setSkillCategoryFilter(e.target.value)}
            style={{
              padding: '0.55rem 0.85rem',
              borderRadius: '6px',
              border: '1px solid var(--border-subtle)',
              background: 'var(--bg-app)',
              color: 'var(--text-body)',
              fontSize: '0.85rem'
            }}
          >
            <option value="all">Kategoria Zote</option>
            <option value="Ufundi">Ufundi</option>
            <option value="Tehama">Tehama & Apps</option>
            <option value="Kilimo">Kilimo & Mifugo</option>
            <option value="Mavazi">Mavazi & Urembo</option>
            <option value="Afya">Afya & Ustawi</option>
            <option value="Elimu">Elimu & Mafunzo</option>
          </select>
        </div>

        {/* Skills List Table */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
          {filteredSkills.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-muted)' }}>
              Hakuna ujuzi uliopatikana kwa kigezo hiki.
            </div>
          ) : (
            filteredSkills.map((item) => (
              <div
                key={item.id}
                style={{
                  background: 'var(--bg-app)',
                  border: item.isApproved ? '1px solid var(--border-subtle)' : '1.5px solid #f59e0b',
                  borderRadius: 'var(--radius-sm)',
                  padding: '1rem 1.25rem',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  flexWrap: 'wrap',
                  gap: '1rem'
                }}
              >
                <div style={{ flex: 1, minWidth: '260px', display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flexWrap: 'wrap' }}>
                    <strong style={{ fontSize: '1rem', color: 'var(--text-headline)' }}>
                      {item.fullName}
                    </strong>
                    {item.isVerifiedMember && (
                      <span className="badge badge-gold" style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.72rem' }}>
                        <ShieldCheck size={12} /> Muumini Mthibitishwa
                      </span>
                    )}
                    <span className="badge badge-blue" style={{ fontSize: '0.72rem' }}>
                      {item.category}
                    </span>
                    <span className={`badge ${item.isApproved ? 'badge-green' : 'badge-gold'}`} style={{ fontSize: '0.72rem' }}>
                      {item.isApproved ? '✓ Imethibitishwa Kuonyeshwa' : '⏳ Inasubiri Idhini'}
                    </span>
                  </div>

                  <div style={{ fontSize: '0.88rem', fontWeight: 600, color: 'var(--gold-700)' }}>
                    {item.profession} ({item.experienceYears})
                  </div>

                  <p style={{ fontSize: '0.82rem', color: 'var(--text-body)', margin: 0, lineHeight: 1.4 }}>
                    {item.description}
                  </p>

                  <div style={{ display: 'flex', gap: '1rem', fontSize: '0.78rem', color: 'var(--text-muted)', flexWrap: 'wrap' }}>
                    <span>📍 {item.location} ({item.jumuiya})</span>
                    <span>📞 {item.phone}</span>
                    <span>🕒 {item.createdAt}</span>
                  </div>
                </div>

                {/* Moderation Actions */}
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flexWrap: 'wrap' }}>
                  <button
                    onClick={() => handleToggleApproveSkill(item.id)}
                    className={item.isApproved ? 'btn-outline' : 'btn-primary'}
                    style={{ fontSize: '0.78rem', padding: '0.45rem 0.75rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}
                  >
                    <Check size={14} />
                    <span>{item.isApproved ? 'Sitisha Kuonyesha' : 'Idhinisha'}</span>
                  </button>

                  <button
                    onClick={() => handleToggleVerifySkillMember(item.id)}
                    className="btn-outline"
                    style={{ fontSize: '0.78rem', padding: '0.45rem 0.75rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}
                    title={item.isVerifiedMember ? 'Ondoa uthibitisho wa muumini' : 'Thibitisha muumini'}
                  >
                    <ShieldCheck size={14} style={{ color: item.isVerifiedMember ? 'var(--gold-600)' : 'inherit' }} />
                    <span>{item.isVerifiedMember ? 'Mthibitishwa' : 'Thibitisha Muumini'}</span>
                  </button>

                  <button
                    onClick={() => handleDeleteSkill(item.id)}
                    title="Futa Ujuzi Huu"
                    style={{
                      background: 'none',
                      border: 'none',
                      cursor: 'pointer',
                      color: 'var(--text-muted)',
                      padding: '6px',
                      borderRadius: '4px'
                    }}
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Quick Navigation to Certificates and Cell Management */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '1.25rem' }}>
        <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Award size={20} style={{ color: 'var(--gold-600)' }} />
            <h4 style={{ fontSize: '1.05rem', fontWeight: 700, margin: 0 }}>
              {isSw ? 'Utoaji wa Vyeti Rasmi' : 'Official Certificate Studio'}
            </h4>
          </div>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', margin: 0 }}>
            {isSw 
              ? 'Thibitisha na uchapishe vyeti vya ubatizo, ndoa na wakfu vilivyosainiwa na Askofu Mercy James.'
              : 'Endorse and print official certificates with church seals.'}
          </p>
          <button onClick={() => setActiveTab('certificates')} className="btn-primary" style={{ marginTop: 'auto' }}>
            <Award size={15} />
            <span>{isSw ? 'Fungua Studio ya Vyeti' : 'Open Certificate Studio'}</span>
          </button>
        </div>

        <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Users size={20} style={{ color: 'var(--primary-600)' }} />
            <h4 style={{ fontSize: '1.05rem', fontWeight: 700, margin: 0 }}>
              {isSw ? `Usimamizi wa Jumuiya ${groups.length} za Nyumbani` : `${groups.length} Home Cell Fellowships`}
            </h4>
          </div>
          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', margin: 0 }}>
            {isSw 
              ? 'Kwa Matope, Mbagala Kuu, Rangi Tatu, Chamazi na Charambe zimewasilisha ripoti za wiki hii.'
              : 'All 5 local branches reporting directly to the church administration.'}
          </p>
          <button onClick={() => setActiveTab('jumuiya')} className="btn-gold" style={{ marginTop: 'auto' }}>
            <Users size={15} />
            <span>{isSw ? 'Kagua Ripoti za Jumuiya' : 'Review Cell Reports'}</span>
          </button>
        </div>
      </div>

      {/* MODAL: NEW NOTICE */}
      {showNoticeModal && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(0,0,0,0.7)',
          zIndex: 1000,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '1rem'
        }}>
          <div className="church-card" style={{ maxWidth: '540px', width: '100%', maxHeight: '92vh', overflowY: 'auto' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '0.3rem', color: 'var(--text-headline)' }}>
              {isSw ? 'Andika Tangazo Jipya la Kanisa' : 'Draft New Church Announcement'}
            </h3>

            {/* Quick worship-reminder templates */}
            <div style={{ display: 'flex', gap: '0.4rem', flexWrap: 'wrap', marginBottom: '0.6rem' }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--text-muted)', alignSelf: 'center' }}>
                {isSw ? '⚡ Vikumbusho vya Haraka:' : '⚡ Quick reminders:'}
              </span>
              <button
                type="button"
                className="badge badge-blue"
                style={{ cursor: 'pointer' }}
                onClick={() => {
                  setTitle(isSw ? 'Kumbusha: Ibada Kuu ya Jumapili' : 'Reminder: Sunday Main Service');
                  setCategory('Ibada');
                  setContent(isSw
                    ? 'Wapendwa, kesho ni Ibada Kuu ya Sayuni saa 02:30 Asubuhi Hekalu Kuu la Mbagala Kwa Matope. Lete familia na marafiki. Ubarikiwe!'
                    : 'Beloved, tomorrow is the Sayuni Main Service at 02:30 AM at Mbagala Kwa Matope. Bring family and friends. God bless you!');
                }}
              >
                {isSw ? '🙏 Ibada ya Jumapili' : '🙏 Sunday Service'}
              </button>
              <button
                type="button"
                className="badge badge-blue"
                style={{ cursor: 'pointer' }}
                onClick={() => {
                  setTitle(isSw ? 'Kumbusha: Mkesha wa Ijumaa' : 'Reminder: Friday Night Vigil');
                  setCategory('Mkesha');
                  setContent(isSw
                    ? 'Wapendwa, Ijumaa saa 04:00 usiku ni Mkesha wa maombi Hekaluni. Tafadhali hudhuria na ulete wageni.'
                    : 'Beloved, Friday at 10:00 PM is the night vigil at church. Please attend and bring guests.');
                }}
              >
                {isSw ? '🌙 Mkesha' : '🌙 Vigil'}
              </button>
              <button
                type="button"
                className="badge badge-blue"
                style={{ cursor: 'pointer' }}
                onClick={() => {
                  setTitle(isSw ? 'Kumbusha: Jumuiya ya Nyumbani' : 'Reminder: Home Cell (Jumuiya)');
                  setCategory('Jumuiya');
                  setTargetAudience('jumuiya');
                  setContent(isSw
                    ? 'Wapendwa wa Jumuiya, wiki hii tunakutana nyumbani kwa maombi na neno. Tafadhali thibitisha mahudhurio yako.'
                    : 'Beloved Jumuiya, we meet at home this week for prayer and the Word. Please confirm your attendance.');
                }}
              >
                {isSw ? '🏠 Jumuiya' : '🏠 Jumuiya'}
              </button>
            </div>

            <form onSubmit={handleCreateNotice} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
              {feedback && (
                <div style={{
                  padding: '0.8rem 1rem',
                  borderRadius: 'var(--radius-md)',
                  background: feedback.type === 'success' ? 'rgba(34, 197, 94, 0.12)' : 'rgba(239, 68, 68, 0.12)',
                  border: `1px solid ${feedback.type === 'success' ? '#22c55e' : '#ef4444'}`,
                  color: feedback.type === 'success' ? '#15803d' : '#b91c1c',
                  fontSize: '0.85rem',
                  fontWeight: 600,
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem'
                }}>
                  {feedback.type === 'success' ? <CheckCircle2 size={16} /> : <AlertTriangle size={16} />}
                  <span>{feedback.message}</span>
                </div>
              )}

              {/* Aina ya Tangazo: Kawaida, Dharura, Msiba */}
              <div>
                <label className="form-label">{isSw ? 'Aina ya Tangazo (Type)' : 'Announcement Type'}</label>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '0.5rem', marginTop: '0.2rem' }}>
                  <button
                    type="button"
                    onClick={() => setNoticeType('normal')}
                    style={{
                      padding: '0.55rem 0.5rem',
                      borderRadius: '8px',
                      border: noticeType === 'normal' ? '2px solid #0D52CD' : '1px solid var(--border-color, #cbd5e1)',
                      background: noticeType === 'normal' ? 'rgba(13, 82, 205, 0.1)' : 'transparent',
                      color: noticeType === 'normal' ? '#0D52CD' : 'inherit',
                      fontWeight: 700,
                      fontSize: '0.8rem',
                      cursor: 'pointer'
                    }}
                  >
                    📢 {isSw ? 'Kawaida' : 'Normal'}
                  </button>
                  <button
                    type="button"
                    onClick={() => setNoticeType('urgent')}
                    style={{
                      padding: '0.55rem 0.5rem',
                      borderRadius: '8px',
                      border: noticeType === 'urgent' ? '2px solid #ea580c' : '1px solid var(--border-color, #cbd5e1)',
                      background: noticeType === 'urgent' ? 'rgba(234, 88, 12, 0.1)' : 'transparent',
                      color: noticeType === 'urgent' ? '#ea580c' : 'inherit',
                      fontWeight: 700,
                      fontSize: '0.8rem',
                      cursor: 'pointer'
                    }}
                  >
                    ⚡ {isSw ? 'Dharura' : 'Urgent'}
                  </button>
                  <button
                    type="button"
                    onClick={() => setNoticeType('bereavement')}
                    style={{
                      padding: '0.55rem 0.5rem',
                      borderRadius: '8px',
                      border: noticeType === 'bereavement' ? '2px solid #475569' : '1px solid var(--border-color, #cbd5e1)',
                      background: noticeType === 'bereavement' ? 'rgba(71, 85, 105, 0.12)' : 'transparent',
                      color: noticeType === 'bereavement' ? '#334155' : 'inherit',
                      fontWeight: 700,
                      fontSize: '0.8rem',
                      cursor: 'pointer'
                    }}
                  >
                    🕊️ {isSw ? 'Msiba / Maombolezo' : 'Bereavement'}
                  </button>
                </div>
              </div>

              <div>
                <label className="form-label">{isSw ? 'Kichwa cha Tangazo' : 'Announcement Title'} *</label>
                <input 
                  type="text" 
                  required
                  placeholder={isSw ? 'mf. Mazoezi ya Pamoja ya Kwaya au Taarifa ya Msiba' : 'e.g. Joint Choir Rehearsal'}
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="form-input"
                  disabled={isSubmitting}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label className="form-label">{isSw ? 'Kategoria ya Tangazo' : 'Category'}</label>
                  <select 
                    value={category} 
                    onChange={(e) => setCategory(e.target.value)}
                    className="form-select"
                    disabled={isSubmitting}
                  >
                    <option value="Taarifa Kuu">Taarifa Kuu</option>
                    <option value="Ibada">Ibada & Ratiba</option>
                    <option value="Vikundi vya Nyumba">Vikundi vya Nyumba (Jumuiya)</option>
                    <option value="Fedha & Michango">Fedha & Michango / Ujenzi</option>
                    <option value="Kwaya">Kwaya & Sifa</option>
                    <option value="Semina">Semina & Mafundisho</option>
                    <option value="Mkesha">Mkesha wa Maombi</option>
                  </select>
                </div>

                <div>
                  <label className="form-label">{isSw ? 'Tawi la Kanisa (Branch)' : 'Church Branch'}</label>
                  <select 
                    value={branch} 
                    onChange={(e) => setBranch(e.target.value)}
                    className="form-select"
                    disabled={isSubmitting}
                  >
                    <option value="Zote">{isSw ? 'Matawi Yote (National)' : 'All Branches'}</option>
                    <option value="Mbagala Kwa Matope">{isSw ? 'Mbagala Kwa Matope (HQ)' : 'Mbagala Kwa Matope (HQ)'}</option>
                    <option value="Kibondemaji">Mbagala Kibondemaji</option>
                    <option value="Kisemvule">Kisemvule (Pwani)</option>
                    <option value="Vikindu">Vikindu (Pwani)</option>
                    <option value="Morogoro">Morogoro Mjini</option>
                    <option value="Bukoba">Bukoba Mjini (Kagera)</option>
                    <option value="Njombe">Njombe Mjini</option>
                    <option value="Makambako">Makambako</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="form-label">{isSw ? 'Walengwa wa Tangazo (Audience)' : 'Target Audience'}</label>
                <select 
                  value={targetAudience} 
                  onChange={(e) => setTargetAudience(e.target.value as any)}
                  className="form-select"
                  disabled={isSubmitting}
                >
                  <option value="all">{isSw ? '📢 Waumini Wote (Public - Wote Wataona Kwenye App)' : 'All Members (Public)'}</option>
                  <option value="leaders">{isSw ? '🔒 Viongozi Pekee (Wachungaji, Wazee, Mashemasi)' : 'Church Leadership Only'}</option>
                  <option value="elders">{isSw ? '🔒 Wazee wa Kanisa Pekee' : 'Church Elders Only'}</option>
                  <option value="choir">{isSw ? '🎵 Wanakwaya Pekee' : 'Choir Members Only'}</option>
                  <option value="jumuiya">{isSw ? '🏠 Jumuiya Maalum (chagua jumuiya chini)' : 'Specific Jumuiya (choose below)'}</option>
                  <option value="member">{isSw ? '👤 Muumini Maalum (weka UID chini)' : 'Specific Member (enter UID below)'}</option>
                </select>
                {targetAudience === 'jumuiya' && (
                  <input
                    type="text"
                    className="form-input"
                    style={{ marginTop: '0.5rem' }}
                    placeholder={isSw ? 'Jina la Jumuiya (k.m. Mbagala Kijichi)' : 'Jumuiya name (e.g. Mbagala Kijichi)'}
                    value={targetJumuiya}
                    onChange={(e) => setTargetJumuiya(e.target.value)}
                    disabled={isSubmitting}
                  />
                )}
                {targetAudience === 'member' && (
                  <input
                    type="text"
                    className="form-input"
                    style={{ marginTop: '0.5rem' }}
                    placeholder={isSw ? 'Firebase UID ya muumini (kutoka Members)' : 'Member Firebase UID (from Members)'}
                    value={targetUid}
                    onChange={(e) => setTargetUid(e.target.value)}
                    disabled={isSubmitting}
                  />
                )}
                <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: '0.4rem', lineHeight: 1.5 }}>
                  {isSw
                    ? 'Ujumbe wa kibinafsi unaonekana kwenye app ya muumini huyo tu (wakati app iko online). Push wakati app imefungwa inahitaji FCM (production).'
                    : 'Personalized messages appear only in that member\'s app (when online). Push when the app is closed needs FCM (production).'}
                </p>
              </div>

              <div>
                <label className="form-label">{isSw ? 'Ujumbe / Maelezo ya Tangazo' : 'Announcement Content'} *</label>
                <textarea 
                  rows={4} 
                  required
                  placeholder={isSw ? 'Andika maelezo kamili ya tangazo hapa kwa utulivu na lugha ya staha...' : 'Write full announcement here...'}
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  className="form-textarea"
                  disabled={isSubmitting}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '0.5rem' }}>
                <button 
                  type="button" 
                  onClick={() => setShowNoticeModal(false)}
                  className="btn-secondary"
                  disabled={isSubmitting}
                >
                  {isSw ? 'Ghairi' : 'Cancel'}
                </button>
                <button 
                  type="submit" 
                  className="btn-primary"
                  disabled={isSubmitting}
                  style={{ opacity: isSubmitting ? 0.7 : 1, minWidth: '150px', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '0.5rem' }}
                >
                  <CheckCircle2 size={16} />
                  <span>{isSubmitting ? (isSw ? 'Inachapisha...' : 'Publishing...') : (isSw ? 'Hifadhi & Sawazisha' : 'Save & Publish')}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: OFFICIAL PRINTABLE REPORT (VISITORS / GROUPS) */}
      {activeReportModal === 'visitors' && (
        <PrintableOfficialReport
          reportType="visitors_monthly"
          title="Ripoti Rasmi ya Wageni na Ufuatiliaji wa Kichungaji"
          subtitle="Daftari Kuu la Wageni Waliofika Kanisani Sayuni Yerusalemu (Mbagala Kwa Matope)"
          visitors={visitors}
          onClose={() => setActiveReportModal(null)}
        />
      )}

      {activeReportModal === 'groups' && (
        <PrintableOfficialReport
          reportType="groups_consolidated"
          title="Ripoti Jumuishi ya Vikundi vya Huduma na Jumuiya za Nyumbani"
          subtitle="Tathmini ya Mahudhurio, Mafundisho na Sadaka za Nyumba kwa Nyumba"
          reports={reports}
          onClose={() => setActiveReportModal(null)}
        />
      )}

      {activeReportModal === 'bulletin' && (
        <PrintableOfficialReport
          reportType="weekly_bulletin"
          title="Kijarida Rasmi cha Ubaoni & Matangazo ya Kanisa"
          subtitle="Sekretarieti Kuu ya Kanisa — Hekalu la Sayuni Yerusalemu (Mbagala Kwa Matope)"
          notices={notices}
          onClose={() => setActiveReportModal(null)}
        />
      )}
    </div>
  );
};
