import React, { useState } from 'react';
import { 
  Share2, 
  Copy, 
  Check, 
  Volume2, 
  VolumeX, 
  RefreshCw, 
  Church,
  BookOpen,
  Heart,
  MapPin
} from 'lucide-react';
import type { Language, UserRole } from '../types';
import { DEVOTIONAL_VERSES, CHURCH_PROFILE } from '../data/mockData';

interface DailyDevotionalProps {
  language: Language;
  userRole: UserRole;
}

export const DailyDevotional: React.FC<DailyDevotionalProps> = ({
  language
}) => {
  const isSw = language === 'sw';
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [currentIndex, setCurrentIndex] = useState<number>(0);
  const [isCopied, setIsCopied] = useState<boolean>(false);
  const [isSpeaking, setIsSpeaking] = useState<boolean>(false);

  const categories = ['All', 'Imani', 'Amani', 'Uponyaji', 'Ushindi', 'Matumaini'];

  const filteredVerses = selectedCategory === 'All'
    ? DEVOTIONAL_VERSES
    : DEVOTIONAL_VERSES.filter(v => v.category === selectedCategory);

  const currentDevo = filteredVerses[currentIndex] || DEVOTIONAL_VERSES[0];

  const handleNextRandom = () => {
    if (filteredVerses.length <= 1) return;
    let nextIdx = currentIndex;
    do {
      nextIdx = Math.floor(Math.random() * filteredVerses.length);
    } while (nextIdx === currentIndex);
    setCurrentIndex(nextIdx);
    if (isSpeaking) {
      window.speechSynthesis.cancel();
      setIsSpeaking(false);
    }
  };

  const handleCopyStatus = () => {
    const shareText = `*NENO LA SIKU - ZION FELLOWSHIP CHURCH*\n\n"${currentDevo.swahiliText}"\n— ${currentDevo.reference}\n\n*Tafakari ya Kichungaji:*\n${currentDevo.pastoralReflection}\n\n*Sala:*\n${currentDevo.prayer}\n\nZion Fellowship Church (Mbagala Kwa Matope, Dar es Salaam)`;
    
    navigator.clipboard.writeText(shareText);
    setIsCopied(true);
    setTimeout(() => setIsCopied(false), 2000);
  };

  const handleNativeShare = () => {
    if (navigator.share) {
      navigator.share({
        title: `Neno la Siku - ${currentDevo.reference}`,
        text: `"${currentDevo.swahiliText}" - ${currentDevo.reference} (Zion Jerusalem Church)`
      }).catch(() => handleCopyStatus());
    } else {
      handleCopyStatus();
    }
  };

  const toggleSpeak = () => {
    if ('speechSynthesis' in window) {
      if (isSpeaking) {
        window.speechSynthesis.cancel();
        setIsSpeaking(false);
        return;
      }

      const text = `${currentDevo.swahiliText}. Kutoka ${currentDevo.reference}. Tafakari: ${currentDevo.pastoralReflection}. Sala: ${currentDevo.prayer}`;
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'sw-TZ';
      utterance.rate = 0.95;

      utterance.onend = () => setIsSpeaking(false);
      utterance.onerror = () => setIsSpeaking(false);

      setIsSpeaking(true);
      window.speechSynthesis.speak(utterance);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', maxWidth: '1000px', margin: '0 auto' }}>
      {/* Title & Action Bar */}
      <div style={{ textAlign: 'center' }}>
        <span className="badge badge-purple" style={{ marginBottom: '0.5rem', display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
          <BookOpen size={13} />
          <span>{isSw ? 'Chakula cha Kiroho cha Kila Siku' : 'Daily Spiritual Food'}</span>
        </span>
        <h2 style={{ fontFamily: 'var(--font-cinzel)', fontSize: '1.85rem', fontWeight: 900, color: 'var(--text-headline)' }}>
          {isSw ? 'Neno la Siku & Tafakari ya Uzima' : 'Verse of the Day & Devotion'}
        </h2>
        <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', maxWidth: '600px', margin: '0.35rem auto 0 auto' }}>
          {isSw 
            ? 'Pata faraja, mwongozo, na neno la ushindi kwa ajili ya siku ya leo. Shiriki Neno na ndugu, marafiki na kwenye WhatsApp Status.'
            : 'Find comfort, guidance, and spiritual victory for today. Share with friends on WhatsApp status.'}
        </p>
      </div>

      {/* Categories Filter Pills */}
      <div style={{ display: 'flex', justifyContent: 'center', flexWrap: 'wrap', gap: '0.45rem' }}>
        {categories.map((cat) => (
          <button
            key={cat}
            onClick={() => {
              setSelectedCategory(cat);
              setCurrentIndex(0);
            }}
            className={`nav-item ${selectedCategory === cat ? 'active' : ''}`}
            style={{ padding: '0.4rem 1rem', fontSize: '0.82rem' }}
          >
            {cat === 'All' ? (isSw ? 'Yote' : 'All') : cat}
          </button>
        ))}
      </div>

      {/* Main Devotion Card + WhatsApp Card Generator Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '1.5rem', alignItems: 'stretch' }}>
        {/* Left: Interactive Devotional Card */}
        <div className="church-card gold-border" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '1.5rem', padding: '2rem' }}>
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
              <span className="badge badge-purple">
                {currentDevo.category}
              </span>
              <button 
                onClick={handleNextRandom} 
                className="btn-secondary"
                style={{ padding: '0.35rem 0.75rem', fontSize: '0.78rem' }}
                title={isSw ? 'Badili Fungu' : 'Next Verse'}
              >
                <RefreshCw size={13} />
                <span>{isSw ? 'Fungu Jingine' : 'Shuffle'}</span>
              </button>
            </div>

            {/* Scripture Quote */}
            <blockquote style={{
              fontFamily: 'var(--font-scripture)',
              fontSize: '1.25rem',
              lineHeight: '1.7',
              color: 'var(--text-headline)',
              fontStyle: 'italic',
              borderLeft: '4px solid var(--primary)',
              paddingLeft: '1.25rem',
              marginBottom: '1.25rem'
            }}>
              "{currentDevo.swahiliText}"
            </blockquote>

            <div style={{ textAlign: 'right', fontWeight: 800, color: 'var(--primary)', fontSize: '1rem', marginBottom: '1.5rem' }}>
              — {currentDevo.reference}
            </div>

            {/* Pastoral Reflection */}
            <div style={{ background: 'var(--surface-container-low)', padding: '1rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', marginBottom: '1rem' }}>
              <strong style={{ fontSize: '0.85rem', color: 'var(--primary)', display: 'flex', alignItems: 'center', gap: '0.35rem', marginBottom: '0.3rem' }}>
                <BookOpen size={14} />
                <span>{isSw ? 'Tafakari ya Kichungaji:' : 'Pastoral Meditation:'}</span>
              </strong>
              <p style={{ fontSize: '0.9rem', color: 'var(--text-body)', lineHeight: '1.5' }}>
                {isSw ? currentDevo.pastoralReflection : currentDevo.reflectionEn}
              </p>
            </div>

            {/* Daily Prayer */}
            <div style={{ background: 'var(--surface-container-low)', padding: '1rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)' }}>
              <strong style={{ fontSize: '0.85rem', color: 'var(--primary)', display: 'flex', alignItems: 'center', gap: '0.35rem', marginBottom: '0.3rem' }}>
                <Heart size={14} />
                <span>{isSw ? 'Sala ya Leo:' : 'Daily Prayer:'}</span>
              </strong>
              <p style={{ fontSize: '0.88rem', color: 'var(--text-headline)', fontStyle: 'italic', lineHeight: '1.5' }}>
                "{currentDevo.prayer}"
              </p>
            </div>
          </div>

          {/* Controls Bar */}
          <div style={{ display: 'flex', gap: '0.65rem', borderTop: '1px solid var(--border-subtle)', paddingTop: '1.25rem' }}>
            <button 
              onClick={toggleSpeak} 
              className={isSpeaking ? 'btn-gold' : 'btn-secondary'} 
              style={{ flex: 1, padding: '0.6rem' }}
            >
              {isSpeaking ? <VolumeX size={16} /> : <Volume2 size={16} />}
              <span>{isSpeaking ? (isSw ? 'Sitisha Sauti' : 'Stop Audio') : (isSw ? 'Sikiliza Sauti' : 'Listen')}</span>
            </button>

            <button 
              onClick={handleNativeShare} 
              className="btn-primary" 
              style={{ flex: 1, padding: '0.6rem' }}
            >
              <Share2 size={16} />
              <span>{isSw ? 'Shiriki WhatsApp' : 'Share WhatsApp'}</span>
            </button>
          </div>
        </div>

        {/* Right: WhatsApp Status Graphic Preview Card */}
        <div className="church-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '1.25rem' }}>
          <div>
            <span style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--text-headline)', display: 'flex', alignItems: 'center', gap: '0.35rem', marginBottom: '0.6rem' }}>
              <Share2 size={14} style={{ color: 'var(--primary)' }} />
              <span>{isSw ? 'Mwonekano wa WhatsApp Status Card' : 'WhatsApp Status Card Preview'}</span>
            </span>

            {/* Visual Graphic Card Container */}
            <div 
              id="whatsapp-share-card"
              style={{
                background: 'linear-gradient(145deg, #0b1120 0%, #1e3a8a 60%, #172554 100%)',
                color: '#ffffff',
                padding: '2rem 1.75rem',
                borderRadius: '16px',
                border: '2px solid rgba(245, 158, 11, 0.5)',
                boxShadow: '0 12px 30px rgba(15, 23, 42, 0.4)',
                position: 'relative',
                overflow: 'hidden',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'space-between',
                minHeight: '340px'
              }}
            >
              {/* Background ambient glow */}
              <div style={{
                position: 'absolute',
                top: '-40px',
                right: '-40px',
                width: '160px',
                height: '160px',
                borderRadius: '50%',
                background: 'radial-gradient(circle, rgba(245, 158, 11, 0.3) 0%, rgba(245, 158, 11, 0) 70%)',
                pointerEvents: 'none'
              }} />

              {/* Card Header */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', position: 'relative', zIndex: 2 }}>
                <div style={{
                  width: '38px',
                  height: '38px',
                  borderRadius: '50%',
                  background: 'rgba(255, 255, 255, 0.1)',
                  border: '1.5px solid #fbbf24',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#fbbf24'
                }}>
                  <Church size={20} />
                </div>
                <div>
                  <div style={{ fontFamily: 'var(--font-cinzel)', fontWeight: 800, fontSize: '0.95rem', letterSpacing: '1px', color: '#fef3c7' }}>
                    ZION JERUSALEM
                  </div>
                  <div style={{ fontSize: '0.7rem', color: '#93c5fd', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                    Neno la Uzima • Daily Bread
                  </div>
                </div>
              </div>

              {/* Central Scripture */}
              <div style={{ margin: '1.5rem 0', position: 'relative', zIndex: 2 }}>
                <div style={{ fontSize: '2.5rem', lineHeight: '1', color: 'rgba(245, 158, 11, 0.4)', fontFamily: 'serif' }}>
                  “
                </div>
                <p style={{
                  fontFamily: 'var(--font-scripture)',
                  fontSize: '1.2rem',
                  lineHeight: '1.6',
                  color: '#ffffff',
                  fontStyle: 'italic',
                  margin: '-1rem 0 0.8rem 0'
                }}>
                  {currentDevo.swahiliText}
                </p>
                <div style={{ textAlign: 'right', fontWeight: 800, color: '#fbbf24', fontSize: '1rem' }}>
                  — {currentDevo.reference}
                </div>
              </div>

              {/* Card Footer */}
              <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                borderTop: '1px solid rgba(255, 255, 255, 0.15)',
                paddingTop: '0.75rem',
                position: 'relative',
                zIndex: 2,
                fontSize: '0.75rem',
                color: '#cbd5e1'
              }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                  <MapPin size={12} />
                  <span>{CHURCH_PROFILE.location}</span>
                </span>
                <span style={{ color: '#fbbf24', fontWeight: 600 }}>Sayuni Yerusalemu</span>
              </div>
            </div>
          </div>

          {/* Quick Copy Button */}
          <button 
            onClick={handleCopyStatus}
            className="btn-gold" 
            style={{ width: '100%' }}
          >
            {isCopied ? <Check size={16} /> : <Copy size={16} />}
            <span>{isCopied ? (isSw ? 'Imenakiliwa kwenye Clipboard!' : 'Copied to Clipboard!') : (isSw ? 'Nakili Ujumbe wa WhatsApp' : 'Copy Formatted Text')}</span>
          </button>
        </div>
      </div>
    </div>
  );
};
