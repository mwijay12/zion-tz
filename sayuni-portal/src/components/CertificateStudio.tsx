import React, { useState } from 'react';
import {
  AlertCircle,
  Award,
  Download,
  FileEdit,
  ImagePlus,
  Loader2,
  PenLine,
  Settings2,
  Trash2
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
  downloadCertificatePdf,
  formatCertificateDate
} from '../services/certificatePdfService';
import {
  loadCertificateSettings,
  readSignatureImage,
  saveCertificateSettings,
  type CertificateSettings
} from '../services/certificateSettingsService';


interface SignatureUploadProps {
  label: string;
  hint: string;
  value: string | null;
  isSw: boolean;
  onChange: (file?: File | null) => void;
  onRemove: () => void;
}

const SignatureUpload: React.FC<SignatureUploadProps> = ({
  label,
  hint,
  value,
  isSw,
  onChange,
  onRemove
}) => (
  <div className="cert-upload">
    <div className="cert-upload-label">
      {label}
      <small>{hint}</small>
    </div>
    <div className="cert-upload-row">
      {value ? (
        <>
          <img className="cert-upload-thumb" src={value} alt="" />
          <button
            type="button"
            className="nav-item"
            onClick={onRemove}
            style={{ fontSize: '0.74rem', padding: '0.35rem 0.8rem' }}
          >
            <Trash2 size={13} />
            <span>{isSw ? 'Ondoa' : 'Remove'}</span>
          </button>
        </>
      ) : (
        <span className="cert-empty-mark">
          {isSw ? 'Hakuna saini — mstari tupu unachapishwa' : 'No signature — a blank line is printed'}
        </span>
      )}
    </div>
    <label className="cert-upload-row" style={{ cursor: 'pointer' }}>
      <ImagePlus size={14} style={{ color: 'var(--primary)' }} />
      <span style={{ fontSize: '0.74rem', fontWeight: 700, color: 'var(--primary)' }}>
        {isSw ? 'Chagua picha (PNG / JPG, max 1.5 MB)' : 'Choose image (PNG / JPG, max 1.5 MB)'}
      </span>
      <input
        type="file"
        accept="image/png,image/jpeg"
        className="cert-file-input"
        onChange={(event) => {
          onChange(event.target.files?.[0]);
          event.target.value = '';
        }}
      />
    </label>
  </div>
);

interface CertificateStudioProps {
  language: Language;
  userRole: UserRole;
}

