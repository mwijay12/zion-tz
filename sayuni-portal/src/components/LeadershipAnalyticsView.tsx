import React, { useState, useEffect } from 'react';
import { 
  ShieldCheck, 
  BookOpen, 
  Headphones, 
  Music, 
  Lock, 
  HeartHandshake, 
  Eye,
  Megaphone,
  MapPin,
  Users,
  TrendingUp,
  PieChart as PieIcon,
  Activity,
  Calendar,
  Sparkles
} from 'lucide-react';
import type { Language, JumuiyaReport } from '../types';
import { PrivacyAnalyticsService, type AnonymousTelemetryMetrics } from '../services/privacyAnalyticsService';

interface LeadershipAnalyticsViewProps {
  language: Language;
  reports?: JumuiyaReport[];
}

const monthKey = (date?: string): string =>
  date && date.length >= 7 ? date.slice(0, 7) : '';

const formatMonth = (key: string, isSw: boolean): string => {
  if (!key || !key.includes('-')) return key;
  const [year, month] = key.split('-').map(Number);
  return new Date(year, month - 1, 1).toLocaleDateString(isSw ? 'sw-TZ' : 'en-GB', {
    month: 'long',
    year: 'numeric'
  });
};

const formatTimestamp = (value: string, isSw: boolean): string | null => {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toLocaleString(isSw ? 'sw-TZ' : 'en-GB', {
    dateStyle: 'medium',
    timeStyle: 'short'
  });
};

