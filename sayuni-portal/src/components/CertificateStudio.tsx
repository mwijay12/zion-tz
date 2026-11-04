import React, { useState } from 'react';
import {
  AlertCircle,
  Award,
  Download,
  FileEdit,
  Loader2
} from 'lucide-react';
import type { Language, UserRole, CertificateType } from '../types';
import { CHURCH_PROFILE } from '../data/mockData';
import {
  CERTIFICATE_DEFINITIONS,
  CERTIFICATE_TYPE_ORDER,
  certificateBody,
  certificateTitle
} from '../data/certificateContent';
import {
  createCertificateSerial,
  downloadCertificatePdf
} from '../services/certificatePdfService';

interface CertificateStudioProps {
  language: Language;
  userRole: UserRole;
}

export const CertificateStudio: React.FC<CertificateStudioProps> = ({
  language
}) => {
  const isSw = language === 'sw';
  const [selectedType, setSelectedType] = useState<CertificateType>('baptism');
  
  // Active Form Fields
  const [recipientName, setRecipientName] = useState('');
  const [spouseName, setSpouseName] = useState('');
  const [parentNames, setParentNames] = useState('');
  const [eventDate, setEventDate] = useState('2026-08-16');
  const [scripture, setScripture] = useState(CERTIFICATE_DEFINITIONS.baptism.defaultVerse);
  const [notes, setNotes] = useState('Ubatizo wa maji tele katika Mto Ruvu.');
  const [certificateSerial, setCertificateSerial] = useState(() => createCertificateSerial('baptism'));
  const [isGenerating, setIsGenerating] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const handleTypeChange = (type: CertificateType) => {
    setSelectedType(type);
    setScripture(CERTIFICATE_DEFINITIONS[type].defaultVerse);
    setCertificateSerial(createCertificateSerial(type));
    setFormError(null);
  };

  const handleDownload = async () => {
    const missingFields: string[] = [];

    if (!recipientName.trim()) {
      missingFields.push(isSw ? 'jina la mpokeaji' : 'recipient name');
    }
    if (!eventDate) {
      missingFields.push(isSw ? 'tarehe ya tukio' : 'event date');
    }
    if (selectedType === 'marriage' && !spouseName.trim()) {
      missingFields.push(isSw ? 'jina la mwanandoa' : 'spouse name');
    }
    if (selectedType === 'dedication' && !parentNames.trim()) {
      missingFields.push(isSw ? 'majina ya wazazi' : 'parents names');
    }

    if (missingFields.length > 0) {
      setFormError(
        `${isSw ? 'Tafadhali jaza' : 'Please fill in'} ${missingFields.join(', ')}.`
      );
      return;
    }

    setFormError(null);
    setIsGenerating(true);

    try {
      await downloadCertificatePdf({
        type: selectedType,
        recipientName: recipientName.trim(),
        spouseName: spouseName.trim(),
        parentNames: parentNames.trim(),
        eventDate,
        scripture: scripture.trim(),
        notes: notes.trim(),
        serialNumber: certificateSerial,
        language
      });
    } catch {
      setFormError(
        isSw
          ? 'Imeshindikana kutengeneza PDF. Tafadhali jaribu tena.'
          : 'Unable to generate the PDF. Please try again.'
      );
    } finally {
      setIsGenerating(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Top Header */}
      <div className="no-print" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <span className="badge badge-purple" style={{ marginBottom: '0.35rem', display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
            <Award size={13} />
            <span>{isSw ? 'Utoaji wa Nyaraka Rasmi' : 'Official Credentials Studio'}</span>
          </span>
          <h2 style={{ fontFamily: 'var(--font-cinzel)', fontSize: '1.65rem', fontWeight: 800, color: 'var(--text-headline)' }}>
            {isSw ? 'Studio ya Kutengeneza Vyeti vya Kanisa' : 'Church Certificate Studio'}
          </h2>
        </div>

        <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center', flexWrap: 'wrap' }}>
          <span className="badge badge-gold" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
            {isSw ? 'PDF ya Vekta â€¢ A4 Landscape' : 'Vector PDF â€¢ A4 Landscape'}
          </span>

          <button
            type="button"
            onClick={handleDownload}
            className="btn-primary"
            disabled={isGenerating}
            style={{ padding: '0.65rem 1.4rem' }}
          >
            {isGenerating ? <Loader2 size={18} /> : <Download size={18} />}
            <span>
              {isGenerating
                ? (isSw ? 'Inatengeneza PDF...' : 'Generating PDF...')
                : (isSw ? 'Pakua Cheti (PDF)' : 'Download Certificate (PDF)')}
            </span>
          </button>
        </div>
      </div>

      {/* Type Selector Tabs */}
      <div className="no-print" style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem', borderBottom: '1px solid var(--border-subtle)', paddingBottom: '0.75rem' }}>
        {CERTIFICATE_TYPE_ORDER.map((type) => (
          <button
            key={type}
            onClick={() => handleTypeChange(type)}
            className={`nav-item ${selectedType === type ? 'active' : ''}`}
            style={{ padding: '0.5rem 1.1rem', fontSize: '0.86rem' }}
          >
            <Award size={15} />
            <span>
              {isSw
                ? CERTIFICATE_DEFINITIONS[type].titleSw.replace('CHETI CHA ', '')
                : CERTIFICATE_DEFINITIONS[type].titleEn.replace('CERTIFICATE OF ', '')}
            </span>
          </button>
        ))}
      </div>

      {/* Studio Layout: Left Controls + Right Live Preview */}
      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(320px, 380px) 1fr', gap: '1.5rem', alignItems: 'start' }}>
        {/* Left Controls Form (Hidden on Print) */}
        <div className="church-card no-print" style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <h3 style={{ fontSize: '1.05rem', fontWeight: 700, color: 'var(--text-headline)', borderBottom: '1px solid var(--border-subtle)', paddingBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <FileEdit size={16} style={{ color: 'var(--primary)' }} />
            <span>{isSw ? 'Taarifa za Cheti' : 'Certificate Details'}</span>
          </h3>

          {formError && (
            <div
              role="alert"
              style={{
                display: 'flex',
                alignItems: 'flex-start',
                gap: '0.5rem',
                padding: '0.7rem 0.8rem',
                borderRadius: '8px',
                background: 'var(--error-container)',
                color: 'var(--error)',
                fontSize: '0.8rem',
                lineHeight: 1.45
              }}
            >
              <AlertCircle size={16} style={{ flexShrink: 0, marginTop: '1px' }} />
              <span>{formError}</span>
            </div>
          )}

          <div className="form-group">
            <label className="form-label">{isSw ? 'Jina Kamili la Mpokeaji' : 'Recipient Full Name'}</label>
            <input 
              type="text" 
              className="form-input"
              value={recipientName}
              onChange={(e) => setRecipientName(e.target.value)}
              placeholder="Mfano: Neema J. Mwakyusa"
              maxLength={80}
            />
          </div>

          {selectedType === 'marriage' && (
            <div className="form-group">
              <label className="form-label">{isSw ? 'Jina la Mwanandoa Mwingine' : 'Spouse Full Name'}</label>
              <input 
                type="text" 
                className="form-input"
                value={spouseName}
                onChange={(e) => setSpouseName(e.target.value)}
                placeholder="Mfano: Sarah Kavishe"
                maxLength={80}
              />
            </div>
          )}

          {selectedType === 'dedication' && (
            <div className="form-group">
              <label className="form-label">{isSw ? 'Majina ya Wazazi' : 'Parents Names'}</label>
              <input 
                type="text" 
                className="form-input"
                value={parentNames}
                onChange={(e) => setParentNames(e.target.value)}
                placeholder="Mfano: Mzee Peter & Mama Mary"
                maxLength={120}
              />
            </div>
          )}

          <div className="form-group">
            <label className="form-label">{isSw ? 'Tarehe ya Tukio' : 'Date of Event'}</label>
            <input 
              type="date" 
              className="form-input"
              value={eventDate}
              onChange={(e) => setEventDate(e.target.value)}
            />
          </div>

          <div className="form-group">
            <label className="form-label">{isSw ? 'Fungu la Biblia' : 'Scripture Verse'}</label>
            <textarea 
              className="form-textarea"
              rows={3}
              value={scripture}
              onChange={(e) => setScripture(e.target.value)}
              maxLength={320}
            />
          </div>

          <div className="form-group">
            <label className="form-label">{isSw ? 'Maelezo ya Ziada / Mahali' : 'Location / Special Notes'}</label>
            <input 
              type="text" 
              className="form-input"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              maxLength={140}
            />
          </div>

          <button
            onClick={handleDownload}
            className="btn-gold"
            disabled={isGenerating}
            style={{ width: '100%', marginTop: '0.5rem' }}
          >
            {isGenerating ? <Loader2 size={16} /> : <Download size={16} />}
            <span>
              {isGenerating
                ? (isSw ? 'Inatengeneza PDF...' : 'Generating PDF...')
                : (isSw ? 'Pakua Cheti Sasa (PDF)' : 'Download Certificate Now (PDF)')}
            </span>
          </button>
          <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', lineHeight: 1.45, textAlign: 'center', margin: 0 }}>
            {isSw
              ? 'PDF halisi ya vekta (A4 landscape), si picha ya skrini.'
              : 'True vector PDF (A4 landscape), not a screen capture.'}
          </p>
        </div>

        {/* Right Live Preview: Majestic Ornate Certificate */}
        <div className="certificate-preview-scroll-wrapper" style={{ overflowX: 'auto', paddingBottom: '1rem' }}>
          <div 
            className="certificate-render-wrapper"
            style={{
              width: '820px',
              minHeight: '560px',
              background: '#fffdfa',
              color: '#0f172a',
              padding: '24px',
              margin: '0 auto',
              boxShadow: '0 10px 30px rgba(0,0,0,0.15)',
              borderRadius: '8px',
              position: 'relative',
              boxSizing: 'border-box'
            }}
          >
            {/* Double Ornate Border with Gold Foil Styling */}
            <div 
              style={{
                border: '4px double #d97706',
                padding: '20px',
                minHeight: '504px',
                position: 'relative',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'space-between',
                background: 'radial-gradient(ellipse at center, rgba(255,255,255,1) 0%, rgba(254,249,235,0.7) 100%)'
              }}
            >
              {/* Ornate Corner Elements */}
              <div style={{ position: 'absolute', top: '8px', left: '8px', width: '26px', height: '26px', borderTop: '3px solid #b45309', borderLeft: '3px solid #b45309' }} />
              <div style={{ position: 'absolute', top: '8px', right: '8px', width: '26px', height: '26px', borderTop: '3px solid #b45309', borderRight: '3px solid #b45309' }} />
              <div style={{ position: 'absolute', bottom: '8px', left: '8px', width: '26px', height: '26px', borderBottom: '3px solid #b45309', borderLeft: '3px solid #b45309' }} />
              <div style={{ position: 'absolute', bottom: '8px', right: '8px', width: '26px', height: '26px', borderBottom: '3px solid #b45309', borderRight: '3px solid #b45309' }} />

              {/* Watermark in center */}
              <div 
                style={{
                  position: 'absolute',
                  top: '50%',
                  left: '50%',
                  transform: 'translate(-50%, -50%)',
                  opacity: 0.05,
                  pointerEvents: 'none',
                  textAlign: 'center'
                }}
              >
                <img 
                  src="/zion_logo.png" 
                  alt="ZFC Watermark" 
                  style={{ width: '280px', height: '280px', objectFit: 'contain' }} 
                />
              </div>

              {/* Certificate Header */}
              <div style={{ textAlign: 'center', position: 'relative', zIndex: 2 }}>
                <div style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  width: '64px',
                  height: '64px',
                  borderRadius: '50%',
                  margin: '0 auto 8px auto',
                  overflow: 'hidden',
                  border: '2px solid #f59e0b',
                  boxShadow: '0 2px 8px rgba(0,0,0,0.15)'
                }}>
                  <img 
                    src="/zion_logo.png" 
                    alt="Zion Fellowship Church Logo" 
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }} 
                  />
                </div>

                <h1 style={{
                  fontFamily: 'var(--font-cinzel)',
                  fontSize: '1.45rem',
                  fontWeight: 900,
                  color: '#1e3a8a',
                  letterSpacing: '2px',
                  margin: '0 0 2px 0'
                }}>
                  {CHURCH_PROFILE.name}
                </h1>

                <div style={{
                  fontSize: '0.8rem',
                  fontWeight: 700,
                  color: '#d97706',
                  letterSpacing: '1px',
                  textTransform: 'uppercase'
                }}>
                  {CHURCH_PROFILE.motto}
                </div>

                <div style={{
                  fontSize: '0.75rem',
                  color: '#64748b',
                  marginBottom: '10px'
                }}>
                  {CHURCH_PROFILE.location} â€¢ {CHURCH_PROFILE.phone}
                </div>

                {/* Ribbon Title */}
                <div style={{
                  display: 'inline-block',
                  background: 'linear-gradient(135deg, #1e3a8a 0%, #1e40af 100%)',
                  color: '#ffffff',
                  padding: '6px 28px',
                  borderRadius: '20px',
                  border: '1.5px solid #f59e0b',
                  boxShadow: '0 4px 10px rgba(30, 58, 138, 0.2)'
                }}>
                  <span style={{
                    fontFamily: 'var(--font-cinzel)',
                    fontSize: '1rem',
                    fontWeight: 800,
                    letterSpacing: '1.5px',
                    color: '#fef3c7'
                  }}>
                    {certificateTitle(selectedType, language)}
                  </span>
                </div>
              </div>

              {/* Certificate Body */}
              <div style={{ textAlign: 'center', padding: '16px 20px', position: 'relative', zIndex: 2 }}>
                <p style={{ fontFamily: 'var(--font-scripture)', fontSize: '0.95rem', color: '#475569', fontStyle: 'italic', marginBottom: '8px' }}>
                  {isSw ? 'Hati hii inathibitisha kwamba:' : 'This certifies that:'}
                </p>

                {/* Recipient Name in Calligraphic Bold */}
                <div style={{
                  fontFamily: 'var(--font-cinzel)',
                  fontSize: '1.9rem',
                  fontWeight: 900,
                  color: '#1e3a8a',
                  borderBottom: '2px solid #f59e0b',
                  display: 'inline-block',
                  padding: '2px 35px',
                  margin: '4px 0 10px 0'
                }}>
                  {recipientName}
                </div>

                {selectedType === 'marriage' && (
                  <div style={{ fontSize: '1rem', color: '#334155', margin: '4px 0 8px 0' }}>
                    {isSw ? 'Na' : 'And'}{' '}
                    <strong style={{ fontFamily: 'var(--font-cinzel)', fontSize: '1.35rem', color: '#1e3a8a' }}>
                      {spouseName}
                    </strong>
                  </div>
                )}

                {selectedType === 'dedication' && (
                  <div style={{ fontSize: '0.88rem', color: '#475569', margin: '4px 0 8px 0' }}>
                    {isSw ? 'Mtoto wa' : 'Child of'}: <strong>{parentNames}</strong>
                  </div>
                )}

                <p style={{
                  maxWidth: '650px',
                  margin: '6px auto 14px auto',
                  fontSize: '0.88rem',
                  lineHeight: '1.5',
                  color: '#334155'
                }}>
                  {certificateBody(selectedType, language)}
                </p>

                {notes.trim() && (
                  <div style={{ fontSize: '0.72rem', color: '#64748b', marginBottom: '8px' }}>
                    <strong>{isSw ? 'Mahali / Maelezo' : 'Location / Notes'}:</strong> {notes}
                  </div>
                )}

                {/* Scripture Reference Quote */}
                <div style={{
                  fontFamily: 'var(--font-scripture)',
                  fontSize: '0.82rem',
                  fontStyle: 'italic',
                  color: '#64748b',
                  background: 'rgba(245, 158, 11, 0.08)',
                  padding: '6px 14px',
                  borderRadius: '6px',
                  display: 'inline-block',
                  maxWidth: '680px',
                  border: '1px solid rgba(245, 158, 11, 0.25)'
                }}>
                  "{scripture}"
                </div>
              </div>

              {/* Certificate Signatures & Official Seal Footer */}
              <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'flex-end',
                padding: '0 20px 8px 20px',
                position: 'relative',
                zIndex: 2
              }}>
                {/* Pastor Signature */}
                <div style={{ textAlign: 'center', width: '220px' }}>
                  <div style={{
                    fontFamily: "'Great Vibes', 'Dancing Script', cursive",
                    fontSize: '1.55rem',
                    color: '#0A2540',
                    height: '34px',
                    lineHeight: '34px',
                    marginBottom: '2px',
                    textShadow: '0 1px 1px rgba(0,0,0,0.08)'
                  }}>
                    Askofu Mercy James
                  </div>
                  <div style={{ borderBottom: '1.5px solid #0f172a', width: '100%', marginBottom: '4px' }} />
                  <div style={{ fontSize: '0.72rem', fontWeight: 800, color: '#1e3a8a', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                    {isSw ? 'Mchungaji Kiongozi' : 'Senior Pastor'}
                  </div>
                </div>

                {/* Official Church Seal */}
                <div style={{ textAlign: 'center' }}>
                  <div style={{
                    width: '84px',
                    height: '84px',
                    borderRadius: '50%',
                    border: '2.5px solid #c59b27',
                    background: 'radial-gradient(circle, #fffbf0 30%, #fef3c7 100%)',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '2px',
                    margin: '0 auto 4px auto',
                    boxShadow: '0 4px 12px rgba(197, 155, 39, 0.25), inset 0 0 0 2px rgba(197, 155, 39, 0.3)'
                  }}>
                    <span style={{ fontFamily: 'var(--font-cinzel)', fontSize: '0.92rem', fontWeight: 900, color: '#92400e', letterSpacing: '1px' }}>
                      ZJ
                    </span>
                    <span style={{ fontSize: '0.44rem', fontWeight: 800, color: '#b45309', letterSpacing: '0.6px', textTransform: 'uppercase', textAlign: 'center', lineHeight: 1.1 }}>
                      OFFICIAL SEAL
                    </span>
                  </div>
                  <div style={{ fontSize: '0.68rem', fontFamily: 'monospace', color: '#64748b', fontWeight: 600 }}>
                    {certificateSerial}
                  </div>
                </div>

                {/* Secretary Signature & Date */}
                <div style={{ textAlign: 'center', width: '220px' }}>
                  <div style={{
                    fontFamily: "'Great Vibes', 'Dancing Script', cursive",
                    fontSize: '1.55rem',
                    color: '#0A2540',
                    height: '34px',
                    lineHeight: '34px',
                    marginBottom: '2px',
                    textShadow: '0 1px 1px rgba(0,0,0,0.08)'
                  }}>
                    Sekretarieti ya Kanisa
                  </div>
                  <div style={{ borderBottom: '1.5px solid #0f172a', width: '100%', marginBottom: '4px' }} />
                  <div style={{ fontSize: '0.72rem', fontWeight: 800, color: '#1e3a8a', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                    {isSw ? 'Katibu wa Kanisa' : 'Church Secretary'}
                  </div>
                  <div style={{ fontSize: '0.68rem', color: '#64748b', marginTop: '2px' }}>
                    {isSw ? 'Tarehe ya Tukio:' : 'Event Date:'} {eventDate}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
