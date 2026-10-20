import React, { useState } from 'react';
import { 
  Users, 
  Plus, 
  Clock, 
  MapPin, 
  Phone,
  Printer,
  Calendar,
  BookOpen,
  Heart,
  AlertTriangle
} from 'lucide-react';
import type { Language, UserRole, JumuiyaGroup, JumuiyaReport, FinancialRecord } from '../types';

interface JumuiyaModuleProps {
  language: Language;
  userRole: UserRole;
  groups: JumuiyaGroup[];
  reports: JumuiyaReport[];
  setReports: React.Dispatch<React.SetStateAction<JumuiyaReport[]>>;
  setFinances: React.Dispatch<React.SetStateAction<FinancialRecord[]>>;
}

export const JumuiyaModule: React.FC<JumuiyaModuleProps> = ({
  language,
  groups,
  reports,
  setReports,
  setFinances
}) => {
  const isSw = language === 'sw';
  const [showNewReportModal, setShowNewReportModal] = useState(false);
  const [selectedGroupFilter, setSelectedGroupFilter] = useState<string>('all');

  // Form states
  const [selectedJumuiyaId, setSelectedJumuiyaId] = useState<string>(groups[0]?.id || 'jum-1');
  const [reportDate, setReportDate] = useState<string>(new Date().toISOString().split('T')[0]);
  const [hostFamily, setHostFamily] = useState<string>('');
  const [menCount, setMenCount] = useState<number>(0);
  const [womenCount, setWomenCount] = useState<number>(0);
  const [youthCount, setYouthCount] = useState<number>(0);
  const [childrenCount, setChildrenCount] = useState<number>(0);
  const [visitorsCount, setVisitorsCount] = useState<number>(0);
  const [topic, setTopic] = useState<string>('');
  const [offering, setOffering] = useState<string>('');
  const [prayers, setPrayers] = useState<string>('');
  const [welfareAlert, setWelfareAlert] = useState<string>('');
  const [leaderName, setLeaderName] = useState<string>('');

  const totalWeeklyAttendees = reports.reduce((acc, r) => acc + r.attendeesMen + r.attendeesWomen + r.attendeesYouth + r.attendeesChildren, 0);
  const totalWeeklyOfferings = reports.reduce((acc, r) => acc + r.offeringAmount, 0);

  const handleSubmitReport = (e: React.FormEvent) => {
    e.preventDefault();
    const grp = groups.find(g => g.id === selectedJumuiyaId);
    const jumName = grp ? grp.name : 'Jumuiya';

    const newRep: JumuiyaReport = {
      id: `rep-${Date.now().toString().slice(-4)}`,
      jumuiyaId: selectedJumuiyaId,
      jumuiyaName: jumName,
      reportDate: reportDate,
      hostFamily: hostFamily || (isSw ? 'Kaya ya Mshirika' : 'Host Member Family'),
      attendeesMen: Number(menCount),
      attendeesWomen: Number(womenCount),
      attendeesYouth: Number(youthCount),
      attendeesChildren: Number(childrenCount),
      newVisitors: Number(visitorsCount),
      scriptureTopic: topic,
      offeringAmount: Number(offering) || 0,
      prayerRequests: prayers,
      sickOrWelfareNeeds: welfareAlert,
      submittedBy: leaderName || grp?.leaderName || 'Kiongozi wa Jumuiya',
      submittedAt: new Date().toLocaleString()
    };

    setReports([newRep, ...reports]);

    // Automatically record offering in finances
    if (Number(offering) > 0) {
      const finEntry: FinancialRecord = {
        id: `fin-jum-${Date.now().toString().slice(-4)}`,
        date: reportDate,
        type: 'jumuiya',
        category: `Sadaka ya ${jumName}`,
        amount: Number(offering),
        paymentMethod: 'M-Pesa',
        donorName: jumName,
        notes: `Makusanyo ya maombi ya nyumba kwa nyumba - Mwenyeji: ${hostFamily}`
      };
      setFinances(prev => [finEntry, ...prev]);
    }

    // Reset Form
    setHostFamily('');
    setMenCount(0);
    setWomenCount(0);
    setYouthCount(0);
    setChildrenCount(0);
    setVisitorsCount(0);
    setTopic('');
    setOffering('');
    setPrayers('');
    setWelfareAlert('');
    setShowNewReportModal(false);
  };

  const filteredReports = selectedGroupFilter === 'all' 
    ? reports 
    : reports.filter(r => r.jumuiyaId === selectedGroupFilter);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Title & Action Bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <span className="badge badge-purple" style={{ marginBottom: '0.35rem', display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
            <Users size={13} />
            <span>{isSw ? 'Ushirika wa Nyumba kwa Nyumba' : 'Home Cell Fellowships'}</span>
          </span>
          <h2 style={{ fontFamily: 'var(--font-cinzel)', fontSize: '1.65rem', fontWeight: 800, color: 'var(--text-headline)' }}>
            {isSw ? 'Jumuiya za Maombi na Ripoti' : 'Home-to-Home Prayer Cells'}
          </h2>
        </div>

        <button 
          onClick={() => setShowNewReportModal(true)} 
          className="btn-gold"
          style={{ fontSize: '0.88rem' }}
        >
          <Plus size={16} />
          <span>{isSw ? 'Wasilisha Ripoti ya Wiki' : 'Submit Weekly Report'}</span>
        </button>
      </div>

      {/* Summary KPI Cards */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
        gap: '1.15rem'
      }}>
        <div className="church-card">
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>
            {isSw ? 'VIKUNDI VYA JUMUIYA' : 'ACTIVE CELL GROUPS'}
          </span>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--primary-700)', marginTop: '0.35rem' }}>
            {groups.length} {isSw ? 'Jumuiya' : 'Cells'}
          </div>
          <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
            {isSw ? 'Kijitonyama, Sinza, Ubungo, Mbezi' : 'City-wide geographic zones'}
          </span>
        </div>

        <div className="church-card">
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>
            {isSw ? 'WALIOHUDHURIA MAOMBI' : 'WEEKLY PRAYER ATTENDEES'}
          </span>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--emerald-600)', marginTop: '0.35rem' }}>
            {totalWeeklyAttendees} {isSw ? 'Washirika' : 'Members'}
          </div>
          <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
            {isSw ? 'Kwenye kaya za waumini' : 'Across all host homes'}
          </span>
        </div>

        <div className="church-card">
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>
            {isSw ? 'SADAKA ZA JUMUIYA' : 'CELL GROUP OFFERINGS'}
          </span>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--gold-600)', marginTop: '0.35rem' }}>
            Tsh {totalWeeklyOfferings.toLocaleString()}
          </div>
          <span style={{ fontSize: '0.78rem', color: 'var(--emerald-600)', fontWeight: 600 }}>
            {isSw ? 'Imeingizwa moja kwa moja' : 'Directly added to ledger'}
          </span>
        </div>
      </div>

      {/* 4 Jumuiya Groups Cards */}
      <div>
        <h3 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '0.85rem', color: 'var(--text-headline)' }}>
          {isSw ? 'Orodha ya Jumuiya na Viongozi Wake' : 'Cell Groups & Overseer Leaders'}
        </h3>
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(270px, 1fr))',
          gap: '1.15rem'
        }}>
          {groups.map((grp) => (
            <div key={grp.id} className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <strong style={{ fontSize: '1.05rem', color: 'var(--primary-800)' }}>
                  {grp.name}
                </strong>
                <span className="badge badge-blue">
                  {grp.memberCount} {isSw ? 'Washirika' : 'Members'}
                </span>
              </div>

              <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                <MapPin size={14} style={{ color: 'var(--gold-600)' }} />
                <span>{grp.location}</span>
              </div>

              <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                <Users size={14} style={{ color: 'var(--primary-600)' }} />
                <span><strong>{isSw ? 'Kiongozi:' : 'Leader:'}</strong> {grp.leaderName}</span>
              </div>

              <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                <Clock size={14} style={{ color: 'var(--emerald-600)' }} />
                <span>{grp.meetingDay}</span>
              </div>

              <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                <Phone size={14} />
                <span>{grp.leaderPhone}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Pastoral Oversight Reports Feed */}
      <div className="church-card" style={{ marginTop: '0.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem', marginBottom: '1.25rem' }}>
          <div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 700, color: 'var(--text-headline)' }}>
              {isSw ? 'Mlisho wa Ripoti za Kila Wiki (Pastoral Feed)' : 'Weekly Submitted Reports Feed'}
            </h3>
            <p style={{ fontSize: '0.83rem', color: 'var(--text-muted)' }}>
              {isSw ? 'Taarifa zinazotumwa na viongozi wa jumuiya kwa ajili ya Mchungaji' : 'Consolidated reports submitted by cell leaders for pastoral oversight'}
            </p>
          </div>

          {/* Filter */}
          <select 
            value={selectedGroupFilter} 
            onChange={(e) => setSelectedGroupFilter(e.target.value)}
            className="form-select"
            style={{ width: 'auto', padding: '0.4rem 0.8rem', fontSize: '0.85rem' }}
          >
            <option value="all">{isSw ? 'Jumuiya Zote' : 'All Cell Groups'}</option>
            {groups.map(g => (
              <option key={g.id} value={g.id}>{g.name}</option>
            ))}
          </select>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          {filteredReports.map((report) => {
            const total = report.attendeesMen + report.attendeesWomen + report.attendeesYouth + report.attendeesChildren;
            return (
              <div 
                key={report.id} 
                style={{
                  background: 'var(--bg-app)',
                  border: '1.5px solid var(--border-subtle)',
                  borderRadius: 'var(--radius-md)',
                  padding: '1.25rem',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '0.75rem'
                }}
              >
                {/* Header of Report */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '0.5rem' }}>
                  <div>
                    <h4 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--on-surface)' }}>
                      {report.jumuiyaName}
                    </h4>
                    <div style={{ fontSize: '0.82rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.35rem', flexWrap: 'wrap' }}>
                      <span style={{ display: 'flex', alignItems: 'center', gap: '0.2rem' }}>
                        <MapPin size={13} />
                        <span>{isSw ? 'Mwenyeji:' : 'Host Family:'} <strong>{report.hostFamily}</strong></span>
                      </span>
                      <span>•</span>
                      <span style={{ display: 'flex', alignItems: 'center', gap: '0.2rem' }}>
                        <Calendar size={13} />
                        <span>{report.reportDate}</span>
                      </span>
                    </div>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span className="badge badge-emerald">
                      Sadaka: Tsh {report.offeringAmount.toLocaleString()}
                    </span>
                    <span className="badge badge-purple">
                      Waliohudhuria: {total}
                    </span>
                  </div>
                </div>

                {/* Attendance Demographics breakdown */}
                <div style={{
                  display: 'flex',
                  flexWrap: 'wrap',
                  gap: '0.65rem',
                  background: 'var(--surface-container-low)',
                  padding: '0.6rem 0.85rem',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: '0.82rem',
                  border: '1px solid var(--border-subtle)'
                }}>
                  <span>Wanaume: <strong>{report.attendeesMen}</strong></span>
                  <span>•</span>
                  <span>Wanawake: <strong>{report.attendeesWomen}</strong></span>
                  <span>•</span>
                  <span>Vijana: <strong>{report.attendeesYouth}</strong></span>
                  <span>•</span>
                  <span>Watoto: <strong>{report.attendeesChildren}</strong></span>
                  {report.newVisitors > 0 && (
                    <>
                      <span>•</span>
                      <span style={{ color: 'var(--emerald)', fontWeight: 700 }}>
                        Wageni Wapya: {report.newVisitors}
                      </span>
                    </>
                  )}
                </div>

                {/* Scripture Topic */}
                {report.scriptureTopic && (
                  <div style={{ fontSize: '0.88rem', color: 'var(--text-headline)', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                    <BookOpen size={14} style={{ color: 'var(--primary)' }} />
                    <span><strong>{isSw ? 'Somo Lililofundishwa:' : 'Scripture / Topic:'}</strong> {report.scriptureTopic}</span>
                  </div>
                )}

                {/* Urgent Sick / Welfare Alert */}
                {report.sickOrWelfareNeeds && (
                  <div style={{
                    background: 'var(--error-container)',
                    color: 'var(--on-error-container)',
                    borderLeft: '4px solid var(--error)',
                    padding: '0.65rem 0.85rem',
                    borderRadius: '0 6px 6px 0',
                    fontSize: '0.85rem',
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '0.5rem'
                  }}>
                    <AlertTriangle size={18} style={{ color: 'var(--error)', flexShrink: 0, marginTop: '2px' }} />
                    <div>
                      <strong style={{ color: 'var(--error)' }}>
                        {isSw ? 'Taarifa ya Ustawi / Wagonjwa (Haja ya Kichungaji):' : 'Welfare & Sick Care Alert:'}
                      </strong>
                      <div style={{ marginTop: '0.2rem' }}>
                        {report.sickOrWelfareNeeds}
                      </div>
                    </div>
                  </div>
                )}

                {/* Prayer Requests */}
                {report.prayerRequests && (
                  <div style={{ fontSize: '0.85rem', color: 'var(--text-body)', background: 'var(--surface-container-low)', padding: '0.65rem 0.85rem', borderRadius: 'var(--radius-sm)', display: 'flex', alignItems: 'flex-start', gap: '0.35rem' }}>
                    <Heart size={14} style={{ color: 'var(--primary)', marginTop: '2px', flexShrink: 0 }} />
                    <div>
                      <strong>{isSw ? 'Maombi Maalum ya Washirika:' : 'Member Prayer Requests:'}</strong> "{report.prayerRequests}"
                    </div>
                  </div>
                )}

                {/* Footer info & Printable Stationery Copy */}
                <div style={{ 
                  fontSize: '0.78rem', 
                  color: 'var(--text-muted)', 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center', 
                  borderTop: '1px solid var(--border-subtle)', 
                  paddingTop: '0.6rem',
                  flexWrap: 'wrap',
                  gap: '0.5rem'
                }}>
                  <span>{isSw ? 'Imewasilishwa na:' : 'Submitted by:'} <strong>{report.submittedBy}</strong> • {report.submittedAt}</span>
                  
                  <button
                    onClick={() => window.print()}
                    className="btn-secondary"
                    style={{ fontSize: '0.75rem', padding: '0.25rem 0.65rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}
                    title={isSw ? 'Print kwa ajili ya faili ngumu (Stationery Backup)' : 'Print for hardcopy filing'}
                  >
                    <Printer size={13} />
                    <span>{isSw ? 'Print Nakala ya Faili (Backup)' : 'Print File Copy'}</span>
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Modal: New Weekly Cell Report */}
      {showNewReportModal && (
        <div style={{
          position: 'fixed',
          top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0, 0, 0, 0.7)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100,
          padding: '1rem'
        }}>
          <div className="church-card" style={{ maxWidth: '600px', width: '100%', maxHeight: '92vh', overflowY: 'auto' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '0.35rem', color: 'var(--text-headline)' }}>
              {isSw ? 'Wasilisha Ripoti ya Jumuiya ya Nyumba kwa Nyumba' : 'Submit Home Cell Group Report'}
            </h3>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginBottom: '1.25rem' }}>
              {isSw ? 'Jaza taarifa za mkutano wa maombi ya wiki hii ili kuwasilishwa kwa Mchungaji' : 'Fill weekly prayer cell numbers, scripture topic, offerings and pastoral welfare alerts'}
            </p>

            <form onSubmit={handleSubmitReport}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div className="form-group">
                  <label className="form-label">{isSw ? 'Chagua Jumuiya' : 'Cell Group'}</label>
                  <select 
                    className="form-select"
                    value={selectedJumuiyaId}
                    onChange={(e) => setSelectedJumuiyaId(e.target.value)}
                  >
                    {groups.map(g => (
                      <option key={g.id} value={g.id}>{g.name}</option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">{isSw ? 'Tarehe ya Mkutano' : 'Meeting Date'}</label>
                  <input 
                    type="date" 
                    className="form-input"
                    value={reportDate}
                    onChange={(e) => setReportDate(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">{isSw ? 'Kaya ya Mwenyeji (Host Home)' : 'Host Home Family'}</label>
                <input 
                  type="text" 
                  className="form-input"
                  placeholder={isSw ? 'Mfano: Kaya ya Mzee Mollel' : 'e.g. Mollel Family Residence'}
                  value={hostFamily}
                  onChange={(e) => setHostFamily(e.target.value)}
                  required
                />
              </div>

              {/* Attendance Breakdown Grid */}
              <div style={{ background: 'var(--surface-container-low)', padding: '0.85rem', borderRadius: 'var(--radius-sm)', marginBottom: '1.15rem', border: '1px solid var(--border-subtle)' }}>
                <span style={{ fontSize: '0.85rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.35rem', marginBottom: '0.6rem' }}>
                  <Users size={14} />
                  <span>{isSw ? 'Takwimu za Waliohudhuria' : 'Attendance Breakdown'}</span>
                </span>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(90px, 1fr))', gap: '0.6rem' }}>
                  <div>
                    <label style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{isSw ? 'Wanaume' : 'Men'}</label>
                    <input 
                      type="number" 
                      min="0" 
                      className="form-input" 
                      value={menCount} 
                      onChange={(e) => setMenCount(Number(e.target.value))} 
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{isSw ? 'Wanawake' : 'Women'}</label>
                    <input 
                      type="number" 
                      min="0" 
                      className="form-input" 
                      value={womenCount} 
                      onChange={(e) => setWomenCount(Number(e.target.value))} 
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{isSw ? 'Vijana' : 'Youth'}</label>
                    <input 
                      type="number" 
                      min="0" 
                      className="form-input" 
                      value={youthCount} 
                      onChange={(e) => setYouthCount(Number(e.target.value))} 
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{isSw ? 'Watoto' : 'Children'}</label>
                    <input 
                      type="number" 
                      min="0" 
                      className="form-input" 
                      value={childrenCount} 
                      onChange={(e) => setChildrenCount(Number(e.target.value))} 
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.75rem', color: 'var(--emerald-600)', fontWeight: 700 }}>{isSw ? 'Wageni' : 'Visitors'}</label>
                    <input 
                      type="number" 
                      min="0" 
                      className="form-input" 
                      value={visitorsCount} 
                      onChange={(e) => setVisitorsCount(Number(e.target.value))} 
                    />
                  </div>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div className="form-group">
                  <label className="form-label">{isSw ? 'Somo Lililofundishwa' : 'Scripture / Topic'}</label>
                  <input 
                    type="text" 
                    className="form-input"
                    placeholder="Mfano: Zaburi 23"
                    value={topic}
                    onChange={(e) => setTopic(e.target.value)}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">{isSw ? 'Sadaka Iliyokusanywa (Tsh)' : 'Offering Collected (Tsh)'}</label>
                  <input 
                    type="number" 
                    className="form-input"
                    placeholder="Mfano: 85000"
                    value={offering}
                    onChange={(e) => setOffering(e.target.value)}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label" style={{ color: 'var(--error)', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                  <AlertTriangle size={14} />
                  <span>{isSw ? 'Wagonjwa & Mahitaji ya Ustawi (Mchungaji Atembelee)' : 'Sick & Pastoral Welfare Alerts'}</span>
                </label>
                <textarea 
                  className="form-textarea"
                  rows={2}
                  placeholder={isSw ? 'Mfano: Mama Joyce anaumwa, anahitaji maombi ya Mchungaji...' : 'e.g. Member unwell, requesting pastoral visitation'}
                  value={welfareAlert}
                  onChange={(e) => setWelfareAlert(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label className="form-label">{isSw ? 'Maombi Maalum ya Washirika' : 'Prayer Requests'}</label>
                <textarea 
                  className="form-textarea"
                  rows={2}
                  placeholder={isSw ? 'Maombi ya kazi, shule, biashara au shukrani...' : 'Special prayer requests from fellowship'}
                  value={prayers}
                  onChange={(e) => setPrayers(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label className="form-label">{isSw ? 'Jina la Kiongozi Anayewasilisha' : 'Submitting Leader Name'}</label>
                <input 
                  type="text" 
                  className="form-input"
                  placeholder="Mfano: Mwl. Daudi Msechu"
                  value={leaderName}
                  onChange={(e) => setLeaderName(e.target.value)}
                />
              </div>

              <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1.25rem' }}>
                <button type="submit" className="btn-primary" style={{ flex: 1 }}>
                  {isSw ? 'Wasilisha Ripoti kwa Mchungaji' : 'Submit to Senior Pastor'}
                </button>
                <button 
                  type="button" 
                  onClick={() => setShowNewReportModal(false)}
                  className="btn-secondary"
                >
                  {isSw ? 'Ghairi' : 'Cancel'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