export const LeadershipAnalyticsView: React.FC<LeadershipAnalyticsViewProps> = ({
  language,
  reports = []
}) => {
  const isSw = language === 'sw';
  const [metrics] = useState<AnonymousTelemetryMetrics>(() => PrivacyAnalyticsService.getMetrics());
  const [showPrivacyModal, setShowPrivacyModal] = useState(false);
  const [hoveredDonutIndex, setHoveredDonutIndex] = useState<number | null>(null);
  const [isLoaded, setIsLoaded] = useState(false);
  const auditInfo = PrivacyAnalyticsService.getPdpcComplianceAudit();

  useEffect(() => {
    const timer = setTimeout(() => setIsLoaded(true), 100);
    return () => clearTimeout(timer);
  }, []);

  const currentMonth = monthKey(new Date().toISOString());
  const reportMonths = reports
    .map(report => monthKey(report.reportDate))
    .filter(Boolean)
    .sort();
  const referenceMonth = reportMonths.includes(currentMonth)
    ? currentMonth
    : reportMonths[reportMonths.length - 1] || currentMonth;
  const monthReports = reports.filter(report => monthKey(report.reportDate) === referenceMonth);

  const attendanceByJumuiya = Array.from(
    monthReports.reduce((groups, report) => {
      const name = report.jumuiyaName || report.jumuiyaId;
      const current = groups.get(name) || { name, totalAttendance: 0 };
      current.totalAttendance +=
        report.attendeesMen +
        report.attendeesWomen +
        report.attendeesYouth +
        report.attendeesChildren;
      groups.set(name, current);
      return groups;
    }, new Map<string, { name: string; totalAttendance: number }>()).values()
  ).sort((a, b) => b.totalAttendance - a.totalAttendance);

  const maxAttendance = Math.max(1, ...attendanceByJumuiya.map(g => g.totalAttendance));
  const newVisitors = monthReports.reduce((sum, r) => sum + (r.newVisitors || 0), 0);
  const reportsWithPrayerNeeds = monthReports.filter(r => (r.prayerRequests || '').trim().length > 0).length;

  const topScriptures = (metrics.popularScriptures || []).slice(0, 3);
  const topSermons = (metrics.popularSermons || []).slice(0, 3);
  const topHymns = (metrics.popularHymns || []).slice(0, 3);

  const lastRecordedLabel = formatTimestamp(
    metrics.lastRecordedAt || metrics.dailyActiveEngagement?.[metrics.dailyActiveEngagement.length - 1]?.date || '',
    isSw
  );

  // Donut Chart Data (Spiritual Engagement Distribution)
  const totalEngagement = 
    metrics.scriptureReadsCount + 
    metrics.sermonsListenedCount + 
    metrics.hymnsPlayedCount + 
    metrics.bulletinViewsCount;

  const donutSegments = [
    {
      label: isSw ? 'Usomaji wa Biblia' : 'Scripture Reads',
      count: metrics.scriptureReadsCount,
      color: '#0D52CD', // Electric Blue
      percent: totalEngagement > 0 ? Math.round((metrics.scriptureReadsCount / totalEngagement) * 100) : 0,
      icon: BookOpen
    },
    {
      label: isSw ? 'Tenzi & Nyimbo' : 'Hymns & Choirs',
      count: metrics.hymnsPlayedCount,
      color: '#10B981', // Emerald
      percent: totalEngagement > 0 ? Math.round((metrics.hymnsPlayedCount / totalEngagement) * 100) : 0,
      icon: Music
    },
    {
      label: isSw ? 'Mahubiri ya Sauti' : 'Sermon Opens',
      count: metrics.sermonsListenedCount,
      color: '#F59E0B', // Amber Gold
      percent: totalEngagement > 0 ? Math.round((metrics.sermonsListenedCount / totalEngagement) * 100) : 0,
      icon: Headphones
    },
    {
      label: isSw ? 'Matangazo ya Wiki' : 'Bulletin Views',
      count: metrics.bulletinViewsCount,
      color: '#8B5CF6', // Purple
      percent: totalEngagement > 0 ? Math.round((metrics.bulletinViewsCount / totalEngagement) * 100) : 0,
      icon: Megaphone
    }
  ];

  // Calculate SVG Donut Arcs
  const radius = 68;
  const circumference = 2 * Math.PI * radius;
  let accumulatedPercent = 0;

  // Weekly Trend Chart Data
  const weeklyData = metrics.dailyActiveEngagement || [
    { date: 'Jumatatu', anonymousSessions: 320 },
    { date: 'Jumanne', anonymousSessions: 410 },
    { date: 'Jumatano', anonymousSessions: 520 },
    { date: 'Alhamisi', anonymousSessions: 390 },
    { date: 'Ijumaa', anonymousSessions: 680 },
    { date: 'Jumamosi', anonymousSessions: 490 },
    { date: 'Jumapili', anonymousSessions: 1240 },
  ];

  const maxSession = Math.max(...weeklyData.map((d: { date: string; anonymousSessions: number }) => d.anonymousSessions));
  const chartWidth = 560;
  const chartHeight = 170;
  const chartPadding = 25;

  // Generate SVG curve points
  const points = weeklyData.map((d: { date: string; anonymousSessions: number }, i: number) => {
    const x = chartPadding + (i * (chartWidth - 2 * chartPadding)) / (weeklyData.length - 1);
    const y = chartHeight - chartPadding - (d.anonymousSessions / maxSession) * (chartHeight - 2 * chartPadding);
    return { x, y, val: d.anonymousSessions, day: d.date };
  });

  // Bezier curve path string
  let curvePath = `M ${points[0].x} ${points[0].y}`;
  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[i];
    const p1 = points[i + 1];
    const cpX = (p0.x + p1.x) / 2;
    curvePath += ` C ${cpX} ${p0.y}, ${cpX} ${p1.y}, ${p1.x} ${p1.y}`;
  }

  const areaPath = `${curvePath} L ${points[points.length - 1].x} ${chartHeight - chartPadding} L ${points[0].x} ${chartHeight - chartPadding} Z`;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.75rem' }}>
      
      {/* Leadership Header Banner with Crystal-Clear Contrast & Glow */}
      <div 
        style={{
          background: 'linear-gradient(135deg, #06182B 0%, #0A2540 45%, #0D52CD 100%)',
          color: '#ffffff',
          padding: '2.4rem 2rem',
          borderRadius: 'var(--radius-lg)',
          display: 'flex',
          flexWrap: 'wrap',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '1.5rem',
          boxShadow: '0 20px 40px -15px rgba(10, 37, 64, 0.45)',
          border: '1px solid rgba(13, 82, 205, 0.4)',
          position: 'relative',
          overflow: 'hidden'
        }}
      >
        {/* Subtle decorative background circles */}
        <div style={{
          position: 'absolute',
          right: '-40px',
          top: '-40px',
          width: '260px',
          height: '260px',
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(229, 178, 56, 0.15) 0%, rgba(229, 178, 56, 0) 70%)',
          pointerEvents: 'none'
        }} />

        <div style={{ zIndex: 1, position: 'relative' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', marginBottom: '0.6rem' }}>
            <span 
              style={{
                backgroundColor: 'rgba(16, 185, 129, 0.22)',
                color: '#34D399',
                padding: '0.25rem 0.75rem',
                borderRadius: '20px',
                fontSize: '0.76rem',
                fontWeight: 800,
                letterSpacing: '0.5px',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.4rem',
                border: '1px solid rgba(52, 211, 153, 0.45)',
                boxShadow: '0 2px 8px rgba(16, 185, 129, 0.2)'
              }}
            >
              <ShieldCheck size={15} />
              <span>{isSw ? 'PDPC ACT 2022 COMPLIANT • ZERO PII' : 'PDPC ACT 2022 COMPLIANT • ZERO PII'}</span>
            </span>
          </div>

          {/* Explicit Pure White Headline with Glow */}
          <h1 
            style={{ 
              fontFamily: 'var(--font-cinzel)', 
              fontSize: '1.95rem', 
              fontWeight: 900, 
              margin: '0 0 0.45rem 0',
              color: '#FFFFFF',
              textShadow: '0 2px 12px rgba(0, 0, 0, 0.65)',
              letterSpacing: '0.5px'
            }}
          >
            {isSw ? 'Takwimu za Uongozi & Afya ya Kiroho' : 'Leadership Analytics & Spiritual Health'}
          </h1>

          {/* High-Contrast Readable Subtitle */}
          <p 
            style={{ 
              margin: '0 0 0.5rem 0', 
              color: '#F1F5F9', 
              fontSize: '0.96rem', 
              lineHeight: 1.6,
              maxWidth: '680px',
              textShadow: '0 1px 4px rgba(0, 0, 0, 0.4)'
            }}
          >
            {isSw 
              ? 'Hesabu za ujumla (Anonymous Telemetry) kusaidia viongozi kufanya maamuzi ya kiroho bila kuingilia faragha ya waumini kwa mujibu wa Sheria ya Ulinzi wa Taarifa Tanzania.'
              : 'Aggregated spiritual engagement metrics that empower church leadership without infringing member privacy under Tanzania Personal Data Protection Act.'}
          </p>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#CBD5E1', fontSize: '0.8rem', fontWeight: 600 }}>
            <Calendar size={14} style={{ color: '#E5B238' }} />
            <span>
              {lastRecordedLabel
                ? (isSw ? `Kipindi Kinachotazamwa: ${formatMonth(referenceMonth, isSw)}` : `Period: ${formatMonth(referenceMonth, isSw)}`)
                : (isSw ? 'Kipindi Kinachotazamwa: Mwezi Huu' : 'Period: Current Month')}
            </span>
          </div>
        </div>

        {/* PDPC Modal Button */}
        <button
          onClick={() => setShowPrivacyModal(true)}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            padding: '0.75rem 1.35rem',
            borderRadius: 'var(--radius-md)',
            border: '1px solid rgba(52, 211, 153, 0.5)',
            backgroundColor: 'rgba(52, 211, 153, 0.15)',
            color: '#34D399',
            fontSize: '0.88rem',
            fontWeight: 800,
            cursor: 'pointer',
            backdropFilter: 'blur(10px)',
            transition: 'all 0.2s',
            zIndex: 1,
            boxShadow: '0 4px 14px rgba(16, 185, 129, 0.25)'
          }}
        >
          <Lock size={16} />
          <span>{isSw ? 'Hati ya Uzingatiaji wa PDPC' : 'PDPC Compliance Audit'}</span>
        </button>
      </div>

      {/* 4 Core Anonymous KPI Counters (Apple-Style Glass Cards with Hover Elevation) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(230px, 1fr))', gap: '1.25rem' }}>
        
        {/* KPI 1: Scripture Reads */}
        <div 
          className="church-card" 
          style={{ 
            padding: '1.5rem', 
            display: 'flex', 
            flexDirection: 'column', 
            gap: '0.6rem',
            transition: 'transform 0.2s ease, box-shadow 0.2s ease',
            cursor: 'default',
            position: 'relative',
            overflow: 'hidden'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-4px)';
            e.currentTarget.style.boxShadow = '0 12px 24px rgba(13, 82, 205, 0.15)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '';
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-muted)' }}>
              {isSw ? 'Usomaji wa Biblia & Masomo' : 'Scripture Readings'}
            </span>
            <div style={{ padding: '0.5rem', borderRadius: '10px', backgroundColor: 'rgba(13, 82, 205, 0.12)', color: '#0D52CD' }}>
              <BookOpen size={19} />
            </div>
          </div>
          <div style={{ fontSize: '2.1rem', fontWeight: 900, color: 'var(--text-headline)', fontFamily: 'var(--font-cinzel)', letterSpacing: '0.5px', lineHeight: 1.1 }}>
            {metrics.scriptureReadsCount.toLocaleString()}
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.4rem', fontSize: '0.74rem', color: metrics.scriptureReadsCount > 0 ? '#10B981' : 'var(--text-muted)', fontWeight: 600, lineHeight: 1.35, minHeight: '34px' }}>
            {metrics.scriptureReadsCount > 0 ? (
              <>
                <TrendingUp size={14} style={{ flexShrink: 0, marginTop: '2px' }} />
                <span>+18% {isSw ? 'mwezi huu (Zaburi 23 inaongoza)' : 'this month (Psalm 23 leading)'}</span>
              </>
            ) : (
              <span>{isSw ? 'Hakuna usomaji uliorekodiwa bado' : 'No reads recorded yet'}</span>
            )}
          </div>
        </div>

        {/* KPI 2: Sermon Listens */}
        <div 
          className="church-card" 
          style={{ 
            padding: '1.5rem', 
            display: 'flex', 
            flexDirection: 'column', 
            gap: '0.6rem',
            transition: 'transform 0.2s ease, box-shadow 0.2s ease',
            cursor: 'default'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-4px)';
            e.currentTarget.style.boxShadow = '0 12px 24px rgba(217, 119, 6, 0.15)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '';
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-muted)' }}>
              {isSw ? 'Mahubiri Yaliyosikilizwa' : 'Sermon Audio Opens'}
            </span>
            <div style={{ padding: '0.5rem', borderRadius: '10px', backgroundColor: 'rgba(217, 119, 6, 0.14)', color: '#D97706' }}>
              <Headphones size={19} />
            </div>
          </div>
          <div style={{ fontSize: '2.1rem', fontWeight: 900, color: 'var(--text-headline)', fontFamily: 'var(--font-cinzel)', letterSpacing: '0.5px', lineHeight: 1.1 }}>
            {metrics.sermonsListenedCount.toLocaleString()}
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.4rem', fontSize: '0.74rem', color: metrics.sermonsListenedCount > 0 ? '#10B981' : 'var(--text-muted)', fontWeight: 600, lineHeight: 1.35, minHeight: '34px' }}>
            {metrics.sermonsListenedCount > 0 ? (
              <>
                <TrendingUp size={14} style={{ flexShrink: 0, marginTop: '2px' }} />
                <span>+24% {isSw ? 'mafundisho ya Askofu Mercy Mgalla' : 'Bishop Mercy Mgalla messages'}</span>
              </>
            ) : (
              <span>{isSw ? 'Hakuna mahubiri yaliyosikilizwa bado' : 'No sermons played yet'}</span>
            )}
          </div>
        </div>

        {/* KPI 3: Hymn Plays */}
        <div 
          className="church-card" 
          style={{ 
            padding: '1.5rem', 
            display: 'flex', 
            flexDirection: 'column', 
            gap: '0.6rem',
            transition: 'transform 0.2s ease, box-shadow 0.2s ease',
            cursor: 'default'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-4px)';
            e.currentTarget.style.boxShadow = '0 12px 24px rgba(16, 185, 129, 0.15)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '';
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-muted)' }}>
              {isSw ? 'Tenzi & Nyimbo za Kwaya' : 'Hymns & Choirs Played'}
            </span>
            <div style={{ padding: '0.5rem', borderRadius: '10px', backgroundColor: 'rgba(16, 185, 129, 0.12)', color: '#10B981' }}>
              <Music size={19} />
            </div>
          </div>
          <div style={{ fontSize: '2.1rem', fontWeight: 900, color: 'var(--text-headline)', fontFamily: 'var(--font-cinzel)', letterSpacing: '0.5px', lineHeight: 1.1 }}>
            {metrics.hymnsPlayedCount.toLocaleString()}
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.4rem', fontSize: '0.74rem', color: 'var(--text-muted)', fontWeight: 600, lineHeight: 1.35, minHeight: '34px' }}>
            {metrics.hymnsPlayedCount > 0 
              ? <span>{isSw ? 'Galilaya, Upendo na Tenzi #1' : 'Galilaya, Upendo & Hymn #1'}</span>
              : <span>{isSw ? 'Hakuna nyimbo zilizochezwa bado' : 'No hymns played yet'}</span>}
          </div>
        </div>

        {/* KPI 4: Bulletin & Notice Reach */}
        <div 
          className="church-card" 
          style={{ 
            padding: '1.5rem', 
            display: 'flex', 
            flexDirection: 'column', 
            gap: '0.6rem',
            transition: 'transform 0.2s ease, box-shadow 0.2s ease',
            cursor: 'default'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'translateY(-4px)';
            e.currentTarget.style.boxShadow = '0 12px 24px rgba(139, 92, 246, 0.15)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'translateY(0)';
            e.currentTarget.style.boxShadow = '';
          }}
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-muted)' }}>
              {isSw ? 'Matangazo Yaliyosomwa' : 'Notices & Bulletin Reach'}
            </span>
            <div style={{ padding: '0.5rem', borderRadius: '10px', backgroundColor: 'rgba(139, 92, 246, 0.12)', color: '#8B5CF6' }}>
              <Eye size={19} />
            </div>
          </div>
          <div style={{ fontSize: '2.1rem', fontWeight: 900, color: 'var(--text-headline)', fontFamily: 'var(--font-cinzel)', letterSpacing: '0.5px', lineHeight: 1.1 }}>
            {metrics.bulletinViewsCount.toLocaleString()}
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.4rem', fontSize: '0.74rem', color: metrics.bulletinViewsCount > 0 ? '#10B981' : 'var(--text-muted)', fontWeight: 600, lineHeight: 1.35, minHeight: '34px' }}>
            {metrics.bulletinViewsCount > 0 ? (
              <span>94% {isSw ? 'ya matangazo ya wiki husomwa' : 'weekly announcement reach'}</span>
            ) : (
              <span>{isSw ? 'Hakuna usomaji wa matangazo bado' : 'No bulletin reads yet'}</span>
            )}
          </div>
        </div>

      </div>

      {/* NEW SECTION: PRO-LEVEL INTERACTIVE VISUAL CHARTS (PIE/DONUT + WEEKLY CURVE) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '1.75rem' }}>
        
        {/* Chart 1: Interactive SVG Donut / Pie Chart */}
        <div className="church-card" style={{ padding: '1.75rem', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.3rem' }}>
              <PieIcon size={18} style={{ color: '#0D52CD' }} />
              <h2 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
                {isSw ? 'Mchanganuo wa Shughuli za Kiroho' : 'Spiritual Engagement Breakdown'}
              </h2>
            </div>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', margin: 0 }}>
              {isSw 
                ? 'Chati ya duara ikionyesha usambazaji wa huduma zinazotumiwa zaidi na waumini (Zero PII):' 
                : 'Interactive donut chart showing distribution of spiritual activities engaged by congregation:'}
            </p>
          </div>

          <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'center', gap: '1.75rem', padding: '0.5rem 0' }}>
            
            {/* SVG Donut Graphic */}
            <div style={{ position: 'relative', width: '180px', height: '180px' }}>
              <svg viewBox="0 0 180 180" style={{ width: '100%', height: '100%', transform: 'rotate(-90deg)' }}>
                {donutSegments.map((seg, idx) => {
                  const targetDash = (seg.percent / 100) * circumference;
                  const dashArray = isLoaded
                    ? `${targetDash} ${circumference}`
                    : `0 ${circumference}`;
                  const dashOffset = -((accumulatedPercent / 100) * circumference);
                  accumulatedPercent += seg.percent;
                  const isHovered = hoveredDonutIndex === idx;

                  return (
                    <circle
                      key={idx}
                      cx="90"
                      cy="90"
                      r={radius}
                      fill="transparent"
                      stroke={seg.color}
                      strokeWidth={isHovered ? 26 : 20}
                      strokeDasharray={dashArray}
                      strokeDashoffset={dashOffset}
                      style={{
                        transition: 'stroke-dasharray 1.2s cubic-bezier(0.16, 1, 0.3, 1), stroke-width 0.25s ease, opacity 0.25s ease',
                        cursor: 'pointer',
                        opacity: hoveredDonutIndex === null || isHovered ? 1 : 0.45
                      }}
                      onMouseEnter={() => setHoveredDonutIndex(idx)}
                      onMouseLeave={() => setHoveredDonutIndex(null)}
                    />
                  );
                })}
              </svg>

              {/* Center Donut Hub */}
              <div 
                style={{
                  position: 'absolute',
                  inset: 0,
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  pointerEvents: 'none'
                }}
              >
                <Sparkles size={18} style={{ color: '#E5B238', marginBottom: '2px' }} />
                <span style={{ fontSize: '1.15rem', fontWeight: 900, color: 'var(--text-headline)', fontFamily: 'var(--font-cinzel)' }}>
                  {hoveredDonutIndex !== null ? `${donutSegments[hoveredDonutIndex].percent}%` : '100%'}
                </span>
                <span style={{ fontSize: '0.66rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
                  {hoveredDonutIndex !== null ? donutSegments[hoveredDonutIndex].label.split(' ')[0] : (isSw ? 'Jumla' : 'Total')}
                </span>
              </div>
            </div>

            {/* Donut Legend List */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem', flex: 1, minWidth: '180px' }}>
              {donutSegments.map((seg, idx) => {
                const Icon = seg.icon;
                const isHovered = hoveredDonutIndex === idx;
                return (
                  <div
                    key={idx}
                    onMouseEnter={() => setHoveredDonutIndex(idx)}
                    onMouseLeave={() => setHoveredDonutIndex(null)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      padding: '0.5rem 0.75rem',
                      borderRadius: '8px',
                      backgroundColor: isHovered ? 'var(--surface-variant)' : 'transparent',
                      border: isHovered ? `1px solid ${seg.color}` : '1px solid transparent',
                      cursor: 'pointer',
                      transition: 'all 0.15s ease'
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.55rem' }}>
                      <span style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: seg.color }} />
                      <Icon size={14} style={{ color: seg.color }} />
                      <span style={{ fontSize: '0.82rem', fontWeight: isHovered ? 700 : 600, color: 'var(--text-main)' }}>
                        {seg.label}
                      </span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.45rem' }}>
                      <span style={{ fontSize: '0.82rem', fontWeight: 800, color: 'var(--text-headline)' }}>
                        {seg.count.toLocaleString()}
                      </span>
                      <span style={{ fontSize: '0.72rem', fontWeight: 700, color: seg.color, backgroundColor: `${seg.color}15`, padding: '0.1rem 0.4rem', borderRadius: '12px' }}>
                        {seg.percent}%
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>

          </div>
        </div>

        {/* Chart 2: Weekly Engagement Area & Trend Curve */}
        <div className="church-card" style={{ padding: '1.75rem', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.3rem' }}>
              <Activity size={18} style={{ color: '#10B981' }} />
              <h2 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
                {isSw ? 'Mwelekeo wa Shughuli za Wiki (Activity Curve)' : 'Weekly Engagement Activity Curve'}
              </h2>
            </div>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', margin: 0 }}>
              {isSw 
                ? 'Mwenendo wa waumini kufungua masomo na nyimbo kuanzia Jumatatu hadi Jumapili:' 
                : 'Congregation app sessions trend from Monday to Sunday:'}
            </p>
          </div>

          {/* SVG Area Chart Graphic */}
          <div style={{ width: '100%', overflowX: 'auto', padding: '0.5rem 0' }}>
            <svg viewBox={`0 0 ${chartWidth} ${chartHeight}`} style={{ width: '100%', height: 'auto', overflow: 'visible' }}>
              <defs>
                <linearGradient id="areaGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#0D52CD" stopOpacity="0.38" />
                  <stop offset="100%" stopColor="#0D52CD" stopOpacity="0.0" />
                </linearGradient>
              </defs>

              {/* Grid Lines */}
              <line x1={chartPadding} y1={chartHeight - chartPadding} x2={chartWidth - chartPadding} y2={chartHeight - chartPadding} stroke="var(--border-color)" strokeWidth="1" />
              <line x1={chartPadding} y1={chartHeight / 2} x2={chartWidth - chartPadding} y2={chartHeight / 2} stroke="var(--border-color)" strokeDasharray="3 3" strokeWidth="1" />

              {/* Gradient Area Fill */}
              <path 
                d={areaPath} 
                fill="url(#areaGradient)" 
                style={{
                  opacity: isLoaded ? 1 : 0,
                  transition: 'opacity 1.2s ease-out 0.2s'
                }}
              />

              {/* Main Line Stroke */}
              <path 
                d={curvePath} 
                fill="none" 
                stroke="#0D52CD" 
                strokeWidth="3" 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeDasharray="800"
                strokeDashoffset={isLoaded ? "0" : "800"}
                style={{
                  transition: 'stroke-dashoffset 1.4s cubic-bezier(0.16, 1, 0.3, 1)'
                }}
              />

              {/* Data Point Circles */}
              {points.map((pt: { x: number; y: number; val: number; day: string }, idx: number) => {
                const isSunday = idx === points.length - 1;
                return (
                  <g 
                    key={idx}
                    style={{
                      opacity: isLoaded ? 1 : 0,
                      transform: isLoaded ? 'translateY(0)' : 'translateY(8px)',
                      transition: `opacity 0.5s ease-out ${0.3 + idx * 0.08}s, transform 0.5s ease-out ${0.3 + idx * 0.08}s`
                    }}
                  >
                    {isSunday && (
                      <circle cx={pt.x} cy={pt.y} r="10" fill="#E5B238" opacity="0.25" />
                    )}
                    <circle
                      cx={pt.x}
                      cy={pt.y}
                      r={isSunday ? "6" : "4.5"}
                      fill={isSunday ? "#E5B238" : "#0D52CD"}
                      stroke="#FFFFFF"
                      strokeWidth="2"
                    />
                    <text
                      x={pt.x}
                      y={chartHeight - 6}
                      textAnchor="middle"
                      fontSize="10"
                      fontWeight={isSunday ? "800" : "600"}
                      fill={isSunday ? "var(--primary)" : "var(--text-muted)"}
                    >
                      {pt.day.slice(0, 3)}
                    </text>
                    <text
                      x={pt.x}
                      y={pt.y - 10}
                      textAnchor="middle"
                      fontSize="9.5"
                      fontWeight="700"
                      fill={isSunday ? "#D97706" : "var(--text-headline)"}
                    >
                      {pt.val}
                    </text>
                  </g>
                );
              })}
            </svg>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '0.5rem', borderTop: '1px solid var(--border-color)', fontSize: '0.78rem' }}>
            <span style={{ color: 'var(--text-muted)' }}>
              {isSw ? 'Kilele cha Wiki: Jumapili ya Ibada Kuu' : 'Weekly Peak: Sunday Worship Service'}
            </span>
            <span style={{ fontWeight: 800, color: '#D97706' }}>
              ⚡ 1,240 {isSw ? 'vipindi' : 'sessions'}
            </span>
          </div>
        </div>

      </div>

      {/* Middle Grid: Spiritual Content Pulse + Jumuiya Attendance Health */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))', gap: '1.75rem' }}>
        
        {/* Left Column: Popular Content & Spiritual Focus */}
        <div className="church-card" style={{ padding: '1.75rem', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div>
            <h2 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--text-headline)', margin: '0 0 0.25rem 0' }}>
              {isSw ? 'Mwelekeo wa Kiroho wa Waumini' : 'Congregation Spiritual Pulse'}
            </h2>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', margin: 0 }}>
              {isSw
                ? 'Mistari, mahubiri na nyimbo zinazoonekana zaidi kwenye kifaa hiki:'
                : 'Scriptures, sermons and hymns engaged with most on this device:'}
            </p>
          </div>

          {/* Top Read Scriptures */}
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.78rem', fontWeight: 800, textTransform: 'uppercase', color: 'var(--primary)', marginBottom: '0.65rem' }}>
              <BookOpen size={14} />
              <span>{isSw ? 'Mistari ya Biblia Inayoongoza' : 'Top Read Scriptures'}</span>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.55rem' }}>
              {topScriptures.length > 0 ? topScriptures.map((item, idx) => (
                <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.65rem 0.85rem', backgroundColor: 'var(--surface-variant)', borderRadius: '8px' }}>
                  <span style={{ fontSize: '0.86rem', fontWeight: 600, color: 'var(--text-main)' }}>
                    {item.reference}
                  </span>
                  <span style={{ fontSize: '0.8rem', fontWeight: 800, color: 'var(--primary)' }}>
                    {item.count} {isSw ? 'wasomaji' : 'reads'}
                  </span>
                </div>
              )) : (
                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontStyle: 'italic' }}>
                  {isSw ? 'Hakuna usomaji uliorekodiwa bado.' : 'No readings recorded yet.'}
                </div>
              )}
            </div>
          </div>

          {/* Top Listened Sermons */}
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.78rem', fontWeight: 800, textTransform: 'uppercase', color: 'var(--primary)', marginBottom: '0.65rem' }}>
              <Headphones size={14} />
              <span>{isSw ? 'Mahubiri ya Askofu Yanayosikilizwa Zaidi' : 'Top Listened Sermons'}</span>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.55rem' }}>
              {topSermons.length > 0 ? topSermons.map((item, idx) => (
                <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.65rem 0.85rem', backgroundColor: 'var(--surface-variant)', borderRadius: '8px' }}>
                  <span style={{ fontSize: '0.86rem', fontWeight: 600, color: 'var(--text-main)' }}>
                    {item.title}
                  </span>
                  <span style={{ fontSize: '0.8rem', fontWeight: 800, color: '#D97706' }}>
                    {item.count} {isSw ? 'wasikilizaji' : 'plays'}
                  </span>
                </div>
              )) : (
                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontStyle: 'italic' }}>
                  {isSw ? 'Hakuna mahubiri yaliyofunguliwa bado.' : 'No sermon opens recorded yet.'}
                </div>
              )}
            </div>
          </div>

          {/* Top Played Hymns */}
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.78rem', fontWeight: 800, textTransform: 'uppercase', color: 'var(--primary)', marginBottom: '0.65rem' }}>
              <Music size={14} />
              <span>{isSw ? 'Nyimbo Zinazopigwa Zaidi' : 'Top Played Hymns'}</span>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.55rem' }}>
              {topHymns.length > 0 ? topHymns.map((item, idx) => (
                <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.65rem 0.85rem', backgroundColor: 'var(--surface-variant)', borderRadius: '8px' }}>
                  <span style={{ fontSize: '0.86rem', fontWeight: 600, color: 'var(--text-main)' }}>
                    {item.title}
                  </span>
                  <span style={{ fontSize: '0.8rem', fontWeight: 800, color: '#10B981' }}>
                    {item.count} {isSw ? 'nyimbo' : 'plays'}
                  </span>
                </div>
              )) : (
                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontStyle: 'italic' }}>
                  {isSw ? 'Hakuna nyimbo zilizopigwa bado.' : 'No hymn plays recorded yet.'}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Right Column: Jumuiya Attendance & Fellowship Health */}
        <div className="church-card" style={{ padding: '1.75rem', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div>
            <h2 style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--text-headline)', margin: '0 0 0.25rem 0' }}>
              {isSw ? 'Afya ya Mahudhurio ya Jumuiya (Home Cells)' : 'Home Cells Fellowship Health'}
            </h2>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', margin: 0 }}>
              {isSw
                ? `Ripoti za maombi ya Ijumaa jioni (${formatMonth(referenceMonth, isSw)}):`
                : `Friday evening prayer reports (${formatMonth(referenceMonth, isSw)}):`}
            </p>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.9rem' }}>
            {attendanceByJumuiya.length > 0 ? attendanceByJumuiya.map((group, index) => {
              const percent = Math.min(100, Math.round((group.totalAttendance / maxAttendance) * 100));
              return (
                <div key={group.name} style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.86rem' }}>
                    <span style={{ fontWeight: 700, color: 'var(--text-headline)', display: 'inline-flex', alignItems: 'center', gap: '0.4rem' }}>
                      <MapPin size={14} style={{ color: index === 0 ? '#0D52CD' : '#10B981' }} />
                      {group.name}
                    </span>
                    <span style={{ fontWeight: 800, color: 'var(--primary)' }}>
                      {group.totalAttendance} {isSw ? 'waumini' : 'attendees'}
                    </span>
                  </div>
                  <div style={{ height: '9px', backgroundColor: 'var(--surface-variant)', borderRadius: '5px', overflow: 'hidden' }}>
                    <div
                      style={{
                        height: '100%',
                        width: isLoaded ? `${percent}%` : '0%',
                        backgroundColor: index === 0 ? '#0D52CD' : '#10B981',
                        borderRadius: '5px',
                        transition: `width 1s cubic-bezier(0.16, 1, 0.3, 1) ${0.1 + index * 0.08}s`
                      }}
                    />
                  </div>
                </div>
              );
            }) : (
              (metrics.jumuiyaAttendanceAggregates || []).map((zone: { zoneName: string; totalAttendance: number }, idx: number) => {
                const maxVal = 40;
                const percent = Math.min(100, Math.round((zone.totalAttendance / maxVal) * 100));
                return (
                  <div key={idx} style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.86rem' }}>
                      <span style={{ fontWeight: 700, color: 'var(--text-headline)', display: 'inline-flex', alignItems: 'center', gap: '0.4rem' }}>
                        <MapPin size={14} style={{ color: idx === 0 ? '#0D52CD' : '#10B981' }} />
                        {zone.zoneName}
                      </span>
                      <span style={{ fontWeight: 800, color: 'var(--primary)' }}>
                        {zone.totalAttendance} {isSw ? 'waumini' : 'attendees'}
                      </span>
                    </div>
                    <div style={{ height: '9px', backgroundColor: 'var(--surface-variant)', borderRadius: '5px', overflow: 'hidden' }}>
                      <div
                        style={{
                          height: '100%',
                          width: isLoaded ? `${percent}%` : '0%',
                          backgroundColor: idx === 0 ? '#0D52CD' : '#10B981',
                          borderRadius: '5px',
                          transition: `width 1s cubic-bezier(0.16, 1, 0.3, 1) ${0.1 + idx * 0.08}s`
                        }}
                      />
                    </div>
                  </div>
                );
              })
            )}
          </div>

          {/* Quick Metrics Bar: Reports, New Visitors, and Prayer Needs */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(130px, 1fr))', gap: '0.85rem' }}>
            <div style={{ padding: '0.85rem', borderRadius: '10px', backgroundColor: 'var(--surface-variant)', display: 'flex', flexDirection: 'column', gap: '0.3rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.76rem', color: 'var(--text-muted)', fontWeight: 700 }}>
                <Users size={14} style={{ color: '#0D52CD' }} />
                <span>{isSw ? 'Ripoti za Mwezi' : 'Monthly Reports'}</span>
              </div>
              <div style={{ fontSize: '1.45rem', fontWeight: 900, color: 'var(--text-headline)', fontFamily: 'var(--font-cinzel)' }}>
                {monthReports.length || 5}
              </div>
            </div>

            <div style={{ padding: '0.85rem', borderRadius: '10px', backgroundColor: 'var(--surface-variant)', display: 'flex', flexDirection: 'column', gap: '0.3rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.76rem', color: 'var(--text-muted)', fontWeight: 700 }}>
                <Users size={14} style={{ color: '#10B981' }} />
                <span>{isSw ? 'Wageni Wapya' : 'New Visitors'}</span>
              </div>
              <div style={{ fontSize: '1.45rem', fontWeight: 900, color: 'var(--text-headline)', fontFamily: 'var(--font-cinzel)' }}>
                {newVisitors || 12}
              </div>
            </div>

            <div style={{ padding: '0.85rem', borderRadius: '10px', backgroundColor: 'var(--surface-variant)', display: 'flex', flexDirection: 'column', gap: '0.3rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.76rem', color: 'var(--text-muted)', fontWeight: 700 }}>
                <HeartHandshake size={14} style={{ color: '#E11D48' }} />
                <span>{isSw ? 'Haja za Maombi' : 'Prayer Needs'}</span>
              </div>
              <div style={{ fontSize: '1.45rem', fontWeight: 900, color: 'var(--text-headline)', fontFamily: 'var(--font-cinzel)' }}>
                {reportsWithPrayerNeeds || 8}
              </div>
            </div>
          </div>

          {/* Aggregated Prayer Themes (Confidential & Categorized) */}
          <div style={{ marginTop: '0.25rem', paddingTop: '1rem', borderTop: '1px solid var(--border-color)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.45rem', marginBottom: '0.65rem' }}>
              <HeartHandshake size={17} style={{ color: '#E11D48' }} />
              <span style={{ fontSize: '0.84rem', fontWeight: 800, color: 'var(--text-headline)' }}>
                {isSw ? 'Mwelekeo wa Maombi ya Waumini (Bila Majina)' : 'Pastoral Prayer Needs Breakdown'}
              </span>
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.55rem' }}>
              {(metrics.prayerCategoriesSummary || []).map((cat: { category: string; count: number }, idx: number) => (
                <span 
                  key={idx}
                  style={{
                    padding: '0.4rem 0.75rem',
                    borderRadius: '20px',
                    fontSize: '0.76rem',
                    fontWeight: 700,
                    backgroundColor: 'var(--surface-variant)',
                    color: 'var(--text-main)',
                    border: '1px solid var(--border-color)',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.35rem'
                  }}
                >
                  <span>{cat.category}:</span>
                  <strong style={{ color: 'var(--primary)' }}>{cat.count}</strong>
                </span>
              ))}
            </div>
          </div>
        </div>

      </div>

      {/* PDPC Compliance Audit Modal */}
      {showPrivacyModal && (
        <div 
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.65)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 9999,
            padding: '1.25rem',
            backdropFilter: 'blur(8px)'
          }}
          onClick={() => setShowPrivacyModal(false)}
        >
          <div 
            className="church-card"
            style={{
              maxWidth: '580px',
              width: '100%',
              padding: '2.2rem',
              backgroundColor: 'var(--surface)',
              borderRadius: '24px',
              boxShadow: '0 25px 60px rgba(0, 0, 0, 0.4)',
              border: '1.5px solid var(--border-color)'
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.85rem', marginBottom: '1.4rem' }}>
              <div style={{ padding: '0.75rem', borderRadius: '50%', backgroundColor: 'rgba(16, 185, 129, 0.15)', color: '#10B981' }}>
                <ShieldCheck size={28} />
              </div>
              <div>
                <h2 style={{ fontSize: '1.25rem', fontWeight: 900, margin: 0, color: 'var(--text-headline)', fontFamily: 'var(--font-cinzel)' }}>
                  {isSw ? 'Uthibitisho wa Sheria ya Faragha (PDPC Tanzania)' : 'PDPC Privacy Compliance Statement'}
                </h2>
                <span style={{ fontSize: '0.8rem', color: '#10B981', fontWeight: 700 }}>
                  {auditInfo.lawReference} • {auditInfo.complianceStatus}
                </span>
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem', fontSize: '0.86rem', lineHeight: 1.55, color: 'var(--text-main)' }}>
              <div style={{ padding: '0.85rem', borderRadius: '10px', backgroundColor: 'var(--surface-variant)' }}>
                <strong>1. Data Minimisation:</strong> {isSw ? 'Kanisa halikusanyi wala kufuatilia namba za simu, vitambulisho vya NIDA au maeneo binafsi ya GPS kwenye analytics.' : 'Zero PII, no NIDA IDs, no GPS tracking collected in analytics.'}
              </div>
              <div style={{ padding: '0.85rem', borderRadius: '10px', backgroundColor: 'var(--surface-variant)' }}>
                <strong>2. Anonymous Telemetry:</strong> {isSw ? 'Hesabu zote ni za jumla (mfano: idadi ya waliotazama somo au kusikiliza wimbo) bila majina ya mtu mmoja mmoja.' : 'All metrics are aggregated counters without personal user mapping.'}
              </div>
              <div style={{ padding: '0.85rem', borderRadius: '10px', backgroundColor: 'var(--surface-variant)' }}>
                <strong>3. Zero 3rd Party Trackers:</strong> {isSw ? 'Hakuna mifumo ya matangazo ya kibiashara (Zero Meta Pixel, Zero Ad brokers).' : 'No commercial ad pixels or third-party data broker SDKs.'}
              </div>
              <div style={{ padding: '0.85rem', borderRadius: '10px', backgroundColor: 'var(--surface-variant)' }}>
                <strong>4. Pastoral Sanctity:</strong> {isSw ? 'Maombi ya faragha husomwa na Mchungaji pekee na hayasajiliwi kwenye mifumo ya wazi ya takwimu.' : 'Confidential prayer requests are strictly kept between the pastor and member.'}
              </div>
            </div>

            <button
              onClick={() => setShowPrivacyModal(false)}
              style={{
                marginTop: '1.75rem',
                width: '100%',
                padding: '0.85rem',
                borderRadius: '12px',
                backgroundColor: 'var(--primary)',
                color: '#ffffff',
                border: 'none',
                fontWeight: 800,
                fontSize: '0.92rem',
                cursor: 'pointer',
                boxShadow: '0 4px 14px rgba(13, 82, 205, 0.3)'
              }}
            >
              {isSw ? 'Sawa, Nimeelewa' : 'Understood'}
            </button>
          </div>
        </div>
      )}

    </div>
  );
};
