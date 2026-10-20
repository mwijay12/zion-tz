import React, { useState, useEffect } from 'react';
import { 
  BookOpen, 
  Video, 
  Music, 
  FileText, 
  Upload, 
  Plus, 
  Calendar, 
  Heart, 
  CheckCircle2, 
  Tag,
  ExternalLink,
  Megaphone,
  MapPin,
  Clock,
  Mic,
  AlertTriangle,
  ShieldCheck
} from 'lucide-react';
import type { Language, SermonItem, PastoralPoster, JumuiyaReport } from '../types';
import { CHURCH_PROFILE, INITIAL_POSTERS } from '../data/mockData';
import { churchSync, type WarRoomPrayerRequest } from '../services/churchSyncService';
import leadershipImg from '../assets/pastoral_leadership.jpg';

interface PastorsPortalProps {
  language: Language;
  recentReports: JumuiyaReport[];
}

export const PastorsPortal: React.FC<PastorsPortalProps> = ({
  language,
  recentReports
}) => {
  const isSw = language === 'sw';
  const [activeSubTab, setActiveSubTab] = useState<'sermons' | 'posters' | 'prayers'>('sermons');
  
  // Sermons state synced with mobile app
  const [sermons, setSermons] = useState<SermonItem[]>(() => churchSync.getSermons());
  const [warRoomPrayers, setWarRoomPrayers] = useState<WarRoomPrayerRequest[]>(() => churchSync.getPrayers());
  const [showSermonModal, setShowSermonModal] = useState(false);
  const [sermonTitle, setSermonTitle] = useState('');
  const [preacher, setPreacher] = useState(CHURCH_PROFILE.headPastor);
  const [scripture, setScripture] = useState('');
  const [summary, setSummary] = useState('');
  const [mediaType, setMediaType] = useState<'video' | 'audio' | 'text'>('video');
  const [mediaUrl, setMediaUrl] = useState('');
  const [category, setCategory] = useState<'Imani' | 'Uponyaji' | 'Familia' | 'Uongozi' | 'Kusifu'>('Imani');

  // Posters state
  const [posters, setPosters] = useState<PastoralPoster[]>(INITIAL_POSTERS);
  const [showPosterModal, setShowPosterModal] = useState(false);
  const [posterTitle, setPosterTitle] = useState('');
  const [eventDate, setEventDate] = useState('');
  const [posterDesc, setPosterDesc] = useState('');
  const [eventLocation, setEventLocation] = useState('Kwa Matope, Mbagala');
  const [posterSpeaker, setPosterSpeaker] = useState(CHURCH_PROFILE.headPastor);

  // Synchronize with mobile app updates in real-time
  useEffect(() => {
    const unsubscribe = churchSync.subscribe((msg) => {
      if (msg.type === 'SERMON_ADDED' || msg.type === 'SERMONS_UPDATED') {
        setSermons(churchSync.getSermons());
      }
      if (msg.type === 'PRAYER_ADDED' || msg.type === 'PRAYERS_UPDATED') {
        setWarRoomPrayers(churchSync.getPrayers());
      }
    });
    return unsubscribe;
  }, []);

  // Prayer needs from Jumuiya reports
  const prayerNeeds = recentReports.filter(r => r.sickOrWelfareNeeds || r.prayerRequests);

  const handleCreateSermon = (e: React.FormEvent) => {
    e.preventDefault();
    if (!sermonTitle || !scripture) return;

    const newSermon: SermonItem = {
      id: `sermon-${Date.now()}`,
      title: sermonTitle,
      date: new Date().toISOString().split('T')[0],
      preacher,
      scripture,
      summary,
      mediaType,
      mediaUrl: mediaUrl || undefined,
      category,
      likesCount: 0
    };

    // Save to sync bridge so mobile gets it immediately
    churchSync.addSermon(newSermon);
    setSermons(churchSync.getSermons());

    setShowSermonModal(false);
    setSermonTitle('');
    setScripture('');
    setSummary('');
    setMediaUrl('');
  };

  const handleCreatePoster = (e: React.FormEvent) => {
    e.preventDefault();
    if (!posterTitle || !eventDate) return;

    const newPoster: PastoralPoster = {
      id: `poster-${Date.now()}`,
      title: posterTitle,
      eventDate,
      location: eventLocation,
      imageUrl: '/pastoral_leadership.jpg',
      description: posterDesc,
      speaker: posterSpeaker,
      status: 'active'
    };

    setPosters([newPoster, ...posters]);
    setShowPosterModal(false);
    setPosterTitle('');
    setEventDate('');
    setPosterDesc('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Pastoral Studio Hero Banner - High Contrast Royal Purple */}
      <div 
        className="dark-hero"
        style={{
          background: 'linear-gradient(135deg, #0A2540 0%, #082F70 55%, #0D52CD 100%)',
          color: '#ffffff',
          padding: '2rem',
          borderRadius: 'var(--radius-lg)',
          position: 'relative',
          overflow: 'hidden',
          boxShadow: 'var(--shadow-lg)',
          border: '1px solid rgba(13, 82, 205, 0.35)'
        }}
      >
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1.5rem', alignItems: 'center', position: 'relative', zIndex: 2 }}>
          <div style={{ width: '92px', height: '92px', borderRadius: '50%', overflow: 'hidden', border: '3px solid #c59b27', flexShrink: 0, boxShadow: '0 0 16px rgba(13, 82, 205, 0.4)' }}>
            <img 
              src={leadershipImg} 
              alt="Mchungaji Askofu Messi Mgala" 
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
            />
          </div>

          <div style={{ flex: 1, minWidth: '260px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem', marginBottom: '0.45rem', flexWrap: 'wrap' }}>
              <span className="badge" style={{ background: 'rgba(219, 234, 254, 0.22)', color: '#dbeafe', border: '1px solid rgba(219, 234, 254, 0.45)' }}>
                <ShieldCheck size={13} />
                {isSw ? 'Ofisi ya Kichungaji & Kiaskofu' : 'Pastoral & Bishopric Studio'}
              </span>
              <span style={{ fontSize: '0.8rem', color: '#dbeafe', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                <MapPin size={13} style={{ color: '#c59b27' }} />
                Kwa Matope, Mbagala • Dar es Salaam
              </span>
            </div>

            <h2 style={{ fontSize: '1.85rem', fontWeight: 800, margin: '0 0 0.4rem 0', letterSpacing: '-0.02em', color: '#ffffff' }}>
              {CHURCH_PROFILE.headPastor}
            </h2>

            <p style={{ fontSize: '0.88rem', color: '#dee1ff', margin: 0, lineHeight: 1.55 }}>
              {isSw 
                ? 'Pakia mafundisho ya Jumapili, mabango ya mikutano, na fuatilia maombi maalum ya waumini moja kwa moja kutoka kwenye simu yako au kompyuta.'
                : 'Upload Sunday teachings, publish ministry event posters, and attend to escalated member prayers directly from your mobile or PC.'}
            </p>
          </div>

          <div style={{ display: 'flex', gap: '0.65rem', flexWrap: 'wrap' }}>
            <button 
              onClick={() => setShowSermonModal(true)}
              className="btn-primary" 
              style={{ padding: '0.6rem 1.25rem', fontSize: '0.85rem', background: '#0D52CD', color: '#ffffff', border: '1px solid rgba(255,255,255,0.3)' }}
            >
              <Plus size={16} />
              <span>{isSw ? 'Pakia Somo / Mahubiri' : 'Upload Sermon'}</span>
            </button>

            <button 
              onClick={() => setShowPosterModal(true)}
              className="btn-secondary" 
              style={{ padding: '0.6rem 1.25rem', fontSize: '0.85rem', background: 'rgba(255,255,255,0.14)', color: '#ffffff', borderColor: 'rgba(255,255,255,0.35)', backdropFilter: 'blur(8px)' }}
            >
              <Upload size={16} />
              <span>{isSw ? 'Bango la Mkutano' : 'Publish Poster'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Sub-Navigation Tabs (Touch-Friendly for Mobile) */}
      <div style={{ display: 'flex', gap: '0.5rem', borderBottom: '2px solid var(--border-subtle)', paddingBottom: '0.5rem', overflowX: 'auto' }}>
        <button
          onClick={() => setActiveSubTab('sermons')}
          className={`nav-item ${activeSubTab === 'sermons' ? 'active' : ''}`}
          style={{ padding: '0.5rem 1rem', fontSize: '0.9rem', whiteSpace: 'nowrap' }}
        >
          <BookOpen size={16} />
          <span>{isSw ? `Mahubiri & Mafundisho (${sermons.length})` : `Sermons & Teachings (${sermons.length})`}</span>
        </button>

        <button
          onClick={() => setActiveSubTab('posters')}
          className={`nav-item ${activeSubTab === 'posters' ? 'active' : ''}`}
          style={{ padding: '0.5rem 1rem', fontSize: '0.9rem', whiteSpace: 'nowrap' }}
        >
          <Megaphone size={16} />
          <span>{isSw ? `Mabango ya Matukio (${posters.length})` : `Event Posters (${posters.length})`}</span>
        </button>

        <button
          onClick={() => setActiveSubTab('prayers')}
          className={`nav-item ${activeSubTab === 'prayers' ? 'active' : ''}`}
          style={{ padding: '0.5rem 1rem', fontSize: '0.9rem', whiteSpace: 'nowrap' }}
        >
          <Heart size={16} />
          <span>{isSw ? `Maombi ya Waumini (${prayerNeeds.length})` : `Escalated Prayers (${prayerNeeds.length})`}</span>
        </button>
      </div>

      {/* TAB 1: SERMONS & TEACHINGS */}
      {activeSubTab === 'sermons' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem' }}>
            <div>
              <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
                {isSw ? 'Mafundisho na Mahubiri Yaliyopakiwa' : 'Published Sermons & Biblical Teachings'}
              </h3>
              <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                {isSw ? 'Haya yanaonekana moja kwa moja kwenye simu za waumini' : 'Synchronized live to congregant mobile phones'}
              </span>
            </div>

            <button 
              onClick={() => setShowSermonModal(true)}
              className="btn-primary"
              style={{ fontSize: '0.85rem' }}
            >
              <Plus size={15} />
              <span>{isSw ? '+ Pakia Somo Jipya' : '+ New Sermon'}</span>
            </button>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '1.25rem' }}>
            {sermons.map((sermon) => (
              <div 
                key={sermon.id}
                className="church-card"
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '0.75rem',
                  border: '1px solid var(--border-subtle)'
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '0.5rem' }}>
                  <span className="badge badge-gold">
                    <Tag size={12} /> {sermon.category}
                  </span>
                  <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                    <Calendar size={13} /> {sermon.date}
                  </span>
                </div>

                <h4 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--primary-800)', margin: 0, lineHeight: 1.3 }}>
                  {sermon.title}
                </h4>

                <div style={{ fontSize: '0.85rem', color: 'var(--primary)', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                  <BookOpen size={14} />
                  <span>{sermon.scripture} • Mhubiri: {sermon.preacher}</span>
                </div>

                <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', lineHeight: 1.5, margin: 0 }}>
                  {sermon.summary}
                </p>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid var(--border-subtle)', paddingTop: '0.65rem', marginTop: 'auto' }}>
                  <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                    {sermon.mediaType === 'video' && <Video size={15} style={{ color: '#ef4444' }} />}
                    {sermon.mediaType === 'audio' && <Music size={15} style={{ color: '#059669' }} />}
                    {sermon.mediaType === 'text' && <FileText size={15} style={{ color: '#1e3a8a' }} />}
                    <span>{sermon.mediaType.toUpperCase()} Format</span>
                  </span>

                  {sermon.mediaUrl && (
                    <a 
                      href={sermon.mediaUrl} 
                      target="_blank" 
                      rel="noreferrer"
                      className="btn-secondary"
                      style={{ fontSize: '0.75rem', padding: '0.3rem 0.65rem', display: 'flex', alignItems: 'center', gap: '0.3rem' }}
                    >
                      <span>{isSw ? 'Fungua Media' : 'Open Media'}</span>
                      <ExternalLink size={12} />
                    </a>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB 2: POSTERS & EVENT BANNERS */}
      {activeSubTab === 'posters' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem' }}>
            <div>
              <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
                {isSw ? 'Mabango ya Mikutano & Semina za Kanisa' : 'Ministry Event Posters & Banners'}
              </h3>
              <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                {isSw ? 'Mabango yanayotangazwa kwa waumini kwenye simu zao' : 'Displayed on church announcement feeds'}
              </span>
            </div>

            <button 
              onClick={() => setShowPosterModal(true)}
              className="btn-gold"
              style={{ fontSize: '0.85rem' }}
            >
              <Plus size={15} />
              <span>{isSw ? '+ Tunga Bango Jipya' : '+ Create Poster'}</span>
            </button>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '1.25rem' }}>
            {posters.map((poster) => (
              <div 
                key={poster.id}
                className="church-card"
                style={{
                  padding: '1.25rem',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '0.75rem',
                  border: '1.5px solid var(--border-subtle)'
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span className="badge badge-emerald">
                    {poster.status === 'active' ? (isSw ? 'Lipo Hewani' : 'Live') : (isSw ? 'Linakuja' : 'Upcoming')}
                  </span>
                  <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.3rem' }}>
                    <MapPin size={13} /> {poster.location}
                  </span>
                </div>

                <h4 style={{ fontSize: '1.15rem', fontWeight: 700, color: 'var(--on-surface)', margin: 0 }}>
                  {poster.title}
                </h4>

                <div style={{ background: 'var(--surface-container-low)', padding: '0.65rem 0.85rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', fontSize: '0.85rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                    <Clock size={13} style={{ color: 'var(--primary)' }} />
                    <strong>{poster.eventDate}</strong>
                  </div>
                  <div style={{ color: 'var(--text-muted)', marginTop: '0.2rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                    <Mic size={13} />
                    <span>{isSw ? 'Mnenaji Mkuu:' : 'Main Speaker:'} <strong>{poster.speaker}</strong></span>
                  </div>
                </div>

                <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', margin: 0, lineHeight: 1.5 }}>
                  {poster.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB 3: WAR ROOM & CELL GROUP PRAYERS */}
      {activeSubTab === 'prayers' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          {/* Section 1: Live Mobile War Room Prayer Requests */}
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.4rem', flexWrap: 'wrap', gap: '0.5rem' }}>
              <div>
                <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <ShieldCheck size={20} style={{ color: '#c59b27' }} />
                  <span>{isSw ? 'Maombi ya Moja kwa Moja Kutoka kwa Waumini (Mobile App & War Room)' : 'Live Believer Prayer Requests (Mobile App)'}</span>
                </h3>
                <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                  {isSw ? 'Maombi yaliyowasilishwa na waumini kwenye app ya simu kwa ajili ya maombezi ya kiuchungaji' : 'Submitted by congregants on the mobile app for pastoral intercession'}
                </span>
              </div>
              <span className="badge badge-gold" style={{ fontSize: '0.72rem' }}>
                {warRoomPrayers.length} {isSw ? 'Maombi Yapo Hewani' : 'Active Prayers'}
              </span>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
              {warRoomPrayers.map((prayer) => {
                const isCritical = prayer.urgency === 'Critical';
                const isHigh = prayer.urgency === 'High';
                const pastorInterceded = prayer.pastorInterceded;

                return (
                  <div
                    key={prayer.id}
                    className="church-card"
                    style={{
                      padding: '1.1rem',
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '0.65rem',
                      borderLeft: isCritical ? '4px solid #dc2626' : isHigh ? '4px solid #ea580c' : '4px solid var(--primary)',
                      background: pastorInterceded ? 'rgba(16, 185, 129, 0.04)' : undefined
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.5rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <span 
                          style={{
                            fontSize: '0.65rem',
                            fontWeight: 800,
                            padding: '0.2rem 0.5rem',
                            borderRadius: '6px',
                            backgroundColor: isCritical ? 'rgba(220, 38, 38, 0.15)' : isHigh ? 'rgba(234, 88, 12, 0.15)' : 'rgba(13, 82, 205, 0.1)',
                            color: isCritical ? '#dc2626' : isHigh ? '#ea580c' : 'var(--primary)',
                            textTransform: 'uppercase'
                          }}
                        >
                          {isCritical ? (isSw ? 'DHARURA KUBWA' : 'CRITICAL') : isHigh ? (isSw ? 'MUHIMU' : 'HIGH') : (isSw ? 'KAWAIDA' : 'NORMAL')}
                        </span>
                        <strong style={{ fontSize: '1.02rem', color: 'var(--text-headline)' }}>
                          {prayer.title}
                        </strong>
                      </div>
                      <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                        {prayer.date}
                      </span>
                    </div>

                    <p style={{ fontSize: '0.88rem', color: 'var(--text-body)', margin: 0, lineHeight: 1.5 }}>
                      {prayer.description}
                    </p>

                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid var(--border-subtle)', paddingTop: '0.6rem', marginTop: '0.2rem', flexWrap: 'wrap', gap: '0.5rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.8rem', fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                        <span>Kutoka: <strong style={{ color: 'var(--text-headline)' }}>{prayer.author}</strong></span>
                        <span>•</span>
                        <span>🛡️ {prayer.intercessors} {isSw ? 'Waombezi Wamesimama' : 'Intercessors'}</span>
                      </div>

                      <button
                        onClick={() => churchSync.togglePastorIntercession(prayer.id)}
                        className={pastorInterceded ? 'btn-secondary' : 'btn-gold'}
                        style={{ padding: '0.35rem 0.9rem', fontSize: '0.78rem' }}
                      >
                        <CheckCircle2 size={14} style={{ color: pastorInterceded ? '#10b981' : undefined }} />
                        <span>{pastorInterceded ? (isSw ? '✓ Mchungaji Ameombea' : '✓ Prayed by Pastor') : (isSw ? 'Simama Kwenye Pengo (Ombea)' : 'Stand in the Gap')}</span>
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Section 2: Prayer Needs from Home Cells */}
          <div style={{ marginTop: '0.5rem' }}>
            <div style={{ marginBottom: '0.4rem' }}>
              <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
                {isSw ? 'Maombi na Mahitaji ya Wagonjwa Kutoka Majumbani' : 'Urgent Prayer Needs from Home Cells'}
              </h3>
              <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
                {isSw ? 'Yaliyotumwa moja kwa moja na viongozi wa jumuiya za Kwa Matope na Mbagala' : 'Submitted directly by cell group leaders for pastoral intercession'}
              </span>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
              {prayerNeeds.map((rep) => (
                <div 
                  key={rep.id}
                  className="church-card"
                  style={{
                    padding: '1.1rem',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '0.6rem',
                    borderLeft: rep.sickOrWelfareNeeds ? '4px solid #ba1a1a' : '4px solid var(--primary)'
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.5rem' }}>
                    <div>
                      <strong style={{ fontSize: '1rem', color: 'var(--on-surface)' }}>
                        {rep.jumuiyaName}
                      </strong>
                      <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginLeft: '0.5rem' }}>
                        (Kaya: {rep.hostFamily})
                      </span>
                    </div>
                    <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                      {rep.reportDate}
                    </span>
                  </div>

                  {rep.sickOrWelfareNeeds && (
                    <div style={{ background: 'var(--error-container)', color: 'var(--on-error-container)', padding: '0.6rem 0.8rem', borderRadius: '6px', fontSize: '0.85rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                      <AlertTriangle size={15} style={{ color: 'var(--error)', flexShrink: 0 }} />
                      <div>
                        <strong>{isSw ? 'Taarifa ya Ugonjwa:' : 'Sickness Alert:'}</strong> {rep.sickOrWelfareNeeds}
                      </div>
                    </div>
                  )}

                  {rep.prayerRequests && (
                    <div style={{ fontSize: '0.86rem', color: 'var(--text-body)', display: 'flex', alignItems: 'flex-start', gap: '0.4rem' }}>
                      <Heart size={15} style={{ color: 'var(--primary)', marginTop: '2px', flexShrink: 0 }} />
                      <div>
                        <strong>{isSw ? 'Dua ya Maombi:' : 'Prayer Request:'}</strong> "{rep.prayerRequests}"
                      </div>
                    </div>
                  )}

                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', borderTop: '1px solid var(--border-subtle)', paddingTop: '0.4rem', marginTop: '0.2rem' }}>
                    {isSw ? 'Imeripotiwa na Kiongozi:' : 'Reported by leader:'} <strong>{rep.submittedBy}</strong>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* MODAL: UPLOAD SERMON */}
      {showSermonModal && (
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
          <div className="church-card" style={{ maxWidth: '580px', width: '100%', maxHeight: '92vh', overflowY: 'auto' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '0.3rem', color: 'var(--text-headline)' }}>
              {isSw ? 'Pakia Somo / Mahubiri ya Kichungaji' : 'Upload Sermon or Biblical Teaching'}
            </h3>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginBottom: '1rem' }}>
              {isSw ? 'Mafundisho haya yataonekana mara moja kwenye simu za waumini.' : 'This sermon will be available immediately to congregants.'}
            </p>

            <form onSubmit={handleCreateSermon} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
              <div>
                <label className="form-label">{isSw ? 'Kichwa cha Somo (Title)' : 'Sermon Title'} *</label>
                <input 
                  type="text" 
                  required
                  placeholder={isSw ? 'mf. Ushindi Kupitia Neno' : 'e.g. Victorious Living'}
                  value={sermonTitle}
                  onChange={(e) => setSermonTitle(e.target.value)}
                  className="form-input"
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label className="form-label">{isSw ? 'Mhubiri (Preacher)' : 'Preacher'}</label>
                  <input 
                    type="text" 
                    value={preacher}
                    onChange={(e) => setPreacher(e.target.value)}
                    className="form-input"
                  />
                </div>
                <div>
                  <label className="form-label">{isSw ? 'Mstari wa Biblia' : 'Scripture Verse'} *</label>
                  <input 
                    type="text" 
                    required
                    placeholder="mf. Yohana 14:1-6"
                    value={scripture}
                    onChange={(e) => setScripture(e.target.value)}
                    className="form-input"
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label className="form-label">{isSw ? 'Aina ya Maudhui' : 'Media Format'}</label>
                  <select 
                    value={mediaType} 
                    onChange={(e) => setMediaType(e.target.value as any)}
                    className="form-select"
                  >
                    <option value="video">Video (YouTube / MP4)</option>
                    <option value="audio">Audio (Sauti / Podcast)</option>
                    <option value="text">Maandishi (Text Study)</option>
                  </select>
                </div>
                <div>
                  <label className="form-label">{isSw ? 'Kundi la Somo' : 'Category'}</label>
                  <select 
                    value={category} 
                    onChange={(e) => setCategory(e.target.value as any)}
                    className="form-select"
                  >
                    <option value="Imani">Imani</option>
                    <option value="Uponyaji">Uponyaji</option>
                    <option value="Familia">Familia</option>
                    <option value="Uongozi">Uongozi</option>
                    <option value="Kusifu">Kusifu</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="form-label">{isSw ? 'Kiunganishi cha Media (Link ya YouTube au Audio)' : 'Media URL'}</label>
                <input 
                  type="url" 
                  placeholder="https://..."
                  value={mediaUrl}
                  onChange={(e) => setMediaUrl(e.target.value)}
                  className="form-input"
                />
              </div>

              <div>
                <label className="form-label">{isSw ? 'Muhtasari wa Mafundisho & Vidokezo' : 'Teaching Summary & Key Notes'} *</label>
                <textarea 
                  rows={3} 
                  required
                  placeholder={isSw ? 'Andika vidokezo vikuu vya somo kwa ajili ya waumini...' : 'Write sermon outline and key lessons...'}
                  value={summary}
                  onChange={(e) => setSummary(e.target.value)}
                  className="form-textarea"
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '0.5rem' }}>
                <button 
                  type="button" 
                  onClick={() => setShowSermonModal(false)}
                  className="btn-secondary"
                >
                  {isSw ? 'Ghairi' : 'Cancel'}
                </button>
                <button type="submit" className="btn-primary">
                  <CheckCircle2 size={16} />
                  <span>{isSw ? 'Hifadhi & Chapisha Somo' : 'Save & Publish'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: UPLOAD POSTER */}
      {showPosterModal && (
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
          <div className="church-card" style={{ maxWidth: '560px', width: '100%', maxHeight: '92vh', overflowY: 'auto' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '0.3rem', color: 'var(--text-headline)' }}>
              {isSw ? 'Tunga Bango la Tukio la Kanisa' : 'Create Church Event Poster'}
            </h3>

            <form onSubmit={handleCreatePoster} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
              <div>
                <label className="form-label">{isSw ? 'Kichwa cha Tukio / Bango' : 'Event Title'} *</label>
                <input 
                  type="text" 
                  required
                  placeholder={isSw ? 'mf. Mkesha wa Baraka na Uponyaji' : 'e.g. Night of Healing'}
                  value={posterTitle}
                  onChange={(e) => setPosterTitle(e.target.value)}
                  className="form-input"
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label className="form-label">{isSw ? 'Tarehe & Saa' : 'Date & Time'} *</label>
                  <input 
                    type="text" 
                    required
                    placeholder="mf. Ijumaa 25 Sept, Saa 3 Usiku"
                    value={eventDate}
                    onChange={(e) => setEventDate(e.target.value)}
                    className="form-input"
                  />
                </div>
                <div>
                  <label className="form-label">{isSw ? 'Mnenaji / Mhubiri' : 'Speaker'}</label>
                  <input 
                    type="text" 
                    value={posterSpeaker}
                    onChange={(e) => setPosterSpeaker(e.target.value)}
                    className="form-input"
                  />
                </div>
              </div>

              <div>
                <label className="form-label">{isSw ? 'Mahali pa Tukio' : 'Location'}</label>
                <input 
                  type="text" 
                  value={eventLocation}
                  onChange={(e) => setEventLocation(e.target.value)}
                  className="form-input"
                />
              </div>

              <div>
                <label className="form-label">{isSw ? 'Maelezo ya Tukio' : 'Description'} *</label>
                <textarea 
                  rows={3} 
                  required
                  placeholder={isSw ? 'Eleza kuhusu tukio hili kwa waumini...' : 'Describe the event for the congregation...'}
                  value={posterDesc}
                  onChange={(e) => setPosterDesc(e.target.value)}
                  className="form-textarea"
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '0.5rem' }}>
                <button 
                  type="button" 
                  onClick={() => setShowPosterModal(false)}
                  className="btn-secondary"
                >
                  {isSw ? 'Ghairi' : 'Cancel'}
                </button>
                <button type="submit" className="btn-gold">
                  <CheckCircle2 size={16} />
                  <span>{isSw ? 'Chapisha Bango' : 'Publish Poster'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
