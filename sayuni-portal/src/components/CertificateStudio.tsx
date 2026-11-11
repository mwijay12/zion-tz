import React, { useState } from 'react';
import { AlertCircle, Award, Check, Download, FileEdit, Loader2, Palette } from 'lucide-react';
import type { Language, UserRole, CertificateType } from '../types';
import { CHURCH_PROFILE } from '../data/mockData';
import {
  CERTIFICATE_DEFINITIONS,
  CERTIFICATE_TYPE_ORDER,
  certificateBody,
  certificateTitle
} from '../data/certificateContent';
import {
  CERTIFICATE_DESIGNS,
  CERTIFICATE_VARIANT_ORDER,
  certificateCssVars,
  type CertificateVariant
} from '../data/certificateDesign';
import {
  createCertificateSerial,
  downloadCertificatePdf,
  formatCertificateDate
} from '../services/certificatePdfService';
import { loadStored, saveStored, STORAGE_KEYS } from '../utils/storage';

interface CertificateStudioProps {
  language: Language;
  userRole: UserRole;
}

function initialDesign(): CertificateVariant {
  const saved = loadStored<string>(STORAGE_KEYS.certificateDesign, 'classic');
  return saved === 'modern' ? 'modern' : 'classic';
}

export const CertificateStudio: React.FC<CertificateStudioProps> = ({ language }) => {
  const isSw = language === 'sw';
  const today = new Date();
  const issuedLabel = formatCertificateDate(
    `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`,
    language
  );

  const [variant, setVariant] = useState<CertificateVariant>(initialDesign);
  const [selectedType, setSelectedType] = useState<CertificateType>('baptism');

  const [recipientName, setRecipientName] = useState('');
  const [spouseName, setSpouseName] = useState('');
  const [parentNames, setParentNames] = useState('');
  const [eventDate, setEventDate] = useState('2026-08-16');
  const [scripture, setScripture] = useState(CERTIFICATE_DEFINITIONS.baptism.defaultVerse);
  const [notes, setNotes] = useState('Ubatizo wa maji tele katika Mto Ruvu.');
  const [certificateSerial, setCertificateSerial] = useState(() => createCertificateSerial('baptism'));
  const [isGenerating, setIsGenerating] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const eventDateLabel = formatCertificateDate(eventDate, language);
  const design = CERTIFICATE_DESIGNS[variant];

  const handleTypeChange = (type: CertificateType) => {
    setSelectedType(type);
    setScripture(CERTIFICATE_DEFINITIONS[type].defaultVerse);
    setCertificateSerial(createCertificateSerial(type));
    setFormError(null);
  };

  const handleVariantChange = (next: CertificateVariant) => {
    setVariant(next);
    saveStored(STORAGE_KEYS.certificateDesign, next);
  };

  const handleDownload = async () => {
    const missingFields: string[] = [];

    if (!recipientName.trim()) missingFields.push(isSw ? 'jina la mpokeaji' : 'recipient name');
    if (!eventDate) missingFields.push(isSw ? 'tarehe ya tukio' : 'event date');
    if (selectedType === 'marriage' && !spouseName.trim()) {
      missingFields.push(isSw ? 'jina la mwanandoa' : 'spouse name');
    }
    if (selectedType === 'dedication' && !parentNames.trim()) {
      missingFields.push(isSw ? 'majina ya wazazi' : 'parents names');
    }

    if (missingFields.length > 0) {
      setFormError(`${isSw ? 'Tafadhali jaza' : 'Please fill in'} ${missingFields.join(', ')}.`);
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
        language,
        variant
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

  const metaItems = [
    { label: isSw ? 'Imetolewa' : 'Issued', value: issuedLabel },
    { label: isSw ? 'Tarehe ya Tukio' : 'Date of Event', value: eventDateLabel },
    { label: isSw ? 'Namba ya Uthibitisho' : 'Verification No.', value: certificateSerial }
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Top Header */}
      <div className="no-print" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <span className="badge badge-purple" style={{ marginBottom: '0.35rem', display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
            <Award size={13} />
            <span>{isSw ? 'Utoaji wa Nyaraka Rasmi' : 'Official Credentials Studio'}</span>
          </span>
          <h2 style={{ fontFamily: "'Cinzel', Georgia, serif", fontSize: '1.65rem', fontWeight: 800, color: 'var(--text-headline)' }}>
            {isSw ? 'Studio ya Kutengeneza Vyeti vya Kanisa' : 'Church Certificate Studio'}
          </h2>
        </div>

        <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center', flexWrap: 'wrap' }}>
          <span className="badge badge-gold" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
            {isSw ? 'PDF ya Vekta • A4 Landscape' : 'Vector PDF • A4 Landscape'}
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

      {/* Design picker: two serious, two-colour layouts with blank physical signing lines. */}
      <div className="church-card no-print cert-design-card">
        <div className="cert-design-head">
          <div style={{ minWidth: 0, flex: '1 1 300px' }}>
            <div className="cert-design-title">
              <Palette size={16} style={{ color: 'var(--primary)' }} />
              <span>{isSw ? 'Muundo wa Cheti' : 'Certificate Design'}</span>
            </div>
            <p className="cert-design-desc">
              {isSw
                ? 'Chagua muundo rasmi. Yote miwili ina mistari miwili tupu ya kusainiwa kwa mkono, haina saini iliyochapishwa wala muhuri, na inalingana kabisa na PDF.'
                : 'Choose an official layout. Both keep two blank lines for physical signing, print no signature or seal, and match the downloaded PDF exactly.'}
            </p>
          </div>
          <span className="cert-design-count">{isSw ? 'Miundo 2' : '2 designs'}</span>
        </div>

        <div className="cert-design-options">
          {CERTIFICATE_VARIANT_ORDER.map((id) => {
            const option = CERTIFICATE_DESIGNS[id];
            const active = id === variant;
            return (
              <button
                key={id}
                type="button"
                className={`cert-design-option ${active ? 'is-active' : ''}`}
                onClick={() => handleVariantChange(id)}
                aria-pressed={active}
                style={{ '--swatch-paper': option.palette.paper, '--swatch-ink': option.palette.ink, '--swatch-accent': option.palette.accent } as React.CSSProperties}
              >
                <span className={`cert-design-swatch cert-design-swatch--${id}`} aria-hidden="true">
                  <span className="cert-design-swatch-frame" />
                  <span className="cert-design-swatch-line" />
                  <span className="cert-design-swatch-line cert-design-swatch-line--short" />
                  <span className="cert-design-swatch-name" />
                  <span className="cert-design-swatch-rule" />
                </span>
                <span className="cert-design-copy">
                  <strong>{isSw ? option.labelSw : option.labelEn}</strong>
                  <small>{isSw ? option.descriptionSw : option.descriptionEn}</small>
                </span>
                <span className="cert-design-check" aria-hidden="true">
                  {active && <Check size={14} strokeWidth={3} />}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Studio Layout: Left Controls + Right Live Preview */}
      <div className="cert-studio-grid">
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
                display: 'flex', alignItems: 'flex-start', gap: '0.5rem', padding: '0.7rem 0.8rem',
                borderRadius: '8px', background: 'var(--error-container)', color: 'var(--error)',
                fontSize: '0.8rem', lineHeight: 1.45
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
            <input type="date" className="form-input" value={eventDate} onChange={(e) => setEventDate(e.target.value)} />
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
              ? `PDF ya vekta (A4 landscape) · Muundo: ${design.labelSw} · Mistari ya kusainiwa kwa mkono, hakuna muhuri.`
              : `Vector PDF (A4 landscape) · Design: ${design.labelEn} · Blank signing lines, no seal.`}
          </p>
        </div>

        {/* Right Live Preview — matches the PDF for the chosen design */}
        <div className="certificate-preview-scroll-wrapper">
          <div
            className="certificate-render-wrapper cert-sheet"
            data-variant={variant}
            style={certificateCssVars(variant) as React.CSSProperties}
          >
            <div className="cert-frame" aria-hidden="true">
              <span className="cert-corner cert-corner--tl" />
              <span className="cert-corner cert-corner--tr" />
              <span className="cert-corner cert-corner--bl" />
              <span className="cert-corner cert-corner--br" />
            </div>
            <div className="cert-edge" aria-hidden="true" />
            <div className="cert-masthead" aria-hidden="true">
              <div className="cert-masthead-mark">
                <img src="/zion_logo.png" alt="" width={54} height={54} />
              </div>
              <div className="cert-masthead-text">
                <strong>{CHURCH_PROFILE.name}</strong>
                <span>{isSw ? CHURCH_PROFILE.motto : CHURCH_PROFILE.mottoEn}</span>
                <small>{CHURCH_PROFILE.location} • {CHURCH_PROFILE.phone}</small>
              </div>
              <div className="cert-masthead-tag">
                {isSw ? 'Hati Rasmi ya Kanisa' : 'Official Church Document'}<br />{isSw ? 'Sayuni Yerusalemu' : 'Zion Jerusalem'}
              </div>
            </div>
            <img className="cert-watermark" src="/zion_logo.png" alt="" aria-hidden="true" width={300} height={300} />

            <div className="cert-inner">
              <header className="cert-header">
                <div className="cert-brand">
                  <div className="cert-logo">
                    <img src="/zion_logo.png" alt={CHURCH_PROFILE.name} width={54} height={54} />
                  </div>
                  <div className="cert-brand-text">
                    <div className="cert-church-name">{CHURCH_PROFILE.name}</div>
                    <div className="cert-motto">{isSw ? CHURCH_PROFILE.motto : CHURCH_PROFILE.mottoEn}</div>
                    <div className="cert-contact">{CHURCH_PROFILE.location} • {CHURCH_PROFILE.phone}</div>
                  </div>
                </div>
                <div className="cert-rule"><i /></div>
                <div className="cert-eyebrow">
                  {variant === 'modern'
                    ? (isSw ? 'Hati Rasmi' : 'Official Document')
                    : (isSw ? 'Hati Rasmi ya Kanisa' : 'Official Church Document')}
                </div>
                <h1 className="cert-title">{certificateTitle(selectedType, language)}</h1>
                <div className="cert-rule cert-rule--short"><i /></div>
              </header>

              <div className="cert-body">
                <p className="cert-intro">
                  {isSw ? 'Hati hii inathibitisha kwamba:' : 'This certifies that:'}
                </p>
                <div className="cert-name">
                  {recipientName.trim() || (isSw ? 'Jina la Mpokeaji' : 'Recipient Name')}
                </div>

                {selectedType === 'marriage' && (
                  <div className="cert-subline">
                    {isSw ? 'Na' : 'And'} <strong>{spouseName.trim() || '—'}</strong>
                  </div>
                )}
                {selectedType === 'dedication' && (
                  <div className="cert-subline">
                    {isSw ? 'Mtoto wa' : 'Child of'}: <strong>{parentNames.trim() || '—'}</strong>
                  </div>
                )}

                <p className="cert-text">{certificateBody(selectedType, language)}</p>

                {notes.trim() && (
                  <div className="cert-notes">
                    <strong>{isSw ? 'Mahali / Maelezo' : 'Location / Notes'}:</strong> {notes}
                  </div>
                )}

                <div className="cert-verse">“{scripture.replace(/"/g, '')}”</div>
              </div>

              <footer className="cert-footer">
                <div className="cert-rule cert-rule--full"><i /></div>
                <div className="cert-sign-grid">
                  <div className="cert-sign">
                    <span className="cert-sign-line" />
                    <span className="cert-sign-role">{isSw ? 'Mchungaji Kiongozi' : 'Senior Pastor'}</span>
                    <span className="cert-sign-sub">{isSw ? 'Saini ya mkono' : 'Signed by hand'}</span>
                  </div>
                  <div className="cert-sign">
                    <span className="cert-sign-line" />
                    <span className="cert-sign-role">{isSw ? 'Katibu wa Kanisa' : 'Church Secretary'}</span>
                    <span className="cert-sign-sub">{isSw ? 'Saini ya mkono' : 'Signed by hand'}</span>
                  </div>
                </div>
                <div className="cert-meta">
                  {metaItems.map((item) => (
                    <div className="cert-meta-item" key={item.label}>
                      <span className="cert-meta-label">{item.label}</span>
                      <span className="cert-meta-value">{item.value}</span>
                    </div>
                  ))}
                </div>
                <div className="cert-bottom">
                  <span>{CHURCH_PROFILE.name}</span>
                  <span>{CHURCH_PROFILE.email} • {CHURCH_PROFILE.phone}</span>
                  <span>{isSw ? 'Hati Rasmi' : 'Official Document'}</span>
                </div>
              </footer>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
