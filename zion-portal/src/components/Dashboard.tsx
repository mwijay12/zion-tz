import React, { useState } from 'react';
import { 
  Users, 
  Wallet, 
  Home, 
  Award, 
  Calendar, 
  Copy, 
  Check, 
  HeartHandshake, 
  Printer, 
  Music, 
  MapPin, 
  Megaphone, 
  ShieldCheck, 
  X,
  Church
} from 'lucide-react';
import type { Language, UserRole, FinancialProject, JumuiyaReport } from '../types';
import { 
  CHURCH_PROFILE, 
  CHURCH_CHOIRS, 
  SUNDAY_SCHEDULE, 
  INITIAL_BULLETIN_NOTICES 
} from '../data/mockData';

import leadershipImg from '../assets/pastoral_leadership.jpg';
import choirImg from '../assets/zion_worship_choir.jpg';
import fellowshipImg from '../assets/jumuiya_fellowship.jpg';

interface DashboardProps {
  language: Language;
  userRole: UserRole;
  setActiveTab: (tab: string) => void;
  projects: FinancialProject[];
  recentReports: JumuiyaReport[];
  totalIncome: number;
}

export const Dashboard: React.FC<DashboardProps> = ({
  language,
  setActiveTab,
  projects,
  recentReports,
  totalIncome
}) => {
  const isSw = language === 'sw';
  const [copiedTill, setCopiedTill] = useState(false);
  const [copiedBank, setCopiedBank] = useState(false);
  const [showBulletinModal, setShowBulletinModal] = useState(false);

  const mainProject = projects[0];
  const projectPercent = mainProject 
    ? Math.round((mainProject.currentAmount / mainProject.targetAmount) * 100) 
    : 0;

  const copyToClip = (text: string, type: 'till' | 'bank') => {
    navigator.clipboard.writeText(text);
    if (type === 'till') {
      setCopiedTill(true);
      setTimeout(() => setCopiedTill(false), 2000);
    } else {
      setCopiedBank(true);
      setTimeout(() => setCopiedBank(false), 2000);
    }
  };

  const handlePrint = () => {
    window.print();
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.75rem' }}>
      {/* Sanctuary Hero Banner - Sanctuary Navy & Electric Blue */}
      <div 
        className="dark-hero"
        style={{
          background: 'linear-gradient(135deg, #0A2540 0%, #082F70 55%, #0D52CD 100%)',
          color: '#ffffff',
          padding: '2.5rem 2rem',
          borderRadius: 'var(--radius-lg)',
          position: 'relative',
          overflow: 'hidden',
          boxShadow: 'var(--shadow-lg)',
          border: '1px solid rgba(13, 82, 205, 0.35)'
        }}
      >
        <div style={{
          position: 'absolute',
          right: '-20px',
          top: '-20px',
          width: '280px',
          height: '280px',
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(223, 183, 255, 0.25) 0%, rgba(223, 183, 255, 0) 70%)',
          pointerEvents: 'none'
        }} />

        <div style={{ maxWidth: '900px', position: 'relative', zIndex: 2 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem', marginBottom: '0.85rem', flexWrap: 'wrap' }}>
            <span className="badge" style={{ background: 'rgba(241, 218, 255, 0.22)', color: '#f1daff', border: '1px solid rgba(241, 218, 255, 0.45)' }}>
              <Church size={13} />
              {isSw ? 'Makao Makuu ya Ibada' : 'Sanctuary Headquarters'}
            </span>
            <span style={{ fontSize: '0.85rem', color: '#dee1ff', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
              <MapPin size={14} style={{ color: '#dfb7ff' }} />
              {CHURCH_PROFILE.location}
            </span>
          </div>

          <h2 style={{ fontSize: '2.1rem', fontWeight: 800, marginBottom: '0.6rem', lineHeight: 1.25, letterSpacing: '-0.02em', color: '#ffffff' }}>
            {isSw 
              ? 'Karibu Kanisa la Zion Fellowship' 
              : 'Welcome to Zion Fellowship Church'}
          </h2>

          <p style={{ fontSize: '1.02rem', color: '#dee1ff', fontStyle: 'italic', marginBottom: '1.35rem', lineHeight: 1.6 }}>
            {isSw 
              ? '"Kwa kuwa Bwana ameichagua Sayuni; Ameitamani akae ndani yake. Hapa ndipo patakapokuwa pumziko langu milele..." — Zaburi 132:13-14'
              : '"For the Lord hath chosen Zion; he hath desired it for his habitation. This is my rest for ever..." — Psalm 132:13-14'}
          </p>

          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.85rem', alignItems: 'center' }}>
            <div style={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: '0.5rem', 
              background: 'rgba(255, 255, 255, 0.14)', 
              padding: '0.55rem 1.15rem', 
              borderRadius: 'var(--radius-full)',
              backdropFilter: 'blur(10px)',
              fontSize: '0.88rem',
              border: '1px solid rgba(255, 255, 255, 0.25)',
              color: '#ffffff'
            }}>
              <ShieldCheck size={16} style={{ color: '#dfb7ff' }} />
              <span><strong>{CHURCH_PROFILE.headPastor}</strong> &amp; <strong>{CHURCH_PROFILE.bishopHusband}</strong></span>
            </div>

            <button
              onClick={() => setShowBulletinModal(true)}
              className="btn-primary"
              style={{ background: '#0D52CD', color: '#ffffff', border: '1px solid rgba(255, 255, 255, 0.3)', padding: '0.55rem 1.2rem', fontSize: '0.88rem' }}
            >
              <Megaphone size={16} />
              <span>{isSw ? 'Matangazo ya Wiki & Bulletin ya Ubaoni' : 'Weekly Announcements & Bulletin'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Leadership & Identity Hero Feature */}
      <div 
        className="church-card"
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: '1.5rem',
          alignItems: 'center',
          background: 'var(--bg-surface)',
          padding: '1.5rem'
        }}
      >
        <div style={{ position: 'relative', borderRadius: 'var(--radius-md)', overflow: 'hidden', maxHeight: '340px' }}>
          <img 
            src={leadershipImg} 
            alt="Mchungaji Askofu Messi Mgala na James Robert" 
            style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
          />
          <div style={{
            position: 'absolute',
            bottom: 0,
            left: 0,
            right: 0,
            background: 'linear-gradient(to top, rgba(15, 23, 42, 0.9) 0%, transparent 100%)',
            padding: '1.25rem',
            color: '#ffffff'
          }}>
            <span style={{ fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '1px', color: '#fbbf24', fontWeight: 700 }}>
              {isSw ? 'UONGOZI WA KIROHO NA UTUME' : 'SPIRITUAL & APOSTOLIC OVERSIGHT'}
            </span>
            <div style={{ fontSize: '1.15rem', fontWeight: 800 }}>
              {CHURCH_PROFILE.headPastor}
            </div>
            <div style={{ fontSize: '0.88rem', color: '#cbd5e1' }}>
              {isSw ? 'Akiwa na Mume wake:' : 'With her husband:'} <strong>{CHURCH_PROFILE.bishopHusband}</strong>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.9rem' }}>
          <span className="badge badge-purple" style={{ alignSelf: 'flex-start' }}>
            <ShieldCheck size={13} />
            {isSw ? 'Huduma ya Kichungaji na Maono' : 'Pastoral Ministry & Vision'}
          </span>
          <h3 style={{ fontSize: '1.35rem', fontWeight: 800, color: 'var(--text-headline)', lineHeight: 1.3 }}>
            {isSw ? 'Kujenga Kanisa Imara Katika Kristo & Mfumo wa Uwazi' : 'Building a Strong Church in Christ & Transparent Stewardship'}
          </h3>
          <p style={{ fontSize: '0.9rem', color: 'var(--text-muted)', lineHeight: 1.6 }}>
            {isSw 
              ? 'Chini ya uongozi wa Mchungaji Askofu Messi Mgala na Ndg. James Robert, kanisa la Zion Jerusalem lililopo Kwa Matope - Mbagala Dar es Salaam linawakaribisha katika utaratibu mzuri wa kidijitali. Tunalinda kumbukumbu za kanisa, ripoti za vikundi vya maombi majumbani, na matoleo yote ya waumini kwa uadilifu mkuu.'
              : 'Under the spiritual oversight of Bishop Messi Mgala and Mr. James Robert, Zion Jerusalem Church at Kwa Matope, Mbagala Dar es Salaam embraces modern transparency and digital record-keeping for every home prayer cell, ministry choir, and sacred offering.'}
          </p>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem', marginTop: '0.3rem' }}>
            <div style={{ padding: '0.75rem', background: 'var(--bg-app)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>{isSw ? 'Mamlaka ya Usimamizi' : 'Governance'}</div>
              <div style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--primary-800)' }}>{CHURCH_PROFILE.eldersBoard}</div>
            </div>
            <div style={{ padding: '0.75rem', background: 'var(--bg-app)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>{isSw ? 'Makatibu & Hazina' : 'Secretariat & Treasury'}</div>
              <div style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--gold-700)' }}>{CHURCH_PROFILE.churchTreasurer}</div>
            </div>
          </div>
        </div>
      </div>

      {/* KPI Cards */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
        gap: '1.25rem'
      }}>
        {/* Total Members */}
        <div className="church-card" style={{ display: 'flex', alignItems: 'center', gap: '1.15rem' }}>
          <div style={{
            width: '52px',
            height: '52px',
            borderRadius: 'var(--radius-md)',
            background: 'var(--primary-100)',
            color: 'var(--primary-700)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            <Users size={26} />
          </div>
          <div>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>
              {isSw ? 'WAUMINI WALIOORODHESHWA' : 'REGISTERED CONGREGANTS'}
            </span>
            <div style={{ fontSize: '1.65rem', fontWeight: 800, color: 'var(--text-headline)' }}>
              142
            </div>
            <span style={{ fontSize: '0.78rem', color: 'var(--emerald-600)', fontWeight: 600 }}>
              {isSw ? 'Mbagala Kwa Matope' : 'Kwa Matope Parish'}
            </span>
          </div>
        </div>

        {/* Sunday Attendance */}
        <div className="church-card" style={{ display: 'flex', alignItems: 'center', gap: '1.15rem' }}>
          <div style={{
            width: '52px',
            height: '52px',
            borderRadius: 'var(--radius-md)',
            background: 'var(--gold-100)',
            color: 'var(--gold-700)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            <Calendar size={26} />
          </div>
          <div>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>
              {isSw ? 'MAHUDHURIO YA JUMAPILI' : 'SUNDAY ATTENDANCE'}
            </span>
            <div style={{ fontSize: '1.65rem', fontWeight: 800, color: 'var(--text-headline)' }}>
              118
            </div>
            <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
              {isSw ? 'Watu wazima 92 • Watoto 26' : '92 Adults • 26 Children'}
            </span>
          </div>
        </div>

        {/* Finances Total */}
        <div className="church-card" style={{ display: 'flex', alignItems: 'center', gap: '1.15rem' }}>
          <div style={{
            width: '52px',
            height: '52px',
            borderRadius: 'var(--radius-md)',
            background: 'var(--emerald-100)',
            color: 'var(--emerald-600)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            <Wallet size={26} />
          </div>
          <div>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>
              {isSw ? 'MAPATO YA FEDHA (MWEZI)' : 'MONTH COLLECTIONS'}
            </span>
            <div style={{ fontSize: '1.65rem', fontWeight: 800, color: 'var(--text-headline)' }}>
              Tsh {totalIncome.toLocaleString()}
            </div>
            <span style={{ fontSize: '0.78rem', color: 'var(--emerald-600)', fontWeight: 600 }}>
              {isSw ? 'Mafungu, Sadaka & Miradi' : 'Tithes, Offerings & Pledges'}
            </span>
          </div>
        </div>

        {/* Active Jumuiya Cells */}
        <div className="church-card" style={{ display: 'flex', alignItems: 'center', gap: '1.15rem' }}>
          <div style={{
            width: '52px',
            height: '52px',
            borderRadius: 'var(--radius-md)',
            background: 'rgba(124, 58, 237, 0.12)',
            color: '#7c3aed',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}>
            <Home size={26} />
          </div>
          <div>
            <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>
              {isSw ? 'VIKUNDI VYA MAOMBI (NYUMBA)' : 'HOME PRAYER CELLS'}
            </span>
            <div style={{ fontSize: '1.65rem', fontWeight: 800, color: 'var(--text-headline)' }}>
              5 / 5
            </div>
            <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
              {isSw ? 'Mbagala & Majumbani' : 'All reporting regularly'}
            </span>
          </div>
        </div>
      </div>

      {/* Choir Showcase & Home Fellowship Highlights */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))',
        gap: '1.5rem'
      }}>
        {/* Choirs & Praise Ministry Showcase */}
        <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.1rem' }}>
          <div style={{ position: 'relative', borderRadius: 'var(--radius-md)', overflow: 'hidden', height: '180px' }}>
            <img 
              src={choirImg} 
              alt="Kwaya na Sifa Zion Jerusalem" 
              style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
            />
            <div style={{
              position: 'absolute',
              inset: 0,
              background: 'linear-gradient(to top, rgba(15, 23, 42, 0.85) 0%, rgba(15, 23, 42, 0.2) 60%)',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'flex-end',
              padding: '1rem',
              color: '#ffffff'
            }}>
              <span className="badge badge-gold" style={{ alignSelf: 'flex-start', marginBottom: '0.2rem' }}>
                <Music size={12} /> {isSw ? 'Huduma ya Uimbaji & Sifa' : 'Worship & Choirs'}
              </span>
              <h4 style={{ fontSize: '1.15rem', fontWeight: 700, margin: 0 }}>
                {isSw ? 'Kwaya Kuu za Sayuni Yerusalemu' : 'Zion Jerusalem Church Choirs'}
              </h4>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
            {CHURCH_CHOIRS.map((choir, idx) => (
              <div 
                key={idx}
                style={{
                  padding: '0.7rem 0.85rem',
                  borderRadius: 'var(--radius-sm)',
                  background: 'var(--bg-app)',
                  border: '1px solid var(--border-subtle)',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}
              >
                <div>
                  <div style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--primary-800)' }}>
                    {choir.name}
                  </div>
                  <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                    {choir.desc}
                  </div>
                </div>
                <span style={{ fontSize: '0.75rem', background: 'var(--bg-surface)', padding: '0.2rem 0.6rem', borderRadius: 'var(--radius-full)', border: '1px solid var(--border-subtle)' }}>
                  {choir.leader}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Home Fellowship / Prayers at Home */}
        <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.1rem' }}>
          <div style={{ position: 'relative', borderRadius: 'var(--radius-md)', overflow: 'hidden', height: '180px' }}>
            <img 
              src={fellowshipImg} 
              alt="Ibada za Vikundi vya Nyumba kwa Nyumba" 
              style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
            />
            <div style={{
              position: 'absolute',
              inset: 0,
              background: 'linear-gradient(to top, rgba(15, 23, 42, 0.85) 0%, rgba(15, 23, 42, 0.2) 60%)',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'flex-end',
              padding: '1rem',
              color: '#ffffff'
            }}>
              <span className="badge badge-blue" style={{ alignSelf: 'flex-start', marginBottom: '0.2rem' }}>
                <Home size={12} /> {isSw ? 'Ibada Majumbani (Ijumaa)' : 'Home Fellowships (Fridays)'}
              </span>
              <h4 style={{ fontSize: '1.15rem', fontWeight: 700, margin: 0 }}>
                {isSw ? 'Kukomesha Upotevu wa Ripoti za Karatasi' : 'Eliminating Paper Loss in Cell Reports'}
              </h4>
            </div>
          </div>

          <p style={{ fontSize: '0.86rem', color: 'var(--text-muted)', lineHeight: 1.5, margin: 0 }}>
            {isSw 
              ? 'Hakuna tena ripoti za kwenye vijikaratasi vilivyoraruliwa au kupotea! Viongozi wanarekodi moja kwa moja kwa simu hata bila bando, na mfumo unazalisha nakala safi ya PDF kwa ajili ya faili ngumu (hardcopy backup).'
              : 'No more crumpled paper notes torn from school notebooks that get lost! Leaders record directly on phone even offline, and the system generates clean printable PDFs for hardcopy backup.'}
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
            {recentReports.map((report) => (
              <div 
                key={report.id}
                style={{
                  padding: '0.75rem',
                  borderRadius: 'var(--radius-sm)',
                  background: 'var(--bg-app)',
                  border: '1px solid var(--border-subtle)',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}
              >
                <div>
                  <div style={{ fontWeight: 700, fontSize: '0.88rem', color: 'var(--primary-800)' }}>
                    {report.jumuiyaName}
                  </div>
                  <div style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
                    Kaya: {report.hostFamily} • Sadaka: Tsh {report.offeringAmount.toLocaleString()}
                  </div>
                </div>
                <button 
                  onClick={() => setActiveTab('jumuiya')}
                  className="btn-secondary"
                  style={{ fontSize: '0.75rem', padding: '0.3rem 0.6rem' }}
                >
                  {isSw ? 'Tazama' : 'View'}
                </button>
              </div>
            ))}
          </div>

          <button 
            onClick={() => setActiveTab('jumuiya')}
            className="btn-gold"
            style={{ width: '100%', marginTop: 'auto' }}
          >
            <HeartHandshake size={16} />
            <span>{isSw ? '+ Wasilisha Ripoti ya Kikundi' : '+ Submit Home Cell Report'}</span>
          </button>
        </div>
      </div>

      {/* Sunday Service Schedule & Announcement Bulletin Solution */}
      <div 
        className="church-card"
        style={{
          background: 'var(--bg-surface)',
          border: '1.5px solid var(--border-subtle)',
          padding: '1.5rem'
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1rem', marginBottom: '1.25rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
              <Calendar size={18} style={{ color: 'var(--primary-700)' }} />
              <h3 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
                {isSw ? 'Ratiba Rasmi ya Ibada ya Jumapili & Kipindi cha Matangazo' : 'Official Sunday Service Schedule & Bulletin'}
              </h3>
            </div>
            <p style={{ fontSize: '0.86rem', color: 'var(--text-muted)', margin: 0 }}>
              {isSw 
                ? 'Ibada fupi, yenye uwepo wa Mungu, bila matangazo marefu ya kuchosha madhabahuni.' 
                : 'Pact, spirit-filled service without long boring announcements at the pulpit.'}
            </p>
          </div>

          <button 
            onClick={() => setShowBulletinModal(true)}
            className="btn-primary"
            style={{ padding: '0.6rem 1.1rem' }}
          >
            <Printer size={16} />
            <span>{isSw ? 'Chapisha Bulletin ya Ubaoni (Print 1-Page)' : 'Print Notice Board Bulletin'}</span>
          </button>
        </div>

        {/* Timeline */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: '1rem'
        }}>
          {SUNDAY_SCHEDULE.map((item, index) => (
            <div 
              key={index}
              style={{
                padding: '1rem',
                borderRadius: 'var(--radius-sm)',
                background: index === 3 ? 'rgba(245, 158, 11, 0.08)' : 'var(--bg-app)',
                border: index === 3 ? '1.5px solid var(--gold-500)' : '1px solid var(--border-subtle)',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.4rem'
              }}
            >
              <div style={{
                fontSize: '0.78rem',
                fontWeight: 800,
                color: index === 3 ? 'var(--gold-700)' : 'var(--primary-700)',
                letterSpacing: '0.5px'
              }}>
                ⏰ {item.time}
              </div>
              <div style={{ fontWeight: 700, fontSize: '0.9rem', color: 'var(--text-headline)' }}>
                {item.title}
              </div>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', lineHeight: 1.4 }}>
                {item.desc}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Two Column Layout: Project Highlight + Giving */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))',
        gap: '1.5rem'
      }}>
        {/* Left Column: Building Project & Financial Stewardship */}
        <div className="church-card gold-border" style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <span className="badge badge-purple" style={{ marginBottom: '0.4rem', display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
                <Church size={13} />
                <span>{isSw ? 'Mradi Mkuu wa Kanisa' : 'Major Church Project'}</span>
              </span>
              <h3 style={{ fontSize: '1.2rem', fontWeight: 700, color: 'var(--text-headline)' }}>
                {isSw ? mainProject.title : mainProject.titleEn}
              </h3>
              <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginTop: '0.2rem' }}>
                {mainProject.description}
              </p>
            </div>
            <span className="badge badge-green">
              {projectPercent}% {isSw ? 'Imefikiwa' : 'Funded'}
            </span>
          </div>

          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.88rem', marginBottom: '0.4rem' }}>
              <span style={{ color: 'var(--text-muted)' }}>{isSw ? 'Zilizokusanywa:' : 'Collected:'}</span>
              <strong style={{ color: 'var(--primary-700)' }}>
                Tsh {mainProject.currentAmount.toLocaleString()}
              </strong>
            </div>
            <div className="progress-bar-container" style={{ height: '10px' }}>
              <div className="progress-bar-fill" style={{ width: `${projectPercent}%` }} />
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.78rem', marginTop: '0.35rem', color: 'var(--text-muted)' }}>
              <span>{isSw ? 'Lengo:' : 'Target:'} Tsh {mainProject.targetAmount.toLocaleString()}</span>
              <span>{isSw ? 'Mwisho:' : 'Due:'} {mainProject.targetDate}</span>
            </div>
          </div>

          {/* Giving Channels */}
          <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: '1rem', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            <div style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--text-headline)' }}>
              {isSw ? 'Njia Rasmi za Kutuma Sadaka na Michango:' : 'Official Giving & Contribution Channels:'}
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'var(--bg-surface)', padding: '0.6rem 0.8rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <div>
                <div style={{ fontWeight: 700, fontSize: '0.88rem' }}>M-PESA LIPA NUMBER (TILL)</div>
                <div style={{ fontSize: '1.1rem', color: 'var(--gold-700)', fontWeight: 800, letterSpacing: '1px' }}>
                  {CHURCH_PROFILE.paymentChannels.mpesaTill}
                </div>
                <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{CHURCH_PROFILE.paymentChannels.mpesaName}</div>
              </div>
              <button 
                onClick={() => copyToClip(CHURCH_PROFILE.paymentChannels.mpesaTill, 'till')} 
                className="btn-secondary" 
                style={{ padding: '0.4rem 0.75rem', fontSize: '0.78rem' }}
              >
                {copiedTill ? <Check size={14} style={{ color: 'var(--emerald-600)' }} /> : <Copy size={14} />}
                <span>{copiedTill ? (isSw ? 'Imenakiliwa' : 'Copied') : (isSw ? 'Nakili' : 'Copy')}</span>
              </button>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'var(--bg-surface)', padding: '0.6rem 0.8rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <div>
                <div style={{ fontWeight: 700, fontSize: '0.88rem' }}>CRDB BANK ACCOUNT</div>
                <div style={{ fontSize: '0.95rem', color: 'var(--primary-700)', fontWeight: 800, letterSpacing: '1px' }}>
                  {CHURCH_PROFILE.paymentChannels.accountNumber}
                </div>
                <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{CHURCH_PROFILE.paymentChannels.accountName}</div>
              </div>
              <button 
                onClick={() => copyToClip(CHURCH_PROFILE.paymentChannels.accountNumber, 'bank')} 
                className="btn-secondary" 
                style={{ padding: '0.4rem 0.75rem', fontSize: '0.78rem' }}
              >
                {copiedBank ? <Check size={14} style={{ color: 'var(--emerald-600)' }} /> : <Copy size={14} />}
                <span>{copiedBank ? (isSw ? 'Imenakiliwa' : 'Copied') : (isSw ? 'Nakili' : 'Copy')}</span>
              </button>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '0.75rem' }}>
            <button onClick={() => setActiveTab('finance')} className="btn-primary" style={{ flex: 1, padding: '0.6rem' }}>
              <Wallet size={16} />
              <span>{isSw ? 'Fungua Daftari la Fedha' : 'Open Financial Ledger'}</span>
            </button>
          </div>
        </div>

        {/* Right Column: Certificate Studio & Secure Backups */}
        <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
            <Award size={22} style={{ color: 'var(--gold-600)' }} />
            <div>
              <h4 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-headline)', margin: 0 }}>
                {isSw ? 'Studio ya Vyeti Rasmi vya Kanisa' : 'Official Certificate Studio'}
              </h4>
              <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                {isSw ? 'Vilivyosainiwa na Askofu Messi Mgala' : 'Endorsed by Bishop Messi Mgala'}
              </span>
            </div>
          </div>

          <p style={{ fontSize: '0.86rem', color: 'var(--text-muted)', margin: 0, lineHeight: 1.5 }}>
            {isSw 
              ? 'Tengeneza na uchapishe vyeti rasmi vya Ubatizo, Ndoa ya Kikristo, na Wakfu wa Watoto vyenye nembo rasmi ya Sayuni Yerusalemu, sahihi ya kichungaji na nambari ya uthibitisho kwa kubofya mara moja.'
              : 'Generate and print verified baptism, wedding, and dedication certificates with Zion Jerusalem emblem and unique serial verification.'}
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
            <div style={{ padding: '0.75rem', background: 'var(--bg-app)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <strong style={{ fontSize: '0.88rem' }}>Vyeti vya Ubatizo (Baptism)</strong>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>ZJ-BAP-2026-0042 • Maji Tele</div>
              </div>
              <span className="badge badge-green">{isSw ? 'Kimethibitishwa' : 'Verified'}</span>
            </div>

            <div style={{ padding: '0.75rem', background: 'var(--bg-app)', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <strong style={{ fontSize: '0.88rem' }}>Vyeti vya Wakfu wa Mtoto</strong>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>ZJ-DED-2026-0018 • Madhabahuni</div>
              </div>
              <span className="badge badge-gold">{isSw ? 'Tayari' : 'Ready'}</span>
            </div>
          </div>

          <button onClick={() => setActiveTab('certificates')} className="btn-primary" style={{ width: '100%', marginTop: 'auto' }}>
            <Award size={16} />
            <span>{isSw ? 'Fungua Studio ya Vyeti (Print PDF)' : 'Open Certificate Studio'}</span>
          </button>
        </div>
      </div>

      {/* Printable Bulletin & Notice Board Modal */}
      {showBulletinModal && (
        <div 
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0, 0, 0, 0.75)',
            zIndex: 9999,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '1.5rem',
            overflowY: 'auto'
          }}
        >
          <div 
            style={{
              background: '#ffffff',
              color: '#0f172a',
              borderRadius: 'var(--radius-lg)',
              maxWidth: '800px',
              width: '100%',
              padding: 'clamp(1rem, 3vw, 2.25rem)',
              boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
              position: 'relative'
            }}
          >
            {/* Close Button */}
            <button
              onClick={() => setShowBulletinModal(false)}
              style={{
                position: 'absolute',
                top: '1.25rem',
                right: '1.25rem',
                background: '#f1f5f9',
                border: 'none',
                borderRadius: '50%',
                width: '36px',
                height: '36px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer'
              }}
            >
              <X size={20} />
            </button>

            {/* Printable Bulletin Layout */}
            <div id="printable-church-bulletin" style={{ fontFamily: 'Georgia, serif' }}>
              {/* Header */}
              <div style={{ textAlign: 'center', borderBottom: '2px solid #1e3a8a', paddingBottom: '1rem', marginBottom: '1.25rem' }}>
                <h1 style={{ fontFamily: 'Cinzel, serif', fontSize: '1.75rem', fontWeight: 800, color: '#1e3a8a', margin: 0, letterSpacing: '1px' }}>
                  {CHURCH_PROFILE.name}
                </h1>
                <div style={{ fontSize: '1rem', fontWeight: 600, color: '#b45309', marginTop: '0.2rem' }}>
                  {CHURCH_PROFILE.nameSw} — KWA MATOPE, MBAGALA, DAR ES SALAAM
                </div>
                <div style={{ fontSize: '0.85rem', color: '#64748b', marginTop: '0.35rem' }}>
                  Mchungaji Askofu: <strong>{CHURCH_PROFILE.headPastor}</strong> • Usimamizi: <strong>{CHURCH_PROFILE.bishopHusband}</strong>
                </div>
                <div style={{ display: 'inline-block', background: '#fef3c7', color: '#92400e', padding: '0.2rem 0.8rem', borderRadius: '4px', fontSize: '0.8rem', fontWeight: 700, marginTop: '0.5rem' }}>
                  KIJARIDA RASMI CHA UBAONI & MATANGAZO YA JUMAPILI
                </div>
              </div>

              {/* Sunday Schedule */}
              <div style={{ marginBottom: '1.25rem' }}>
                <h3 style={{ fontSize: '1.05rem', color: 'var(--primary)', borderBottom: '1px solid var(--border-subtle)', paddingBottom: '0.4rem', marginBottom: '0.65rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                  <Calendar size={16} />
                  <span>RATIBA YA IBADA YA JUMAPILI</span>
                </h3>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '0.6rem', fontSize: '0.85rem' }}>
                  {SUNDAY_SCHEDULE.map((item, idx) => (
                    <div key={idx} style={{ background: 'var(--surface-container-low)', padding: '0.5rem 0.75rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
                      <strong style={{ color: 'var(--primary)' }}>{item.time}</strong>: {item.title}
                    </div>
                  ))}
                </div>
              </div>

              {/* Announcements List */}
              <div style={{ marginBottom: '1.25rem' }}>
                <h3 style={{ fontSize: '1.05rem', color: 'var(--primary)', borderBottom: '1px solid var(--border-subtle)', paddingBottom: '0.4rem', marginBottom: '0.65rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                  <Megaphone size={16} />
                  <span>MATANGAZO YA WIKI HII</span>
                </h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
                  {INITIAL_BULLETIN_NOTICES.map((notice) => (
                    <div key={notice.id} style={{ borderLeft: notice.isUrgent ? '3px solid #ba1a1a' : '3px solid var(--primary)', paddingLeft: '0.75rem' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <strong style={{ fontSize: '0.92rem', color: notice.isUrgent ? '#ba1a1a' : 'var(--on-surface)' }}>
                          {notice.title}
                        </strong>
                        <span style={{ fontSize: '0.75rem', color: 'var(--on-surface-variant)' }}>{notice.date}</span>
                      </div>
                      <p style={{ fontSize: '0.84rem', color: 'var(--on-surface-variant)', margin: '0.2rem 0 0 0' }}>
                        {notice.content}
                      </p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Weekly Financial Summary (Eliminating Long Pulpit Speeches) */}
              <div style={{ background: 'var(--surface-container-low)', padding: '1rem', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-subtle)', marginBottom: '1.25rem' }}>
                <h3 style={{ fontSize: '1rem', color: 'var(--primary)', margin: '0 0 0.5rem 0', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                  <Wallet size={16} />
                  <span>MUHTASARI WA FEDHA &amp; MATOLEO YA WIKI (UWASILISHAJI WA KAZI)</span>
                </h3>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '0.75rem', textAlign: 'center' }}>
                  <div>
                    <div style={{ fontSize: '0.75rem', color: '#64748b' }}>Mapato ya Mwezi</div>
                    <div style={{ fontSize: '1.1rem', fontWeight: 800, color: '#047857' }}>
                      Tsh {totalIncome.toLocaleString()}
                    </div>
                  </div>
                  <div>
                    <div style={{ fontSize: '0.75rem', color: '#64748b' }}>Sadaka za Vikundi (Ijumaa)</div>
                    <div style={{ fontSize: '1.1rem', fontWeight: 800, color: '#1e3a8a' }}>
                      Tsh 385,000
                    </div>
                  </div>
                  <div>
                    <div style={{ fontSize: '0.75rem', color: '#64748b' }}>Mradi wa Paa & Dari</div>
                    <div style={{ fontSize: '1.1rem', fontWeight: 800, color: '#b45309' }}>
                      Tsh 8,900,000
                    </div>
                  </div>
                </div>
                <div style={{ textAlign: 'center', fontSize: '0.78rem', color: '#64748b', marginTop: '0.6rem' }}>
                  <em>"Mungu humpenda yeye atoaye kwa moyo wa ukunjufu." — 2 Wakorintho 9:7</em>
                </div>
              </div>

              {/* Action Bar */}
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', borderTop: '1px solid #e2e8f0', paddingTop: '1rem' }}>
                <button 
                  onClick={() => setShowBulletinModal(false)}
                  style={{
                    padding: '0.6rem 1.25rem',
                    borderRadius: '6px',
                    border: '1px solid #cbd5e1',
                    background: '#ffffff',
                    cursor: 'pointer',
                    fontWeight: 600
                  }}
                >
                  Funga
                </button>
                <button 
                  onClick={handlePrint}
                  style={{
                    padding: '0.6rem 1.25rem',
                    borderRadius: '6px',
                    border: 'none',
                    background: '#1e3a8a',
                    color: '#ffffff',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                    cursor: 'pointer',
                    fontWeight: 700
                  }}
                >
                  <Printer size={16} />
                  <span>Print Bulletin (Ubao wa Kanisa)</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
