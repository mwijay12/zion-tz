import React, { useState, useEffect } from 'react';
import { 
  UserCheck, 
  UserPlus, 
  Phone, 
  MapPin, 
  HeartHandshake, 
  MessageSquare, 
  CheckCircle2, 
  Clock, 
  Search,
  Users,
  Printer
} from 'lucide-react';
import type { Language, VisitorRecord } from '../types';
import { PrintableOfficialReport } from './PrintableOfficialReport';
import { churchSync } from '../services/churchSyncService';

interface DeaconsPortalProps {
  language: Language;
}

const INITIAL_VISITORS: VisitorRecord[] = [
  {
    id: 'vis-1',
    fullName: 'Grace Emmanuel Shayo',
    phone: '+255 754 112 334',
    residence: 'Mbagala Chamazi',
    firstVisitDate: '2026-09-06',
    invitedBy: 'Mama Sarah (Kwaya ya Galilaya)',
    prayerRequest: 'Kuponywa mtoto wangu mgonjwa na kupata kazi mpya.',
    assignedJumuiya: 'Chamazi',
    followUpStatus: 'Mpya',
    welfareNeeds: 'Anahitaji maombi ya uponyaji nyumbani',
    registeredByDeacon: 'Shemasi Daudi'
  },
  {
    id: 'vis-2',
    fullName: 'Peter Mwita Marwa',
    phone: '+255 765 889 001',
    residence: 'Mbagala Kuu - Stand',
    firstVisitDate: '2026-08-30',
    invitedBy: 'Mzee wa Kanisa Yohana',
    prayerRequest: 'Kufunguliwa kibiashara na amani ndani ya familia.',
    assignedJumuiya: 'Mbagala Kuu',
    followUpStatus: 'Ametembelewa',
    welfareNeeds: 'Alipokelewa vizuri na timu ya ukaribisho',
    registeredByDeacon: 'Shemasi Baraka'
  },
  {
    id: 'vis-3',
    fullName: 'Neema Josephat Maleko',
    phone: '+255 784 990 122',
    residence: 'Charambe Mwisho',
    firstVisitDate: '2026-08-23',
    invitedBy: 'Semina ya Vijana',
    prayerRequest: 'Kujiunga rasmi na Kanisa la Sayuni na madarasa ya ubatizo.',
    assignedJumuiya: 'Charambe',
    followUpStatus: 'Amejiunga na Jumuiya',
    welfareNeeds: 'Amepangiwa darasa la ubatizo mwezi huu',
    registeredByDeacon: 'Shemasi Daudi'
  }
];

