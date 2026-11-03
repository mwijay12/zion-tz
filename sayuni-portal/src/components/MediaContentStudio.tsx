import React, { useState, useRef, useEffect, useCallback } from 'react';
import { 
  Sparkles, 
  Download, 
  Copy, 
  Check, 
  Palette, 
  Smartphone, 
  Square, 
  Quote,
  Share2,
  Printer
} from 'lucide-react';
import type { Language } from '../types';
import { CHURCH_PROFILE, INITIAL_BULLETIN_NOTICES } from '../data/mockData';
import { PrintableOfficialReport } from './PrintableOfficialReport';

interface MediaContentStudioProps {
  language: Language;
}

type AspectRatio = '1:1' | '9:16';
type ThemeStyle = 'sanctuary' | 'gold_burgundy' | 'sunset' | 'emerald' | 'minimal';

interface TemplateOption {
  id: string;
  category: 'quote' | 'scripture' | 'service' | 'vigil';
  title: string;
  titleEn: string;
  quote: string;
  speaker: string;
  scripture: string;
  dateInfo: string;
  theme: ThemeStyle;
}

const TEMPLATES: TemplateOption[] = [
  {
    id: 'bishop-quote-1',
    category: 'quote',
    title: 'Nukuu ya Askofu Mercy Mgalla',
    titleEn: "Bishop Mercy's Pastoral Quote",
    quote: 'Ukitembea katika imani ya kweli, mashaka yote ya kesho yanakoma mbele za Mungu. Usiangalie ukubwa wa mawimbi, mtazame yule aliyetuliza dhoruba.',
    speaker: 'Mchungaji Askofu Mercy Mgalla',
    scripture: 'Marko 4:39-40',
    dateInfo: 'Jumapili ya Imani • Sayuni Jerusalem',
    theme: 'sanctuary',
  },
  {
    id: 'scripture-day',
    category: 'scripture',
    title: 'Mstari wa Siku (Verse of the Day)',
    titleEn: 'Verse of the Day',
    quote: 'Bwana ndiye mchungaji wangu, sitapungukiwa na kitu. Katika malisho ya majani mabichi hunilaza, kando ya maji ya utulivu huniongoza.',
    speaker: 'Neno la Mungu',
    scripture: 'Zaburi 23:1-2',
    dateInfo: 'Ujumbe wa Kila Siku • Sayuni Jerusalem',
    theme: 'emerald',
  },
  {
    id: 'sunday-service',
    category: 'service',
    title: 'Tangazo la Ibada ya Jumapili',
    titleEn: 'Sunday Service Announcement',
    quote: 'Karibu katika Ibada Kuu ya Sifa, Kuabudu na Neno lenye Uzima. Mungu anayo baraka maalum iliyoandaliwa kwa ajili yako na familia yako!',
    speaker: 'Ibada ya Jumapili: 08:30 Asubuhi - 01:00 Mchana',
    scripture: 'Zaburi 122:1',
    dateInfo: 'Sayuni Jerusalem Church • Mbagala Kwa Matope',
    theme: 'gold_burgundy',
  },
  {
    id: 'mkesha-vigil',
    category: 'vigil',
    title: 'Mkesha wa Nguvu na Maombi',
    titleEn: 'All-Night Prayer Vigil',
    quote: 'Mkesha Mkuu wa Kuvunja Misingi na Kufungua Milango ya Baraka. Njoo na hitaji lako la kipekee tukililie jina la Bwana usiku kucha.',
    speaker: 'Ijumaa Hii: Saa 03:00 Usiku Mpaka Asubuhi',
    scripture: 'Matendo ya Mitume 16:25',
    dateInfo: 'Kwa Matope, Mbagala • Dar es Salaam',
    theme: 'sunset',
  },
];

