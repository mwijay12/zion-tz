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
  Database
} from 'lucide-react';
import type { Language, BulletinNotice, JumuiyaReport, JumuiyaGroup } from '../types';
import { CHURCH_PROFILE } from '../data/mockData';
import { churchSync } from '../services/churchSyncService';
import { ChurchDataBackupService } from '../services/churchDataBackupService';
import { FirebaseChurchService } from '../services/firebaseChurchService';

import { PrintableOfficialReport } from './PrintableOfficialReport';
import type { VisitorRecord } from '../types';

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
  const [activeReportModal, setActiveReportModal] = useState<'visitors' | 'groups' | null>(null);
  const [title, setTitle] = useState('');
  const [category, setCategory] = useState<any>('Taarifa Kuu');
  const [targetAudience, setTargetAudience] = useState<'all' | 'leaders' | 'elders' | 'choir'>('all');
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

  useEffect(() => {
    // 1. Live Firestore stream subscription
    const unsubscribeFirestore = FirebaseChurchService.subscribeToAnnouncements((firestoreItems) => {
      if (firestoreItems && firestoreItems.length > 0) {
        const mapped: BulletinNotice[] = firestoreItems.map(item => ({
          id: item.id || `doc-${Date.now()}`,
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
      id: `bul-${Date.now().toString().slice(-4)}`,
      title: title.trim(),
      category,
      content: content.trim(),
      date: new Date().toLocaleDateString(isSw ? 'sw-TZ' : 'en-US', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }),
      isUrgent: noticeType === 'urgent',
      type: noticeType,
      branch,
      targetAudience,
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
      }, 1400);
    } catch (err: any) {
      setFeedback({
        type: 'error',
        message: isSw
          ? `Hitilafu ya Firestore: ${err?.message || 'Kagua muunganisho wa internet au sheria za usalama (Firestore security rules).'}`
          : `Firestore error: ${err?.message || 'Check network connection or Firestore security rules.'}`
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handlePrintBulletin = () => {
    window.print();
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
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
              onClick={handlePrintBulletin}
              className="btn-secondary"
              style={{ padding: '0.6rem 1.25rem', background: 'rgba(255,255,255,0.14)', color: '#ffffff', borderColor: 'rgba(255,255,255,0.35)', backdropFilter: 'blur(8px)' }}
            >
              <Printer size={16} />
              <span>{isSw ? 'Print Kijarida' : 'Print Bulletin'}</span>
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
                <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                  {notice.date}
                </span>
              </div>

              <p style={{ fontSize: '0.88rem', color: 'var(--text-body)', margin: 0, lineHeight: 1.5 }}>
                {notice.content}
              </p>
            </div>
          ))}
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
              ? 'Thibitisha na uchapishe vyeti vya ubatizo, ndoa na wakfu vilivyosainiwa na Askofu Messi Mgala.'
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
                </select>
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
    </div>
  );
};
