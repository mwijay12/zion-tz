import React, { useState } from 'react';
import { 
  Award, 
  Printer, 
  FileEdit
} from 'lucide-react';
import confetti from 'canvas-confetti';
import type { Language, UserRole, CertificateType } from '../types';
import { CHURCH_PROFILE } from '../data/mockData';

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
  const [minister, setMinister] = useState(CHURCH_PROFILE.headPastor);
  const [secretary, setSecretary] = useState(CHURCH_PROFILE.churchSecretary);
  const [scripture, setScripture] = useState(
    'Matendo ya Mitume 2:38 - "Tubuni mkabatizwe kila mmoja kwa jina lake Yesu Kristo mpate ondoleo la dhambi zenu"'
  );
  const [notes, setNotes] = useState('Ubatizo wa maji tele katika Mto Ruvu.');

  const certTypeTitles: Record<CertificateType, { sw: string; en: string; defaultVerse: string }> = {
    baptism: {
      sw: 'CHETI CHA UBATIZO WA MAJI TELE',
      en: 'CERTIFICATE OF HOLY BAPTISM',
      defaultVerse: 'Warumi 6:4 - "Basi tulizikwa pamoja naye kwa njia ya ubatizo katika mauti yake..."'
    },
    dedication: {
      sw: 'CHETI CHA WAKFU WA MTOTO',
      en: 'CERTIFICATE OF CHILD DEDICATION',
      defaultVerse: '1 Samweli 1:27-28 - "Naliomba mtoto huyu; Bwana akanipa dua yangu niliyomwomba..."'
    },
    marriage: {
      sw: 'CHETI CHA NDOA TAKATIFU',
      en: 'CERTIFICATE OF HOLY MATRIMONY',
      defaultVerse: 'Mathayo 19:6 - "Hata wamekuwa si wawili tena bali mwili mmoja. Basi alichokiunganisha Mungu, mwanadamu asikitenganishe."'
    },
    membership: {
      sw: 'CHETI CHA USHIRIKA KAMILI WA KANISA',
      en: 'CERTIFICATE OF FULL CHURCH MEMBERSHIP',
      defaultVerse: 'Waefeso 2:19 - "Basi tangu sasa ninyi si wageni wala wapitaji, bali ninyi ni wenyeji pamoja na watakatifu..."'
    },
    service: {
      sw: 'CHETI CHA SHUKRANI NA UTUMISHI MWEMA',
      en: 'CERTIFICATE OF APPRECIATION & SERVICE',
      defaultVerse: '1 Wakorintho 15:58 - "Basi, ndugu zangu wapendwa, mwimarike, msitikisike, mkizidi sana kutenda kazi ya Bwana sikuzote..."'
    }
  };

  const handleTypeChange = (type: CertificateType) => {
    setSelectedType(type);
    setScripture(certTypeTitles[type].defaultVerse);
  };

  const handlePrint = () => {
    // Explicitly remove any active celebration canvas particles before print dialog
    document.querySelectorAll('canvas').forEach((c) => c.remove());
    window.print();
  };

  const handleCelebrate = () => {
    confetti({
      particleCount: 90,
      spread: 75,
      origin: { y: 0.6 }
    });
  };

  const currentSerial = `ZJ-${selectedType.slice(0, 3).toUpperCase()}-2026-0089`;

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

        <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
          <button 
            type="button"
            onClick={handleCelebrate}
            className="btn-secondary"
            title={isSw ? 'Onyesha Sherehekea kwenye Skrini' : 'Celebrate on Screen'}
            style={{ padding: '0.65rem 1rem' }}
          >
            🎉 {isSw ? 'Sherehekea' : 'Celebrate'}
          </button>

          <button 
            onClick={handlePrint}
            className="btn-primary"
            style={{ padding: '0.65rem 1.4rem' }}
          >
            <Printer size={18} />
            <span>{isSw ? 'Chapisha Cheti (A4 Landscape / PDF)' : 'Print / Save as PDF'}</span>
          </button>
        </div>
      </div>

      {/* Type Selector Tabs */}
      <div className="no-print" style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem', borderBottom: '1px solid var(--border-subtle)', paddingBottom: '0.75rem' }}>
        {(['baptism', 'dedication', 'marriage', 'membership', 'service'] as CertificateType[]).map((type) => (
          <button
            key={type}
            onClick={() => handleTypeChange(type)}
            className={`nav-item ${selectedType === type ? 'active' : ''}`}
            style={{ padding: '0.5rem 1.1rem', fontSize: '0.86rem' }}
          >
            <Award size={15} />
            <span>{isSw ? certTypeTitles[type].sw.replace('CHETI CHA ', '') : certTypeTitles[type].en.replace('CERTIFICATE OF ', '')}</span>
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

          <div className="form-group">
            <label className="form-label">{isSw ? 'Jina Kamili la Mpokeaji' : 'Recipient Full Name'}</label>
            <input 
              type="text" 
              className="form-input"
              value={recipientName}
              onChange={(e) => setRecipientName(e.target.value)}
              placeholder="Mfano: Neema J. Mwakyusa"
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
            <label className="form-label">{isSw ? 'Mchungaji Kiongozi' : 'Officiating Minister'}</label>
            <input 
              type="text" 
              className="form-input"
              value={minister}
              onChange={(e) => setMinister(e.target.value)}
            />
          </div>

          <div className="form-group">
            <label className="form-label">{isSw ? 'Katibu wa Kanisa' : 'Church Secretary'}</label>
            <input 
              type="text" 
              className="form-input"
              value={secretary}
              onChange={(e) => setSecretary(e.target.value)}
            />
          </div>

          <div className="form-group">
            <label className="form-label">{isSw ? 'Fungu la Biblia' : 'Scripture Verse'}</label>
            <textarea 
              className="form-textarea"
              rows={3}
              value={scripture}
              onChange={(e) => setScripture(e.target.value)}
            />
          </div>

          <div className="form-group">
            <label className="form-label">{isSw ? 'Maelezo ya Ziada / Mahali' : 'Location / Special Notes'}</label>
            <input 
              type="text" 
              className="form-input"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
          </div>

          <button 
            onClick={handlePrint}
            className="btn-gold" 
            style={{ width: '100%', marginTop: '0.5rem' }}
          >
            <Printer size={16} />
            <span>{isSw ? 'Chapisha Cheti Sasa' : 'Print Certificate Now'}</span>
          </button>
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
                  {CHURCH_PROFILE.location} • {CHURCH_PROFILE.phone}
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
                    {isSw ? certTypeTitles[selectedType].sw : certTypeTitles[selectedType].en}
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
                  {selectedType === 'baptism' && (
                    isSw 
                      ? 'Amepokea ubatizo wa maji tele kulingana na agizo la Bwana wetu Yesu Kristo na mafundisho ya Maandiko Matakatifu.'
                      : 'Has received holy water baptism in obedience to our Lord Jesus Christ and the teachings of the Holy Scriptures.'
                  )}
                  {selectedType === 'dedication' && (
                    isSw 
                      ? 'Amewekwa wakfu mbele za Bwana Mungu na kusanyiko la watakatifu, kwa maombi na baraka za kiuchungaji.'
                      : 'Has been dedicated unto the Lord God before the congregation, through prayer and pastoral blessings.'
                  )}
                  {selectedType === 'marriage' && (
                    isSw 
                      ? 'Wameunganishwa katika Ndoa Takatifu mbele za Mungu na mashahidi wengi kwa mujibu wa Neno la Mungu.'
                      : 'Have been united in Holy Matrimony before God and witnesses in accordance with the Word of God.'
                  )}
                  {selectedType === 'membership' && (
                    isSw 
                      ? 'Ametambuliwa rasmi kama mshirika kamili wa Kanisa la Sayuni Yerusalemu mwenye haki na wajibu wote wa kiroho.'
                      : 'Has been recognized as a full registered member of Zion Jerusalem Church with all spiritual fellowship privileges.'
                  )}
                  {selectedType === 'service' && (
                    isSw 
                      ? 'Kwa kutambua utumishi wake mwema, uaminifu, na kujitolea kwa dhati katika ujenzi wa ufalme wa Mungu.'
                      : 'In grateful recognition of faithful service, dedication, and steadfast contribution to the kingdom of God.'
                  )}
                </p>

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
                <div style={{ textAlign: 'center', width: '180px' }}>
                  <div style={{ fontFamily: 'var(--font-scripture)', fontStyle: 'italic', color: '#1e3a8a', fontSize: '0.9rem', marginBottom: '4px' }}>
                    {minister}
                  </div>
                  <div style={{ borderBottom: '1.5px solid #0f172a', width: '100%', marginBottom: '4px' }} />
                  <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#1e3a8a', textTransform: 'uppercase' }}>
                    {isSw ? 'Mchungaji Kiongozi' : 'Senior Pastor'}
                  </div>
                </div>

                {/* Golden Seal of Zion Jerusalem */}
                <div style={{ textAlign: 'center' }}>
                  <div style={{
                    width: '66px',
                    height: '66px',
                    borderRadius: '50%',
                    border: '3px dashed #d97706',
                    background: 'radial-gradient(circle, #fef3c7 0%, #fde68a 100%)',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 0 12px rgba(217, 119, 6, 0.3)',
                    margin: '0 auto 4px auto'
                  }}>
                    <Award size={22} style={{ color: '#b45309' }} />
                    <span style={{ fontSize: '0.48rem', fontWeight: 800, color: '#78350f', letterSpacing: '0.5px' }}>
                      OFFICIAL SEAL
                    </span>
                  </div>
                  <div style={{ fontSize: '0.68rem', fontFamily: 'monospace', color: '#64748b' }}>
                    {currentSerial}
                  </div>
                </div>

                {/* Secretary Signature & Date */}
                <div style={{ textAlign: 'center', width: '180px' }}>
                  <div style={{ fontFamily: 'var(--font-scripture)', fontStyle: 'italic', color: '#1e3a8a', fontSize: '0.9rem', marginBottom: '4px' }}>
                    {secretary}
                  </div>
                  <div style={{ borderBottom: '1.5px solid #0f172a', width: '100%', marginBottom: '4px' }} />
                  <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#1e3a8a', textTransform: 'uppercase' }}>
                    {isSw ? 'Katibu wa Kanisa' : 'Church Secretary'}
                  </div>
                  <div style={{ fontSize: '0.68rem', color: '#64748b', marginTop: '2px' }}>
                    {isSw ? 'Tarehe:' : 'Date:'} {eventDate}
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