export const DeaconsPortal: React.FC<DeaconsPortalProps> = ({ language }) => {
  const isSw = language === 'sw';

  const [visitors, setVisitors] = useState<VisitorRecord[]>(() => {
    const synced = churchSync.getVisitors();
    if (synced && synced.length > 0) return synced;
    try {
      const saved = localStorage.getItem('zion_portal_visitors');
      return saved ? JSON.parse(saved) : INITIAL_VISITORS;
    } catch {
      return INITIAL_VISITORS;
    }
  });

  useEffect(() => {
    const unsubscribe = churchSync.subscribe((msg) => {
      if (msg.type === 'VISITOR_ADDED' || msg.type === 'VISITORS_UPDATED') {
        const synced = churchSync.getVisitors();
        if (synced && synced.length > 0) {
          setVisitors(synced);
        }
      }
    });
    return unsubscribe;
  }, []);

  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [showAddModal, setShowAddModal] = useState<boolean>(false);
  const [showPrintReport, setShowPrintReport] = useState<boolean>(false);

  // Form State
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [residence, setResidence] = useState('');
  const [invitedBy, setInvitedBy] = useState('');
  const [assignedJumuiya, setAssignedJumuiya] = useState('Mbagala Kuu');
  const [prayerRequest, setPrayerRequest] = useState('');
  const [welfareNeeds, setWelfareNeeds] = useState('');

  const handleAddVisitor = (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName.trim() || !phone.trim()) return;

    const newRecord: VisitorRecord = {
      id: `vis-${Date.now()}`,
      fullName: fullName.trim(),
      phone: phone.trim(),
      residence: residence.trim() || 'Mbagala',
      firstVisitDate: new Date().toISOString().split('T')[0],
      invitedBy: invitedBy.trim() || 'Ushirika wa Jumapili',
      assignedJumuiya,
      prayerRequest: prayerRequest.trim() || 'Maombi ya baraka na ushindi',
      followUpStatus: 'Mpya',
      welfareNeeds: welfareNeeds.trim(),
      registeredByDeacon: 'Shemasi Zamu'
    };

    churchSync.addVisitor(newRecord);
    setVisitors(churchSync.getVisitors());

    // Reset Form
    setFullName('');
    setPhone('');
    setResidence('');
    setInvitedBy('');
    setPrayerRequest('');
    setWelfareNeeds('');
    setShowAddModal(false);
  };

  const handleUpdateStatus = (id: string, newStatus: VisitorRecord['followUpStatus']) => {
    churchSync.updateVisitorStatus(id, newStatus);
    setVisitors(churchSync.getVisitors());
  };

  const filteredVisitors = visitors.filter(v => {
    const matchesStatus = filterStatus === 'all' || v.followUpStatus === filterStatus;
    const matchesSearch = 
      v.fullName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      v.phone.includes(searchTerm) ||
      v.residence.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesStatus && matchesSearch;
  });

  const totalVisitors = visitors.length;
  const newVisitors = visitors.filter(v => v.followUpStatus === 'Mpya').length;
  const visitedVisitors = visitors.filter(v => v.followUpStatus === 'Ametembelewa').length;
  const integratedVisitors = visitors.filter(v => v.followUpStatus === 'Amejiunga na Jumuiya').length;

  return (
    <div className="portal-page-container">
      {/* Header Banner */}
      <div 
        className="portal-banner" 
        style={{ 
          background: 'linear-gradient(135deg, #0A2540 0%, #082F70 55%, #0D52CD 100%)',
          color: '#ffffff'
        }}
      >
        <div className="portal-banner-content">
          <div className="portal-banner-icon">
            <HeartHandshake size={32} color="#ffffff" />
          </div>
          <div>
            <div className="portal-tag" style={{ color: '#dbeafe' }}>
              {isSw ? 'BARAZA LA MASHEMASI & WAZEE' : 'DEACONS & WELFARE COUNCIL'}
            </div>
            <h1 className="portal-title" style={{ color: '#ffffff' }}>
              {isSw ? 'Mapokezi ya Wageni & Ustawi wa Jamii' : 'Visitor Reception & Pastoral Welfare'}
            </h1>
            <p className="portal-subtitle" style={{ color: 'rgba(255, 255, 255, 0.92)' }}>
              {isSw 
                ? 'Sajili wageni wapya wa ibada za Jumapili, panga ufuatiliaji wa Jumuiya, na simamia maombi ya ustawi.' 
                : 'Register Sunday first-time guests, coordinate home-cell visitations, and pastoral compassion outreach.'}
            </p>
          </div>
        </div>
        <div style={{ display: 'flex', gap: '0.65rem', flexWrap: 'wrap' }}>
          <button 
            onClick={() => setShowPrintReport(true)}
            className="portal-secondary-btn"
            style={{ 
              background: 'rgba(255, 255, 255, 0.16)', 
              color: '#ffffff', 
              border: '1px solid rgba(255, 255, 255, 0.35)',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '0.5rem',
              padding: '0.65rem 1.2rem',
              borderRadius: '8px',
              fontWeight: 700
            }}
          >
            <Printer size={17} />
            <span>{isSw ? 'Chapa Daftari la Wageni (PDF)' : 'Print Guest Report (PDF)'}</span>
          </button>

          <button 
            onClick={() => setShowAddModal(true)}
            className="portal-primary-btn"
          >
            <UserPlus size={18} />
            <span>{isSw ? '+ Sajili Mgeni Mpya' : '+ Register New Guest'}</span>
          </button>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="portal-metrics-grid">
        <div className="portal-metric-card">
          <div className="metric-icon" style={{ background: 'rgba(13, 82, 205, 0.1)', color: '#0D52CD' }}>
            <Users size={22} />
          </div>
          <div>
            <div className="metric-value">{totalVisitors}</div>
            <div className="metric-label">{isSw ? 'Jumla ya Wageni' : 'Total Guests'}</div>
          </div>
        </div>

        <div className="portal-metric-card">
          <div className="metric-icon" style={{ background: 'rgba(239, 68, 68, 0.1)', color: '#EF4444' }}>
            <Clock size={22} />
          </div>
          <div>
            <div className="metric-value">{newVisitors}</div>
            <div className="metric-label">{isSw ? 'Wageni Wapya (Wahitaji Ufuatiliaji)' : 'New Guests Pending'}</div>
          </div>
        </div>

        <div className="portal-metric-card">
          <div className="metric-icon" style={{ background: 'rgba(197, 155, 39, 0.15)', color: '#C59B27' }}>
            <UserCheck size={22} />
          </div>
          <div>
            <div className="metric-value">{visitedVisitors}</div>
            <div className="metric-label">{isSw ? 'Waliofikiwa / Kutembelewa' : 'Followed-Up / Visited'}</div>
          </div>
        </div>

        <div className="portal-metric-card">
          <div className="metric-icon" style={{ background: 'rgba(16, 185, 129, 0.1)', color: '#10B981' }}>
            <CheckCircle2 size={22} />
          </div>
          <div>
            <div className="metric-value">{integratedVisitors}</div>
            <div className="metric-label">{isSw ? 'Wamejiunga na Jumuiya' : 'Joined Cell Groups'}</div>
          </div>
        </div>
      </div>

      {/* Controls Bar: Search & Filter */}
      <div className="portal-controls-bar">
        <div className="portal-search-box">
          <Search size={18} color="var(--text-muted)" />
          <input 
            type="text"
            placeholder={isSw ? 'Tafuta mgeni kwa jina, simu, au eneo...' : 'Search guest by name, phone or area...'}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        <div className="portal-filter-tabs">
          <button 
            className={`filter-tab ${filterStatus === 'all' ? 'active' : ''}`}
            onClick={() => setFilterStatus('all')}
          >
            {isSw ? 'Wote' : 'All'}
          </button>
          <button 
            className={`filter-tab ${filterStatus === 'Mpya' ? 'active' : ''}`}
            onClick={() => setFilterStatus('Mpya')}
          >
            {isSw ? 'Wapya' : 'New'}
          </button>
          <button 
            className={`filter-tab ${filterStatus === 'Ametembelewa' ? 'active' : ''}`}
            onClick={() => setFilterStatus('Ametembelewa')}
          >
            {isSw ? 'Waliotembelewa' : 'Visited'}
          </button>
          <button 
            className={`filter-tab ${filterStatus === 'Amejiunga na Jumuiya' ? 'active' : ''}`}
            onClick={() => setFilterStatus('Amejiunga na Jumuiya')}
          >
            {isSw ? 'Waliojiunga' : 'Integrated'}
          </button>
        </div>
      </div>

      {/* Visitors List Cards */}
      <div className="portal-records-list">
        {filteredVisitors.length === 0 ? (
          <div className="portal-empty-card">
            <HeartHandshake size={48} color="var(--primary)" />
            <h3>{isSw ? 'Hakuna orodha ya wageni iliyopatikana' : 'No guest records found'}</h3>
            <p>{isSw ? 'Bonyeza kitufe cha "+ Sajili Mgeni Mpya" kusajili wageni wa ibada ya leo.' : 'Click "+ Register New Guest" to record attendance.'}</p>
          </div>
        ) : (
          filteredVisitors.map((guest) => (
            <div key={guest.id} className="portal-record-card">
              <div className="record-header">
                <div>
                  <h3 className="record-title">{guest.fullName}</h3>
                  <div className="record-sub">
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.3rem' }}>
                      <Phone size={13} /> {guest.phone}
                    </span>
                    <span>•</span>
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.3rem' }}>
                      <MapPin size={13} /> {guest.residence}
                    </span>
                    <span>•</span>
                    <span>Tarehe: {guest.firstVisitDate}</span>
                  </div>
                </div>

                {/* Status Badge */}
                <span className={`portal-status-pill status-${guest.followUpStatus.toLowerCase().replace(/\s+/g, '-')}`}>
                  {guest.followUpStatus}
                </span>
              </div>

              {/* Details & Needs */}
              <div className="record-body">
                {guest.prayerRequest && (
                  <div className="record-meta-item">
                    <span className="meta-label">{isSw ? 'Haja ya Maombi:' : 'Prayer Need:'}</span>
                    <span className="meta-value">{guest.prayerRequest}</span>
                  </div>
                )}
                <div className="record-meta-row">
                  <div className="record-meta-item">
                    <span className="meta-label">{isSw ? 'Amealikwa na:' : 'Invited by:'}</span>
                    <span className="meta-value">{guest.invitedBy || 'Ibada ya Sayuni'}</span>
                  </div>
                  <div className="record-meta-item">
                    <span className="meta-label">{isSw ? 'Jumuiya ya Karibu:' : 'Assigned Cell:'}</span>
                    <span className="meta-value" style={{ fontWeight: 700, color: 'var(--primary)' }}>
                      {guest.assignedJumuiya}
                    </span>
                  </div>
                </div>
              </div>

              {/* Action Toolbar for Deacon on Phone/PC */}
              <div className="record-actions-toolbar">
                <a 
                  href={`tel:${guest.phone}`}
                  className="toolbar-btn call"
                  title="Piga Simu"
                >
                  <Phone size={14} />
                  <span>{isSw ? 'Piga Simu' : 'Call'}</span>
                </a>
                <a 
                  href={`https://wa.me/${guest.phone.replace(/[^0-9]/g, '')}?text=${encodeURIComponent(`Shalom ${guest.fullName}, tunakushukuru kwa kuabudu nasi katika Kanisa la Sayuni Jerusalem (Mbagala). Mungu wa Sayuni akubariki sana!`)}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="toolbar-btn whatsapp"
                  title="Tuma WhatsApp"
                >
                  <MessageSquare size={14} />
                  <span>WhatsApp</span>
                </a>

                {/* Status Switcher for Deacons */}
                <div className="status-dropdown-wrap" style={{ marginLeft: 'auto' }}>
                  <select 
                    value={guest.followUpStatus}
                    onChange={(e) => handleUpdateStatus(guest.id, e.target.value as VisitorRecord['followUpStatus'])}
                    className="portal-select-compact"
                  >
                    <option value="Mpya">{isSw ? 'Hali: Mpya' : 'Status: New'}</option>
                    <option value="Ametembelewa">{isSw ? 'Hali: Ametembelewa' : 'Status: Visited'}</option>
                    <option value="Amejiunga na Jumuiya">{isSw ? 'Hali: Amejiunga' : 'Status: Integrated'}</option>
                    <option value="Anahitaji Maombi">{isSw ? 'Hali: Anahitaji Maombi' : 'Status: Needs Prayer'}</option>
                  </select>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Modal Dialog: Register New Guest */}
      {showAddModal && (
        <div className="portal-modal-overlay">
          <div className="portal-modal-box">
            <div className="portal-modal-header">
              <h3>{isSw ? 'Sajili Mgeni Mpya wa Sayuni' : 'Register New Sunday Guest'}</h3>
              <button onClick={() => setShowAddModal(false)} className="close-btn">×</button>
            </div>
            <form onSubmit={handleAddVisitor} className="portal-form">
              <div className="form-group">
                <label>{isSw ? 'Jina Kamili la Mgeni *' : 'Guest Full Name *'}</label>
                <input 
                  type="text" 
                  required
                  placeholder={isSw ? 'mf. Neema Emmanuel' : 'e.g. Grace Emmanuel'}
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>{isSw ? 'Namba ya Simu (WhatsApp) *' : 'Phone Number *'}</label>
                  <input 
                    type="tel" 
                    required
                    placeholder="+255 7..."
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                  />
                </div>
                <div className="form-group">
                  <label>{isSw ? 'Mahali Anapoishi / Mtaa *' : 'Residence / Street *'}</label>
                  <input 
                    type="text" 
                    required
                    placeholder={isSw ? 'mf. Mbagala Chamazi' : 'e.g. Chamazi'}
                    value={residence}
                    onChange={(e) => setResidence(e.target.value)}
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>{isSw ? 'Mwenyeji / Amealikwa na Nani?' : 'Invited by:'}</label>
                  <input 
                    type="text" 
                    placeholder={isSw ? 'Jina la mwenyeji' : 'Invited by member'}
                    value={invitedBy}
                    onChange={(e) => setInvitedBy(e.target.value)}
                  />
                </div>
                <div className="form-group">
                  <label>{isSw ? 'Jumuiya ya Kumpa Ukaribu' : 'Assign to Home Cell'}</label>
                  <select 
                    value={assignedJumuiya}
                    onChange={(e) => setAssignedJumuiya(e.target.value)}
                  >
                    <option value="Mbagala Kuu">Mbagala Kuu</option>
                    <option value="Chamazi">Chamazi</option>
                    <option value="Rangi Tatu">Rangi Tatu</option>
                    <option value="Charambe">Charambe</option>
                    <option value="Kiponzelo">Kiponzelo</option>
                  </select>
                </div>
              </div>

              <div className="form-group">
                <label>{isSw ? 'Haja ya Maombi / Sababu ya Kufika' : 'Prayer Request / Reason for Visit'}</label>
                <textarea 
                  rows={2}
                  placeholder={isSw ? 'Ujumbe au ombi maalum la maombi...' : 'Prayer request or notes...'}
                  value={prayerRequest}
                  onChange={(e) => setPrayerRequest(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label>{isSw ? 'Mahitaji Maalum ya Ustawi (Welfare / Msaada)' : 'Welfare Needs (Optional)'}</label>
                <input 
                  type="text" 
                  placeholder={isSw ? 'mf. Wagonjwa, mtoto, n.k.' : 'Special assistance...'}
                  value={welfareNeeds}
                  onChange={(e) => setWelfareNeeds(e.target.value)}
                />
              </div>

              <div className="portal-modal-footer">
                <button type="button" onClick={() => setShowAddModal(false)} className="portal-secondary-btn">
                  {isSw ? 'Ghairi' : 'Cancel'}
                </button>
                <button type="submit" className="portal-primary-btn">
                  {isSw ? 'Hifadhi Mgeni' : 'Save Guest'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* PRINTABLE GUESTS REPORT MODAL */}
      {showPrintReport && (
        <PrintableOfficialReport
          reportType="visitors_monthly"
          title="Daftari Rasmi la Wageni na Ufuatiliaji wa Kiroho"
          subtitle="Idara ya Ukaribisho, Mashemasi na Ustawi wa Jamii — Sayuni Yerusalemu (Mbagala Kwa Matope)"
          visitors={visitors}
          onClose={() => setShowPrintReport(false)}
        />
      )}
    </div>
  );
};