export const MediaContentStudio: React.FC<MediaContentStudioProps> = ({ language }) => {
  const isSw = language === 'sw';
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  // Studio Settings State
  const [ratio, setRatio] = useState<AspectRatio>('9:16'); // 9:16 default for WhatsApp Status
  const [theme, setTheme] = useState<ThemeStyle>('sanctuary');
  const [headline, setHeadline] = useState('SAYUNI JERUSALEM CHURCH');
  const [quoteText, setQuoteText] = useState(TEMPLATES[0].quote);
  const [speakerText, setSpeakerText] = useState(TEMPLATES[0].speaker);
  const [scriptureText, setScriptureText] = useState(TEMPLATES[0].scripture);
  const [dateText, setDateText] = useState(TEMPLATES[0].dateInfo);
  const [copiedCaption, setCopiedCaption] = useState(false);
  const [showBulletinModal, setShowBulletinModal] = useState(false);

  // Apply template
  const applyTemplate = (t: TemplateOption) => {
    setQuoteText(t.quote);
    setSpeakerText(t.speaker);
    setScriptureText(t.scripture);
    setDateText(t.dateInfo);
    setTheme(t.theme);
  };

  // Canvas drawing routine
  const drawGraphic = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Dimensions
    const width = 1080;
    const height = ratio === '9:16' ? 1920 : 1080;
    canvas.width = width;
    canvas.height = height;

    // Background Gradient based on Theme
    let grad = ctx.createLinearGradient(0, 0, width, height);
    let accentColor = '#E5B238'; // Gold default
    let textColor = '#FFFFFF';
    let subTextColor = 'rgba(255, 255, 255, 0.82)';
    let cardBg = 'rgba(255, 255, 255, 0.07)';
    let cardBorder = 'rgba(229, 178, 56, 0.35)';

    if (theme === 'sanctuary') {
      grad.addColorStop(0, '#06182B');
      grad.addColorStop(0.5, '#0A2540');
      grad.addColorStop(1, '#0D52CD');
      accentColor = '#E5B238';
    } else if (theme === 'gold_burgundy') {
      grad.addColorStop(0, '#2D080E');
      grad.addColorStop(0.55, '#520E1A');
      grad.addColorStop(1, '#8C1527');
      accentColor = '#F3C64F';
      cardBorder = 'rgba(243, 198, 79, 0.4)';
    } else if (theme === 'sunset') {
      grad.addColorStop(0, '#1E0836');
      grad.addColorStop(0.5, '#421668');
      grad.addColorStop(1, '#8A2B66');
      accentColor = '#FFAA5B';
      cardBorder = 'rgba(255, 170, 91, 0.4)';
    } else if (theme === 'emerald') {
      grad.addColorStop(0, '#03251D');
      grad.addColorStop(0.5, '#064E3B');
      grad.addColorStop(1, '#047857');
      accentColor = '#6EE7B7';
      cardBorder = 'rgba(110, 231, 183, 0.4)';
    } else if (theme === 'minimal') {
      grad.addColorStop(0, '#F9FAFB');
      grad.addColorStop(1, '#F3F4F6');
      accentColor = '#0A2540';
      textColor = '#111827';
      subTextColor = '#4B5563';
      cardBg = 'rgba(255, 255, 255, 0.95)';
      cardBorder = 'rgba(10, 37, 64, 0.2)';
    }

    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, width, height);

    // Subtle decorative concentric circles for sacred vibe
    ctx.save();
    ctx.strokeStyle = accentColor;
    ctx.globalAlpha = 0.08;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(width / 2, ratio === '9:16' ? 420 : 260, 480, 0, Math.PI * 2);
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(width / 2, ratio === '9:16' ? 420 : 260, 320, 0, Math.PI * 2);
    ctx.stroke();
    ctx.restore();

    // Top Header: Church Name & Badge
    ctx.textAlign = 'center';
    ctx.fillStyle = accentColor;
    ctx.font = 'bold 28px "Cinzel", "Cinzel Decorative", Georgia, serif';
    ctx.letterSpacing = '4px';
    const topY = ratio === '9:16' ? 140 : 100;
    ctx.fillText('✦ ' + headline + ' ✦', width / 2, topY);

    ctx.fillStyle = subTextColor;
    ctx.font = '600 20px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
    ctx.letterSpacing = '2px';
    ctx.fillText(CHURCH_PROFILE.location.toUpperCase(), width / 2, topY + 36);

    // Divider line
    ctx.strokeStyle = accentColor;
    ctx.globalAlpha = 0.4;
    ctx.beginPath();
    ctx.moveTo(width / 2 - 140, topY + 60);
    ctx.lineTo(width / 2 + 140, topY + 60);
    ctx.stroke();
    ctx.globalAlpha = 1;

    // Quote Marks Icon Graphic
    const quoteY = ratio === '9:16' ? 340 : 210;
    ctx.fillStyle = accentColor;
    ctx.font = 'bold 96px Georgia, serif';
    ctx.globalAlpha = 0.35;
    ctx.fillText('“', width / 2, quoteY);
    ctx.globalAlpha = 1;

    // Main Quote Card Box
    const cardMargin = 80;
    const cardWidth = width - (cardMargin * 2);
    const cardY = ratio === '9:16' ? 410 : 240;
    const cardHeight = ratio === '9:16' ? 1040 : 610;

    // Rounded rectangle card
    ctx.save();
    ctx.fillStyle = cardBg;
    ctx.strokeStyle = cardBorder;
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.roundRect(cardMargin, cardY, cardWidth, cardHeight, 28);
    ctx.fill();
    ctx.stroke();
    ctx.restore();

    // Word Wrap Function for Canvas
    const wrapText = (
      text: string, 
      x: number, 
      startY: number, 
      maxWidth: number, 
      lineHeight: number
    ): number => {
      const words = text.split(' ');
      let line = '';
      let currentY = startY;

      for (let n = 0; n < words.length; n++) {
        const testLine = line + words[n] + ' ';
        const metrics = ctx.measureText(testLine);
        const testWidth = metrics.width;
        if (testWidth > maxWidth && n > 0) {
          ctx.fillText(line.trim(), x, currentY);
          line = words[n] + ' ';
          currentY += lineHeight;
        } else {
          line = testLine;
        }
      }
      ctx.fillText(line.trim(), x, currentY);
      return currentY;
    };

    // Draw Main Quote Text
    ctx.textAlign = 'center';
    ctx.fillStyle = textColor;
    const quoteFontSize = ratio === '9:16' ? 46 : 38;
    ctx.font = `600 ${quoteFontSize}px "Cinzel", "Cinzel Decorative", Georgia, serif`;
    const quoteStartY = ratio === '9:16' ? cardY + 160 : cardY + 110;
    const maxTextWidth = cardWidth - 120;
    const lastY = wrapText(quoteText, width / 2, quoteStartY, maxTextWidth, quoteFontSize * 1.45);

    // Speaker / Pastor Highlight
    const speakerY = Math.max(lastY + 70, ratio === '9:16' ? cardY + 680 : cardY + 390);
    ctx.fillStyle = accentColor;
    ctx.font = 'bold 32px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
    ctx.fillText('— ' + speakerText + ' —', width / 2, speakerY);

    // Scripture reference badge
    if (scriptureText) {
      const badgeY = speakerY + 54;
      ctx.fillStyle = subTextColor;
      ctx.font = 'italic 26px Georgia, serif';
      ctx.fillText('« ' + scriptureText + ' »', width / 2, badgeY);
    }

    // Date / Event / Schedule Info
    if (dateText) {
      const dateY = ratio === '9:16' ? cardY + cardHeight - 70 : cardY + cardHeight - 50;
      ctx.fillStyle = accentColor;
      ctx.font = 'bold 22px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
      ctx.fillText('🗓 ' + dateText, width / 2, dateY);
    }

    // Bottom Branding Footer
    const footerY = ratio === '9:16' ? height - 110 : height - 60;
    ctx.fillStyle = subTextColor;
    ctx.font = '600 19px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
    ctx.fillText('Simu & WhatsApp: ' + CHURCH_PROFILE.phone.split('/')[0].trim(), width / 2, footerY);

    ctx.fillStyle = accentColor;
    ctx.font = 'italic 18px Georgia, serif';
    ctx.fillText('« ' + CHURCH_PROFILE.motto + ' »', width / 2, footerY + 36);
  }, [ratio, theme, headline, quoteText, speakerText, scriptureText, dateText]);

  useEffect(() => {
    drawGraphic();
  }, [drawGraphic]);

  // Download image as high-res PNG
  const handleDownloadImage = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const dataUrl = canvas.toDataURL('image/png');
    const link = document.createElement('a');
    const filename = `zion_media_${ratio === '9:16' ? 'status_9x16' : 'post_1x1'}_${Date.now()}.png`;
    link.download = filename;
    link.href = dataUrl;
    link.click();
  };

  // Copy ready-to-use social media caption
  const handleCopyCaption = () => {
    const caption = `✦ SAYUNI JERUSALEM CHURCH — MBAGALA KWA MATOPE ✦\n\n"${quoteText}"\n\n— ${speakerText} (${scriptureText})\n\n🗓 ${dateText}\n📍 ${CHURCH_PROFILE.location}\n📞 Mawasiliano: ${CHURCH_PROFILE.phone}\n\n#SayuniJerusalem #MbagalaKwaMatope #AskofuMercyMgala #NenoLaMungu #TanzaniaGospel #UjumbeWaLeo`;

    navigator.clipboard.writeText(caption);
    setCopiedCaption(true);
    setTimeout(() => setCopiedCaption(false), 2500);
  };

  // 1-Click WhatsApp share to groups
  const handleShareWhatsApp = () => {
    const text = encodeURIComponent(
      `✦ *SAYUNI JERUSALEM CHURCH — MBAGALA KWA MATOPE* ✦\n\n"${quoteText}"\n\n— *${speakerText}* (${scriptureText})\n\n🗓 ${dateText}\n📍 ${CHURCH_PROFILE.location}\n📞 Mawasiliano: ${CHURCH_PROFILE.phone}\n\n#SayuniJerusalem #MbagalaKwaMatope #AskofuMercyMgala`
    );
    window.open(`https://wa.me/?text=${text}`, '_blank');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.75rem' }}>
      {/* Studio Header Banner */}
      <div 
        style={{
          background: 'linear-gradient(135deg, #0A2540 0%, #0D52CD 100%)',
          color: '#ffffff',
          padding: '2rem 1.75rem',
          borderRadius: 'var(--radius-lg)',
          display: 'flex',
          flexWrap: 'wrap',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '1.25rem',
          boxShadow: 'var(--shadow-md)',
          border: '1px solid rgba(13, 82, 205, 0.3)'
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', marginBottom: '0.4rem' }}>
            <Sparkles size={22} style={{ color: '#E5B238' }} />
            <span style={{ fontSize: '0.82rem', fontWeight: 700, letterSpacing: '1.5px', textTransform: 'uppercase', color: '#E5B238' }}>
              {isSw ? 'Kituo cha Ubunifu wa Kanisa' : 'Church Media & Content Studio'}
            </span>
          </div>
          <h1 style={{ fontFamily: 'var(--font-cinzel)', fontSize: '1.75rem', fontWeight: 800, margin: 0 }}>
            {isSw ? 'Tengeneza Picha & Nukuu za Mitandaoni' : 'Create Social Media & Sermon Graphics'}
          </h1>
          <p style={{ margin: '0.4rem 0 0 0', opacity: 0.88, fontSize: '0.92rem', maxWidth: '640px' }}>
            {isSw 
              ? 'Tengeneza kwa sekunde picha za HD kwa ajili ya WhatsApp Status (9:16) na Instagram (1:1) zenye nukuu za Askofu Mercy Mgalla na mistari ya ibada.'
              : 'Generate high-res graphics for WhatsApp Status (9:16) and Instagram (1:1) featuring Bishop Mercy quotes and scripture in seconds.'}
          </p>
        </div>

        {/* Quick actions */}
        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
          <button
            onClick={handleCopyCaption}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              padding: '0.65rem 1.15rem',
              borderRadius: 'var(--radius-md)',
              border: '1px solid rgba(255, 255, 255, 0.25)',
              backgroundColor: 'rgba(255, 255, 255, 0.1)',
              color: '#ffffff',
              fontSize: '0.88rem',
              fontWeight: 600,
              cursor: 'pointer',
              backdropFilter: 'blur(8px)',
              transition: 'all 0.2s'
            }}
          >
            {copiedCaption ? <Check size={16} style={{ color: '#10B981' }} /> : <Copy size={16} />}
            <span>{copiedCaption ? (isSw ? 'Imenakiliwa!' : 'Copied!') : (isSw ? 'Nakili Maelezo (Caption)' : 'Copy Caption')}</span>
          </button>

          <button
            onClick={handleShareWhatsApp}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              padding: '0.65rem 1.15rem',
              borderRadius: 'var(--radius-md)',
              border: 'none',
              backgroundColor: '#25D366',
              color: '#ffffff',
              fontSize: '0.88rem',
              fontWeight: 700,
              cursor: 'pointer',
              boxShadow: '0 4px 12px rgba(37, 211, 102, 0.35)',
              transition: 'transform 0.15s ease'
            }}
            title={isSw ? 'Tuma moja kwa moja kwenye makundi ya WhatsApp' : 'Share to WhatsApp groups'}
          >
            <Share2 size={16} />
            <span>{isSw ? 'Shiriki WhatsApp' : 'Share to WhatsApp'}</span>
          </button>

          <button
            onClick={() => setShowBulletinModal(true)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              padding: '0.65rem 1.15rem',
              borderRadius: 'var(--radius-md)',
              border: '1px solid rgba(255, 255, 255, 0.3)',
              backgroundColor: 'rgba(255, 255, 255, 0.12)',
              color: '#ffffff',
              fontSize: '0.88rem',
              fontWeight: 600,
              cursor: 'pointer',
              backdropFilter: 'blur(8px)',
              transition: 'all 0.2s'
            }}
            title={isSw ? 'Tengeneza Kijarida cha Ukurasa 1 cha Ubao wa Matangazo' : 'Generate 1-Page Notice Board Bulletin'}
          >
            <Printer size={16} />
            <span>{isSw ? 'Chapa Kijarida (Bulletin)' : 'Print Bulletin'}</span>
          </button>

          <button
            onClick={handleDownloadImage}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              padding: '0.65rem 1.25rem',
              borderRadius: 'var(--radius-md)',
              border: 'none',
              backgroundColor: '#E5B238',
              color: '#06182B',
              fontSize: '0.88rem',
              fontWeight: 700,
              cursor: 'pointer',
              boxShadow: '0 4px 12px rgba(229, 178, 56, 0.35)',
              transition: 'transform 0.15s ease'
            }}
          >
            <Download size={17} />
            <span>{isSw ? 'Pakua Picha ya HD' : 'Download High-Res PNG'}</span>
          </button>
        </div>
      </div>

      {/* Main Studio Grid: Left Controls, Right Interactive Canvas Preview */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '1.75rem', alignItems: 'start' }}>
        
        {/* Left Side: Templates & Customization Controls */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          
          {/* Format / Aspect Ratio Selector */}
          <div className="church-card" style={{ padding: '1.25rem' }}>
            <h3 style={{ fontSize: '0.95rem', fontWeight: 700, color: 'var(--text-headline)', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Smartphone size={17} style={{ color: 'var(--primary)' }} />
              {isSw ? '1. Chagua Ukubwa wa Picha' : '1. Select Format'}
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
              <button
                onClick={() => setRatio('9:16')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.5rem',
                  padding: '0.75rem',
                  borderRadius: 'var(--radius-md)',
                  border: ratio === '9:16' ? '2px solid #0D52CD' : '1px solid var(--border-color)',
                  backgroundColor: ratio === '9:16' ? 'rgba(13, 82, 205, 0.08)' : 'var(--surface)',
                  color: ratio === '9:16' ? '#0D52CD' : 'var(--text-main)',
                  fontWeight: 700,
                  fontSize: '0.88rem',
                  cursor: 'pointer'
                }}
              >
                <Smartphone size={18} />
                <span>WhatsApp Status (9:16)</span>
              </button>

              <button
                onClick={() => setRatio('1:1')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.5rem',
                  padding: '0.75rem',
                  borderRadius: 'var(--radius-md)',
                  border: ratio === '1:1' ? '2px solid #0D52CD' : '1px solid var(--border-color)',
                  backgroundColor: ratio === '1:1' ? 'rgba(13, 82, 205, 0.08)' : 'var(--surface)',
                  color: ratio === '1:1' ? '#0D52CD' : 'var(--text-main)',
                  fontWeight: 700,
                  fontSize: '0.88rem',
                  cursor: 'pointer'
                }}
              >
                <Square size={18} />
                <span>Instagram / Post (1:1)</span>
              </button>
            </div>
          </div>

          {/* Color Themes */}
          <div className="church-card" style={{ padding: '1.25rem' }}>
            <h3 style={{ fontSize: '0.95rem', fontWeight: 700, color: 'var(--text-headline)', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Palette size={17} style={{ color: 'var(--primary)' }} />
              {isSw ? '2. Rangi & Mwonekano wa Kiroho' : '2. Color & Spiritual Vibe'}
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(100px, 1fr))', gap: '0.6rem' }}>
              {[
                { id: 'sanctuary', name: isSw ? 'Sanctuary Navy' : 'Navy Glow', color: '#0A2540' },
                { id: 'gold_burgundy', name: isSw ? 'Royal Burgundy' : 'Burgundy', color: '#520E1A' },
                { id: 'sunset', name: isSw ? 'Mkesha Fire' : 'Sunset Fire', color: '#421668' },
                { id: 'emerald', name: isSw ? 'Amani Emerald' : 'Emerald', color: '#064E3B' },
                { id: 'minimal', name: isSw ? 'Light Minimal' : 'Clean Light', color: '#F3F4F6' },
              ].map(t => (
                <button
                  key={t.id}
                  onClick={() => setTheme(t.id as ThemeStyle)}
                  style={{
                    padding: '0.55rem',
                    borderRadius: '8px',
                    border: theme === t.id ? '2px solid #E5B238' : '1px solid var(--border-color)',
                    backgroundColor: 'var(--surface)',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '0.4rem',
                    cursor: 'pointer',
                    fontSize: '0.75rem',
                    fontWeight: 600,
                    color: 'var(--text-main)'
                  }}
                >
                  <span style={{ width: '24px', height: '24px', borderRadius: '50%', backgroundColor: t.color, display: 'inline-block', boxShadow: '0 2px 4px rgba(0,0,0,0.2)' }} />
                  <span>{t.name}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Pre-made Templates */}
          <div className="church-card" style={{ padding: '1.25rem' }}>
            <h3 style={{ fontSize: '0.95rem', fontWeight: 700, color: 'var(--text-headline)', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Quote size={17} style={{ color: 'var(--primary)' }} />
              {isSw ? '3. Sampuli za Haraka (Templates)' : '3. Quick Templates'}
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
              {TEMPLATES.map(t => (
                <div
                  key={t.id}
                  onClick={() => applyTemplate(t)}
                  style={{
                    padding: '0.75rem',
                    borderRadius: '8px',
                    border: '1px solid var(--border-color)',
                    backgroundColor: 'var(--surface-variant)',
                    cursor: 'pointer',
                    transition: 'all 0.15s ease',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center'
                  }}
                >
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '0.86rem', color: 'var(--text-headline)' }}>
                      {isSw ? t.title : t.titleEn}
                    </div>
                    <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', marginTop: '0.2rem' }}>
                      {t.speaker} • {t.scripture}
                    </div>
                  </div>
                  <span style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--primary)' }}>
                    {isSw ? 'Tumia' : 'Apply'} →
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Custom Text Editor */}
          <div className="church-card" style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
            <h3 style={{ fontSize: '0.95rem', fontWeight: 700, color: 'var(--text-headline)', margin: 0 }}>
              {isSw ? '4. Badili Maandishi (Custom Text)' : '4. Edit Text Content'}
            </h3>

            <div>
              <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                {isSw ? 'Kichwa cha Kanisa / Bango' : 'Headline / Banner Title'}
              </label>
              <input
                type="text"
                className="input-field"
                value={headline}
                onChange={(e) => setHeadline(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', fontSize: '0.86rem' }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                {isSw ? 'Nukuu Kuu au Ujumbe' : 'Main Quote or Scripture Text'}
              </label>
              <textarea
                className="input-field"
                rows={4}
                value={quoteText}
                onChange={(e) => setQuoteText(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', fontSize: '0.86rem', resize: 'vertical' }}
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                  {isSw ? 'Mnenaji / Kiongozi' : 'Speaker / Preacher'}
                </label>
                <input
                  type="text"
                  className="input-field"
                  value={speakerText}
                  onChange={(e) => setSpeakerText(e.target.value)}
                  style={{ width: '100%', padding: '0.55rem', fontSize: '0.86rem' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                  {isSw ? 'Mstari wa Biblia' : 'Scripture Reference'}
                </label>
                <input
                  type="text"
                  className="input-field"
                  value={scriptureText}
                  onChange={(e) => setScriptureText(e.target.value)}
                  style={{ width: '100%', padding: '0.55rem', fontSize: '0.86rem' }}
                />
              </div>
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', marginBottom: '0.25rem' }}>
                {isSw ? 'Tarehe, Muda au Tukio' : 'Event Date / Schedule / Location'}
              </label>
              <input
                type="text"
                className="input-field"
                value={dateText}
                onChange={(e) => setDateText(e.target.value)}
                style={{ width: '100%', padding: '0.55rem', fontSize: '0.86rem' }}
              />
            </div>
          </div>
        </div>

        {/* Right Side: Live Canvas Preview Box */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', position: 'sticky', top: '1rem' }}>
          <div 
            className="church-card" 
            style={{ 
              padding: '1.25rem', 
              display: 'flex', 
              flexDirection: 'column', 
              alignItems: 'center',
              backgroundColor: 'var(--surface)'
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center', marginBottom: '0.75rem' }}>
              <span style={{ fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-muted)' }}>
                {isSw ? 'Mwonekano wa Picha Halisi (Live HD Render)' : 'Live HD Canvas Preview'}
              </span>
              <span style={{ fontSize: '0.76rem', color: '#10B981', fontWeight: 700 }}>
                1080 x {ratio === '9:16' ? '1920px' : '1080px'}
              </span>
            </div>

            {/* Canvas Container with scaled display */}
            <div 
              style={{
                width: '100%',
                maxWidth: ratio === '9:16' ? '320px' : '440px',
                borderRadius: '16px',
                overflow: 'hidden',
                boxShadow: '0 12px 32px rgba(0, 0, 0, 0.25)',
                border: '1px solid rgba(229, 178, 56, 0.3)',
                backgroundColor: '#06182B',
                display: 'flex',
                justifyContent: 'center'
              }}
            >
              <canvas
                ref={canvasRef}
                style={{
                  width: '100%',
                  height: 'auto',
                  display: 'block'
                }}
              />
            </div>

            {/* Quick Action Button below preview */}
            <button
              onClick={handleDownloadImage}
              style={{
                marginTop: '1.25rem',
                width: '100%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '0.5rem',
                padding: '0.85rem',
                borderRadius: 'var(--radius-md)',
                border: 'none',
                backgroundColor: 'var(--primary)',
                color: '#ffffff',
                fontSize: '0.92rem',
                fontWeight: 700,
                cursor: 'pointer',
                boxShadow: '0 4px 14px rgba(13, 82, 205, 0.3)'
              }}
            >
              <Download size={18} />
              <span>{isSw ? 'Pakua Picha ya Kutuma WhatsApp / Instagram' : 'Download for WhatsApp / Instagram'}</span>
            </button>
          </div>

          {/* Social Caption Preview Box */}
          <div className="church-card" style={{ padding: '1.25rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
              <span style={{ fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-muted)' }}>
                {isSw ? 'Maelezo ya Kupost Mitandaoni (Caption)' : 'Social Caption & Hashtags'}
              </span>
              <button
                onClick={handleCopyCaption}
                style={{
                  background: 'none',
                  border: 'none',
                  color: 'var(--primary)',
                  fontSize: '0.78rem',
                  fontWeight: 700,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.3rem'
                }}
              >
                {copiedCaption ? <Check size={14} style={{ color: '#10B981' }} /> : <Copy size={14} />}
                <span>{copiedCaption ? (isSw ? 'Imenakiliwa' : 'Copied') : (isSw ? 'Nakili' : 'Copy')}</span>
              </button>
            </div>
            <div 
              style={{
                padding: '0.75rem',
                backgroundColor: 'var(--surface-variant)',
                borderRadius: '8px',
                fontSize: '0.8rem',
                lineHeight: 1.5,
                color: 'var(--text-main)',
                fontFamily: 'monospace',
                whiteSpace: 'pre-wrap'
              }}
            >
              {`✦ SAYUNI JERUSALEM CHURCH — MBAGALA KWA MATOPE ✦\n\n"${quoteText}"\n\n— ${speakerText} (${scriptureText})\n\n🗓 ${dateText}\n📍 ${CHURCH_PROFILE.location}\n\n#SayuniJerusalem #MbagalaKwaMatope #AskofuMercyMgala`}
            </div>
          </div>
        </div>

      </div>

      {/* Printable Bulletin Modal */}
      {showBulletinModal && (
        <PrintableOfficialReport
          reportType="weekly_bulletin"
          title={isSw ? 'Kijarida Rasmi cha Ubao wa Matangazo' : 'Official Weekly Notice Board Bulletin'}
          subtitle={CHURCH_PROFILE.location}
          notices={INITIAL_BULLETIN_NOTICES}
          onClose={() => setShowBulletinModal(false)}
        />
      )}
    </div>
  );
};