export const CertificateStudio: React.FC<CertificateStudioProps> = ({
  language
}) => {
  const isSw = language === 'sw';
  const today = new Date();
  const issuedLabel = formatCertificateDate(
    `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`,
    language
  );
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
  const [settings, setSettings] = useState<CertificateSettings>(() => loadCertificateSettings());
  const [showSignatureSettings, setShowSignatureSettings] = useState(false);
  const [signatureError, setSignatureError] = useState<string | null>(null);

  const handleTypeChange = (type: CertificateType) => {
    setSelectedType(type);
    setScripture(CERTIFICATE_DEFINITIONS[type].defaultVerse);
    setCertificateSerial(createCertificateSerial(type));
    setFormError(null);
  };


  const updateSignature = async (key: keyof CertificateSettings, file?: File | null) => {
    if (!file) return;
    setSignatureError(null);
    try {
      const dataUrl = await readSignatureImage(file);
      const next: CertificateSettings =
        key === 'pastorSignature'
          ? { ...settings, pastorSignature: dataUrl }
          : { ...settings, secretarySignature: dataUrl };
      setSettings(next);
      saveCertificateSettings(next);
    } catch (error) {
      setSignatureError(
        error instanceof Error && error.message === 'too-large'
          ? (isSw ? 'Picha ni kubwa mno (kikomo 1.5 MB).' : 'Image is too large (1.5 MB limit).')
          : (isSw ? 'Tumia picha ya PNG au JPG.' : 'Please use a PNG or JPG image.')
      );
    }
  };

  const removeSignature = (key: keyof CertificateSettings) => {
    const next: CertificateSettings =
      key === 'pastorSignature'
        ? { ...settings, pastorSignature: null }
        : { ...settings, secretarySignature: null };
    setSettings(next);
    saveCertificateSettings(next);
    setSignatureError(null);
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
        language,
        pastorSignature: settings.pastorSignature,
        secretarySignature: settings.secretarySignature
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

      {/* Optional signature settings: blank physical lines by default */}
      <div className="church-card no-print cert-settings-card">
        <div className="cert-settings-head">
          <div style={{ minWidth: 0, flex: '1 1 320px' }}>
            <div className="cert-settings-title">
              <Settings2 size={16} style={{ color: 'var(--primary)' }} />
              <span>{isSw ? 'Mipangilio ya Saini za Vyeti' : 'Certificate Signature Settings'}</span>
            </div>
            <p className="cert-settings-desc">
              {isSw
                ? 'Kwa sasa vyeti HAVINA saini iliyochapishwa — kuna mstari tupu wa kusainiwa kwa mkono. Ukitaka saini ionekane, pakia picha hapa (inahifadhiwa kwenye kifaa hiki tu).'
                : 'Certificates currently print NO signature — just a clean line for signing by hand. If you want one printed, upload an image here (stored on this device only).'}
            </p>
          </div>
          <button
            type="button"
            className={`nav-item ${showSignatureSettings ? 'active' : ''}`}
            onClick={() => setShowSignatureSettings((open) => !open)}
            style={{ fontSize: '0.8rem', padding: '0.45rem 0.95rem', whiteSpace: 'nowrap' }}
          >
            <PenLine size={14} />
            <span>
              {showSignatureSettings
                ? (isSw ? 'Funga' : 'Hide')
                : (isSw ? 'Ongeza saini' : 'Add signature')}
            </span>
          </button>
        </div>

        {showSignatureSettings && (
          <div className="cert-settings-body">
            <SignatureUpload
              label={isSw ? 'Saini ya Mchungaji Kiongozi' : 'Senior Pastor Signature'}
              hint={isSw ? 'Upande wa kushoto wa cheti' : 'Left side of the certificate'}
              value={settings.pastorSignature}
              isSw={isSw}
              onChange={(file) => void updateSignature('pastorSignature', file)}
              onRemove={() => removeSignature('pastorSignature')}
            />
            <SignatureUpload
              label={isSw ? 'Saini ya Katibu wa Kanisa' : 'Church Secretary Signature'}
              hint={isSw ? 'Upande wa kulia wa cheti' : 'Right side of the certificate'}
              value={settings.secretarySignature}
              isSw={isSw}
              onChange={(file) => void updateSignature('secretarySignature', file)}
              onRemove={() => removeSignature('secretarySignature')}
            />
            {signatureError && (
              <div className="cert-settings-error" role="alert" style={{ gridColumn: '1 / -1' }}>
                {signatureError}
              </div>
            )}
            <div className="cert-settings-note" style={{ gridColumn: '1 / -1' }}>
              <PenLine size={14} style={{ flexShrink: 0, marginTop: '2px' }} />
              <span>
                {isSw
                  ? 'Ukiacha sehemu hizi wazi, PDF na onyesho vitakuwa na mistari miwili tupu tu ya kusainiwa kimwili baada ya kuchapisha.'
                  : 'Leave these empty and both the preview and the PDF keep two blank lines to be signed physically after printing.'}
              </span>
            </div>
          </div>
        )}
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

        {/* Right Live Preview — refined engraved certificate, no printed signature */}
        <div className="certificate-preview-scroll-wrapper">
          <div className="certificate-render-wrapper cert-sheet">
            <div className="cert-frame" aria-hidden="true">
              <span className="cert-corner cert-corner--tl" />
              <span className="cert-corner cert-corner--tr" />
              <span className="cert-corner cert-corner--bl" />
              <span className="cert-corner cert-corner--br" />
            </div>
            <img className="cert-watermark" src="/zion_logo.png" alt="" aria-hidden="true" />

            <div className="cert-inner">
              <header className="cert-header">
                <div className="cert-logo">
                  <img src="/zion_logo.png" alt="Zion Jerusalem Church" />
                </div>
                <div className="cert-church-name">{CHURCH_PROFILE.name}</div>
                <div className="cert-motto">{CHURCH_PROFILE.motto}</div>
                <div className="cert-contact">
                  {CHURCH_PROFILE.location} • {CHURCH_PROFILE.phone}
                </div>
                <div className="cert-rule"><i /></div>
                <div className="cert-eyebrow">
                  {isSw ? 'Hati Rasmi ya Kanisa' : 'Official Church Document'}
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
                <div className="cert-sign">
                  <div className="cert-sign-space">
                    {settings.pastorSignature ? (
                      <img className="cert-sign-img" src={settings.pastorSignature} alt="" />
                    ) : (
                      <span className="cert-sign-hint">{isSw ? 'Saini hapa' : 'Sign here'}</span>
                    )}
                  </div>
                  <div className="cert-sign-role">{isSw ? 'Mchungaji Kiongozi' : 'Senior Pastor'}</div>
                  <div className="cert-sign-sub">{isSw ? 'Kusainiwa kwa mkono' : 'To be signed by hand'}</div>
                </div>

                <div className="cert-seal-wrap">
                  <div className="cert-seal">
                    <span className="cert-seal-monogram">ZJ</span>
                    <span className="cert-seal-label">{isSw ? 'Muhuri Rasmi' : 'Official Seal'}</span>
                    <span className="cert-seal-place">Mbagala HQ</span>
                  </div>
                  <div className="cert-serial">{certificateSerial}</div>
                </div>

                <div className="cert-sign">
                  <div className="cert-sign-space">
                    {settings.secretarySignature ? (
                      <img className="cert-sign-img" src={settings.secretarySignature} alt="" />
                    ) : (
                      <span className="cert-sign-hint">{isSw ? 'Saini hapa' : 'Sign here'}</span>
                    )}
                  </div>
                  <div className="cert-sign-role">{isSw ? 'Katibu wa Kanisa' : 'Church Secretary'}</div>
                  <div className="cert-sign-sub">
                    {isSw ? 'Tarehe ya Tukio' : 'Event Date'}: {eventDate}
                  </div>
                </div>
              </footer>

              <div className="cert-bottom">
                <span>{isSw ? 'Imetolewa' : 'Issued'}: {issuedLabel}</span>
                <span>{CHURCH_PROFILE.email}</span>
                <span>{isSw ? 'Namba ya uthibitisho' : 'Verification No.'}: {certificateSerial}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
