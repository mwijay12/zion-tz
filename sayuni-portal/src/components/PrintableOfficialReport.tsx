import React, { useState } from 'react';
import { CHURCH_PROFILE } from '../data/mockData';
import type { VisitorRecord, JumuiyaReport } from '../types';
import { Printer, X, Download } from 'lucide-react';
import {
  generateVisitorsReportPdf,
  generateGroupsReportPdf,
  generateBulletinPdf,
  type PdfMode
} from '../services/officialPdfService';

interface PrintableOfficialReportProps {
  reportType: 'visitors_monthly' | 'groups_consolidated' | 'weekly_bulletin';
  title: string;
  subtitle: string;
  visitors?: VisitorRecord[];
  reports?: JumuiyaReport[];
  notices?: any[];
  onClose: () => void;
}

export const PrintableOfficialReport: React.FC<PrintableOfficialReportProps> = ({
  reportType,
  title,
  subtitle,
  visitors = [],
  reports = [],
  notices = [],
  onClose,
}) => {
  const [currentDate] = useState(() =>
    new Date().toLocaleDateString('sw-TZ', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    })
  );
  const [reportReference] = useState(
    () => `ZFC/RIP/${Date.now().toString().slice(-6)}`
  );

  const [isGenerating, setIsGenerating] = useState(false);

  // Generates a real A4 PDF document (vector text) — never prints the web page.
  const handlePrint = async (mode: PdfMode = 'open') => {
    if (isGenerating) return;
    setIsGenerating(true);
    try {
      if (reportType === 'visitors_monthly') {
        await generateVisitorsReportPdf(visitors, { title, subtitle, mode });
      } else if (reportType === 'groups_consolidated') {
        await generateGroupsReportPdf(reports, { title, subtitle, mode });
      } else {
        await generateBulletinPdf(notices, { title, subtitle, mode });
      }
    } finally {
      setIsGenerating(false);
    }
  };

  const totalAttendees = reports.reduce(
    (sum, r) => sum + r.attendeesMen + r.attendeesWomen + r.attendeesYouth + r.attendeesChildren,
    0
  );
  const totalOfferings = reports.reduce((sum, r) => sum + r.offeringAmount, 0);

  return (
    <div className="printable-report-backdrop">
      <div className="printable-report-actions-bar no-print">
        <div className="actions-left">
          <span className="badge badge-blue">Hakikisho Rasmi la Kuchapisha (Print Preview)</span>
          <span className="text-muted">A4 Portrait • Saini Rasmi ya Katibu & Askofu</span>
        </div>
        <div className="actions-right" style={{ display: 'flex', gap: '0.65rem' }}>
          <button 
            onClick={() => handlePrint('open')} 
            className="btn-primary" 
            style={{ padding: '0.6rem 1.4rem' }}
            disabled={isGenerating}
          >
            <Printer size={16} />
            <span>{isGenerating ? 'Inatengeneza PDF...' : 'Fungua / Chapa PDF Halisi'}</span>
          </button>
          <button 
            onClick={() => handlePrint('download')} 
            className="btn-secondary" 
            style={{ padding: '0.6rem 1.2rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}
            disabled={isGenerating}
            title="Pakua faili la PDF moja kwa moja"
          >
            <Download size={16} />
            <span>Pakua PDF</span>
          </button>
          <button onClick={onClose} className="btn-secondary" style={{ padding: '0.6rem 1.2rem' }}>
            <X size={16} />
            <span>Funga</span>
          </button>
        </div>
      </div>

      <div className="printable-document-sheet">
        {/* Official Church Letterhead */}
        <header className="report-letterhead">
          <div className="letterhead-top">
            <div className="letterhead-logo-wrap">
              <img
                src="/zion_logo.svg"
                alt="Z.F.C Logo"
                className="letterhead-logo"
                onError={(e) => {
                  (e.target as HTMLElement).style.display = 'none';
                }}
              />
            </div>
            <div className="letterhead-church-info">
              <h1 className="letterhead-church-name">{CHURCH_PROFILE.name}</h1>
              <h2 className="letterhead-church-sw">{CHURCH_PROFILE.nameSw}</h2>
              <p className="letterhead-motto">"{CHURCH_PROFILE.motto}"</p>
              <p className="letterhead-address">
                Makao Makuu: {CHURCH_PROFILE.location} • S.L.P. / Simu: {CHURCH_PROFILE.phone}
              </p>
            </div>
          </div>
          <div className="letterhead-divider" />
        </header>

        {/* Report Metadata Header */}
        <div className="report-meta-header">
          <div>
            <h3 className="report-title">{title}</h3>
            <p className="report-subtitle">{subtitle}</p>
          </div>
          <div className="report-reference-box">
            <div><strong>Tarehe:</strong> {currentDate}</div>
            <div><strong>Ofisi:</strong> Sekretarieti Kuu ya Kanisa</div>
            <div><strong>Namba ya Rejea:</strong> {reportReference}</div>
          </div>
        </div>

        {/* Report Content Based on Type */}
        {reportType === 'visitors_monthly' && (
          <div className="report-content-body">
            {/* KPI Summary Cards */}
            <div className="report-summary-cards">
              <div className="summary-box">
                <span className="summary-title">Jumla ya Wageni</span>
                <strong className="summary-num">{visitors.length}</strong>
              </div>
              <div className="summary-box">
                <span className="summary-title">Wageni Wapya</span>
                <strong className="summary-num">
                  {visitors.filter((v) => v.followUpStatus === 'Mpya').length}
                </strong>
              </div>
              <div className="summary-box">
                <span className="summary-title">Waliotembelewa</span>
                <strong className="summary-num">
                  {visitors.filter((v) => v.followUpStatus === 'Ametembelewa').length}
                </strong>
              </div>
              <div className="summary-box">
                <span className="summary-title">Waliojiunga na Jumuiya</span>
                <strong className="summary-num">
                  {visitors.filter((v) => v.followUpStatus === 'Amejiunga na Jumuiya').length}
                </strong>
              </div>
            </div>

            {/* Official Visitors Table */}
            <table className="report-table">
              <thead>
                <tr>
                  <th style={{ width: '30px' }}>#</th>
                  <th>Jina Kamili la Mgeni</th>
                  <th>Simu (WhatsApp)</th>
                  <th>Mtaa / Makazi</th>
                  <th>Tarehe ya Kufika</th>
                  <th>Jumuiya ya Karibu</th>
                  <th>Hali ya Ufuatiliaji</th>
                </tr>
              </thead>
              <tbody>
                {visitors.length === 0 ? (
                  <tr>
                    <td colSpan={7} style={{ textAlign: 'center', padding: '1.5rem' }}>
                      Hakuna rekodi ya wageni iliyopatikana kwa kipindi hiki.
                    </td>
                  </tr>
                ) : (
                  visitors.map((v, i) => (
                    <tr key={v.id}>
                      <td style={{ textAlign: 'center', fontWeight: 'bold' }}>{i + 1}</td>
                      <td>
                        <strong>{v.fullName}</strong>
                        {v.prayerRequest && (
                          <div className="table-sub-detail">
                            <em>Ombi:</em> {v.prayerRequest}
                          </div>
                        )}
                      </td>
                      <td>{v.phone}</td>
                      <td>{v.residence}</td>
                      <td>{v.firstVisitDate}</td>
                      <td>{v.assignedJumuiya}</td>
                      <td>
                        <span className="status-cell-pill">{v.followUpStatus}</span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {reportType === 'groups_consolidated' && (
          <div className="report-content-body">
            <div className="report-summary-cards">
              <div className="summary-box">
                <span className="summary-title">Jumla ya Vikundi / Jumuiya</span>
                <strong className="summary-num">{reports.length}</strong>
              </div>
              <div className="summary-box">
                <span className="summary-title">Waliohudhuria Ibada za Nyumba</span>
                <strong className="summary-num">{totalAttendees}</strong>
              </div>
              <div className="summary-box">
                <span className="summary-title">Jumla ya Sadaka za Jumuiya</span>
                <strong className="summary-num">Tsh {totalOfferings.toLocaleString()}</strong>
              </div>
            </div>

            <table className="report-table">
              <thead>
                <tr>
                  <th style={{ width: '30px' }}>#</th>
                  <th>Jina la Jumuiya / Kikundi</th>
                  <th>Mwakilishi / Kiongozi</th>
                  <th>Mwenyeji / Nyumba ya Ibada</th>
                  <th>Mahudhurio</th>
                  <th>Somo Lililofundishwa</th>
                  <th>Sadaka (Tsh)</th>
                </tr>
              </thead>
              <tbody>
                {reports.map((r, i) => (
                  <tr key={r.id}>
                    <td style={{ textAlign: 'center', fontWeight: 'bold' }}>{i + 1}</td>
                    <td><strong>{r.jumuiyaName}</strong></td>
                    <td>{r.submittedBy}</td>
                    <td>{r.hostFamily || 'Nyumba ya Ibada'}</td>
                    <td>
                      {r.attendeesMen + r.attendeesWomen + r.attendeesYouth + r.attendeesChildren} Waumini
                    </td>
                    <td>{r.scriptureTopic}</td>
                    <td style={{ textAlign: 'right', fontWeight: 'bold' }}>
                      {r.offeringAmount.toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {reportType === 'weekly_bulletin' && (
          <div className="report-content-body">
            <div className="report-summary-cards">
              <div className="summary-box">
                <span className="summary-title">Jumla ya Matangazo</span>
                <strong className="summary-num">{(notices || []).length}</strong>
              </div>
              <div className="summary-box">
                <span className="summary-title">Wigo wa Wasomaji</span>
                <strong className="summary-num">Waumini Wote (Sayuni HQ)</strong>
              </div>
              <div className="summary-box">
                <span className="summary-title">Msimamizi wa Kijarida</span>
                <strong className="summary-num">Ofisi ya Katibu Mkuu</strong>
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.9rem', marginTop: '1rem' }}>
              {(notices || []).map((n, i) => (
                <div 
                  key={n.id || i} 
                  style={{ 
                    border: '1px solid #cbd5e1', 
                    borderLeft: n.isUrgent ? '4px solid #ba1a1a' : '4px solid #0D52CD',
                    borderRadius: '6px',
                    padding: '0.8rem 1rem',
                    background: '#f8fafc'
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.3rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <span style={{ 
                        fontSize: '0.72rem', 
                        fontWeight: 700, 
                        padding: '0.15rem 0.5rem', 
                        borderRadius: '4px',
                        background: n.isUrgent ? '#fee2e2' : '#dbeafe',
                        color: n.isUrgent ? '#991b1b' : '#1e40af'
                      }}>
                        {n.category || 'Taarifa Kuu'}
                      </span>
                      <strong style={{ fontSize: '0.98rem', color: '#0f172a' }}>{n.title}</strong>
                    </div>
                    <span style={{ fontSize: '0.75rem', color: '#64748b' }}>{n.date}</span>
                  </div>
                  <p style={{ margin: 0, fontSize: '0.86rem', color: '#334155', lineHeight: 1.5 }}>
                    {n.content}
                  </p>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Official Signatures and Seals Section */}
        <footer className="report-sign-footer">
          <div className="sign-col">
            <div className="sign-label">Imeandaliwa na Kuthibitishwa:</div>
            <div className="sign-space" />
            <div className="sign-name">Mwl. Peter Mwita</div>
            <div className="sign-title">Katibu Mkuu wa Kanisa — Sayuni Yerusalemu</div>
            <div className="sign-date">Tarehe: {currentDate}</div>
          </div>

          <div className="seal-col">
            <div className="official-stamp-circle">
              <div className="stamp-inner">
                <span>ZION JERUSALEM</span>
                <span className="stamp-mid">OFFICIAL SEAL</span>
                <span>MBAGALA HQ</span>
              </div>
            </div>
          </div>

          <div className="sign-col">
            <div className="sign-label">Imeridhiwa na Kuidhinishwa:</div>
            <div className="sign-space" />
            <div className="sign-name">Askofu Mercy James</div>
            <div className="sign-title">Mchungaji Askofu Kiongozi — Sayuni Yerusalemu</div>
            <div className="sign-date">Tarehe: {currentDate}</div>
          </div>
        </footer>
      </div>
    </div>
  );
};
