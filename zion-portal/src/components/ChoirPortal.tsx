import React, { useState } from 'react';
import { 
  Music, 
  Plus, 
  CheckCircle2, 
  FileText,
  Volume2,
  Upload,
  Edit3,
  Trash2,
  Cloud,
  Loader2
} from 'lucide-react';
import type { Language, ChoirSong } from '../types';
import type { PortalUser } from '../services/authService';
import { CHURCH_CHOIRS, INITIAL_CHOIR_SONGS } from '../data/mockData';
import { uploadToCloudinary, CLOUDINARY_CONFIG } from '../services/cloudinaryService';
import choirImg from '../assets/zion_worship_choir.jpg';

interface ChoirPortalProps {
  language: Language;
  currentUser?: PortalUser | null;
}

export const ChoirPortal: React.FC<ChoirPortalProps> = ({ language, currentUser }) => {
  const isSw = language === 'sw';
  const [songs, setSongs] = useState<ChoirSong[]>(() => {
    try {
      const saved = localStorage.getItem('zion_portal_choir_songs');
      return saved ? JSON.parse(saved) : INITIAL_CHOIR_SONGS;
    } catch {
      return INITIAL_CHOIR_SONGS;
    }
  });

  const [showSongModal, setShowSongModal] = useState(false);
  const [editingSongId, setEditingSongId] = useState<string | null>(null);
  const [selectedChoirFilter, setSelectedChoirFilter] = useState<string>('all');
  const [selectedSongForLyrics, setSelectedSongForLyrics] = useState<ChoirSong | null>(null);

  // Form states
  const [songTitle, setSongTitle] = useState('');
  const [choirName, setChoirName] = useState('Kwaya ya Galilaya');
  const [songKey, setSongKey] = useState('G Major');
  const [tempo, setTempo] = useState('100 BPM');
  const [lyrics, setLyrics] = useState('');
  const [rehearsalDate, setRehearsalDate] = useState('Ijumaa Saa 10:00 Jioni');
  const [audioUrl, setAudioUrl] = useState('');

  // Upload status
  const [isUploadingAudio, setIsUploadingAudio] = useState(false);
  const [uploadSuccessMessage, setUploadSuccessMessage] = useState<string | null>(null);

  const saveSongs = (updated: ChoirSong[]) => {
    setSongs(updated);
    try {
      localStorage.setItem('zion_portal_choir_songs', JSON.stringify(updated));
      // Broadcast to sync endpoint
      fetch('/api/sync/choir-songs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ songs: updated })
      }).catch(e => console.log('Choir songs sync note:', e));
    } catch (e) {
      console.error(e);
    }
  };

  const handleOpenNew = () => {
    setEditingSongId(null);
    setSongTitle('');
    setChoirName('Kwaya ya Galilaya');
    setSongKey('G Major');
    setTempo('100 BPM');
    setLyrics('');
    setRehearsalDate('Ijumaa Saa 10:00 Jioni');
    setAudioUrl('');
    setUploadSuccessMessage(null);
    setShowSongModal(true);
  };

  const handleOpenEdit = (song: ChoirSong) => {
    setEditingSongId(song.id);
    setSongTitle(song.title);
    setChoirName(song.choirName);
    setSongKey(song.key);
    setTempo(song.tempo);
    setLyrics(song.lyrics);
    setRehearsalDate(song.rehearsalDate);
    setAudioUrl(song.audioDemoUrl || '');
    setUploadSuccessMessage(null);
    setShowSongModal(true);
  };

  const handleDeleteSong = (id: string) => {
    const songToDelete = songs.find(s => s.id === id);
    const confirmText = isSw 
      ? `Je, una uhakika unataka kufuta wimbo "${songToDelete?.title}"?`
      : `Are you sure you want to delete "${songToDelete?.title}"?`;
    if (!window.confirm(confirmText)) return;

    const updated = songs.filter(s => s.id !== id);
    saveSongs(updated);
  };

  const handleSaveSong = (e: React.FormEvent) => {
    e.preventDefault();
    if (!songTitle.trim()) return;

    if (editingSongId) {
      // Update existing song
      const updated = songs.map(s => {
        if (s.id === editingSongId) {
          return {
            ...s,
            title: songTitle.trim(),
            choirName,
            key: songKey.trim(),
            tempo: tempo.trim(),
            lyrics: lyrics.trim(),
            rehearsalDate: rehearsalDate.trim(),
            audioDemoUrl: audioUrl.trim() || s.audioDemoUrl
          };
        }
        return s;
      });
      saveSongs(updated);
    } else {
      // Create new song
      const newSong: ChoirSong = {
        id: `song-${Date.now().toString().slice(-4)}`,
        title: songTitle.trim(),
        choirName,
        key: songKey.trim(),
        tempo: tempo.trim(),
        lyrics: lyrics.trim(),
        rehearsalDate: rehearsalDate.trim(),
        audioDemoUrl: audioUrl.trim() || 'https://audio.zionjerusalem.org/choir/sayuni.mp3'
      };
      saveSongs([newSong, ...songs]);
    }

    setShowSongModal(false);
  };

  const filteredSongs = selectedChoirFilter === 'all'
    ? songs
    : songs.filter(s => s.choirName === selectedChoirFilter);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Banner - Sanctuary Navy & Electric Blue */}
      <div 
        className="dark-hero"
        style={{
          background: 'linear-gradient(135deg, #0A2540 0%, #082F70 55%, #0D52CD 100%)',
          color: '#ffffff',
          padding: '2rem',
          borderRadius: 'var(--radius-lg)',
          position: 'relative',
          overflow: 'hidden',
          boxShadow: 'var(--shadow-lg)',
          border: '1px solid rgba(13, 82, 205, 0.35)'
        }}
      >
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1.5rem', alignItems: 'center', position: 'relative', zIndex: 2 }}>
          <div style={{ width: '92px', height: '92px', borderRadius: 'var(--radius-md)', overflow: 'hidden', border: '2px solid #dfb7ff', flexShrink: 0, boxShadow: '0 0 16px rgba(109, 0, 179, 0.4)' }}>
            <img 
              src={choirImg} 
              alt="Kwaya za Zion Jerusalem" 
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
            />
          </div>

          <div style={{ flex: 1, minWidth: '260px' }}>
            <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: '0.65rem', marginBottom: '0.45rem' }}>
              <span className="badge" style={{ background: 'rgba(241, 218, 255, 0.22)', color: '#f1daff', border: '1px solid rgba(241, 218, 255, 0.45)' }}>
                <Music size={13} />
                {isSw ? 'Idara ya Uimbaji na Muziki' : 'Music Ministry & Choirs'}
              </span>

              <span className="badge" style={{ background: 'rgba(255, 255, 255, 0.18)', color: '#ffffff', border: '1px solid rgba(255, 255, 255, 0.3)' }}>
                <Cloud size={13} />
                <span>Cloudinary Vault: Active ({CLOUDINARY_CONFIG.uploadPreset})</span>
              </span>

              {currentUser?.isSuperAdmin && (
                <span className="badge badge-gold" style={{ fontSize: '0.72rem' }}>
                  👑 Super Admin Uploads Enabled
                </span>
              )}
            </div>

            <h2 style={{ fontSize: '1.85rem', fontWeight: 800, margin: '0 0 0.4rem 0', letterSpacing: '-0.02em', color: '#ffffff' }}>
              {isSw ? 'Lango la Kwaya & Ukuaji wa Muziki' : 'Choir & Worship Ministry Portal'}
            </h2>

            <p style={{ fontSize: '0.88rem', color: '#dee1ff', margin: 0, maxWidth: '750px', lineHeight: 1.55 }}>
              {isSw 
                ? 'Galilaya, Upendo, Wamama, Vijana, na Praise Team. Pakia faili za sauti, rekodi za mazoezi, badili chords na funguo, hariri maneno (lyrics), na dhibiti ratiba.'
                : 'Galilaya, Upendo, Wamama, Vijana, and Praise Team. Upload audio tracks, practice recordings, change chords, edit lyrics, and manage schedules.'}
            </p>
          </div>

          <button 
            onClick={handleOpenNew}
            className="btn-primary"
            style={{ padding: '0.65rem 1.35rem', background: '#0D52CD', color: '#ffffff' }}
          >
            <Plus size={16} />
            <span>{isSw ? '+ Sajili / Pakia Wimbo Mpya' : '+ Add / Upload New Song'}</span>
          </button>
        </div>
      </div>

      {/* Choir Overview Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))', gap: '1rem' }}>
        {CHURCH_CHOIRS.map((choir, idx) => (
          <div 
            key={idx}
            className="church-card"
            style={{
              padding: '1rem',
              display: 'flex',
              flexDirection: 'column',
              gap: '0.45rem',
              border: selectedChoirFilter === choir.name ? '2px solid var(--primary-600)' : '1px solid var(--border-subtle)',
              cursor: 'pointer'
            }}
            onClick={() => setSelectedChoirFilter(selectedChoirFilter === choir.name ? 'all' : choir.name)}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <strong style={{ fontSize: '0.92rem', color: 'var(--primary-800)' }}>
                {choir.name}
              </strong>
              <Music size={15} style={{ color: 'var(--gold-600)' }} />
            </div>
            <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
              {choir.leader}
            </div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: 'auto' }}>
              {songs.filter(s => s.choirName === choir.name).length} {isSw ? 'Nyimbo Zilizosajiliwa' : 'Registered Songs'}
            </div>
          </div>
        ))}
      </div>

      {/* Song Catalog Registry */}
      <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem' }}>
          <div>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
              {isSw ? 'Sajili ya Nyimbo za Kanisa (Song Catalog)' : 'Church Song & Hymn Repertoire'}
            </h3>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
              {isSw ? 'Funguo za sauti (keys), tempo, maneno na ratiba za mazoezi' : 'Vocal keys, tempo BPM, lyrics, and practice schedules'}
            </span>
          </div>

          <select 
            value={selectedChoirFilter}
            onChange={(e) => setSelectedChoirFilter(e.target.value)}
            className="form-select"
            style={{ width: 'auto', fontSize: '0.85rem' }}
          >
            <option value="all">{isSw ? 'Kwaya Zote' : 'All Choirs'}</option>
            {CHURCH_CHOIRS.map(c => (
              <option key={c.name} value={c.name}>{c.name}</option>
            ))}
          </select>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '1rem' }}>
          {filteredSongs.map((song) => (
            <div 
              key={song.id}
              style={{
                background: 'var(--bg-app)',
                border: '1px solid var(--border-subtle)',
                borderRadius: 'var(--radius-sm)',
                padding: '1.1rem',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.65rem'
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '0.5rem' }}>
                <div>
                  <span className="badge badge-gold" style={{ fontSize: '0.75rem', marginBottom: '0.25rem' }}>
                    {song.choirName}
                  </span>
                  <h4 style={{ fontSize: '1.05rem', fontWeight: 700, color: 'var(--primary-800)', margin: 0 }}>
                    {song.title}
                  </h4>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <span style={{ fontSize: '0.8rem', fontWeight: 800, color: 'var(--primary-700)', background: 'var(--bg-surface)', padding: '0.2rem 0.5rem', borderRadius: '4px', border: '1px solid var(--border-subtle)' }}>
                    Key: {song.key}
                  </span>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '1rem', fontSize: '0.78rem', color: 'var(--on-surface-variant)' }}>
                <span>Tempo: <strong>{song.tempo}</strong></span>
                <span>Mazoezi: <strong>{song.rehearsalDate}</strong></span>
              </div>

              <div style={{ fontSize: '0.82rem', color: 'var(--text-muted)', background: 'var(--bg-surface)', padding: '0.55rem 0.75rem', borderRadius: '4px', fontStyle: 'italic', borderLeft: '3px solid var(--gold-500)' }}>
                "{song.lyrics.slice(0, 90)}..."
              </div>

              {song.audioDemoUrl && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.75rem', color: 'var(--primary-700)', fontWeight: 600 }}>
                    <Volume2 size={13} />
                    <span>{isSw ? 'Sikiliza Demo / Sauti' : 'Audio Demo'}</span>
                  </div>
                  <audio 
                    controls 
                    src={song.audioDemoUrl} 
                    style={{ width: '100%', height: '32px', borderRadius: '6px' }}
                    preload="none"
                  />
                </div>
              )}

              {/* Actions Footer: Lyrics, Edit, Delete */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 'auto', borderTop: '1px solid var(--border-subtle)', paddingTop: '0.65rem' }}>
                <button 
                  onClick={() => setSelectedSongForLyrics(song)}
                  className="btn-secondary"
                  style={{ fontSize: '0.75rem', padding: '0.3rem 0.65rem' }}
                >
                  <FileText size={13} />
                  <span>{isSw ? 'Maneno (Lyrics)' : 'Lyrics'}</span>
                </button>

                <div style={{ display: 'flex', gap: '0.4rem' }}>
                  <button
                    onClick={() => handleOpenEdit(song)}
                    className="btn-secondary"
                    style={{ fontSize: '0.75rem', padding: '0.3rem 0.65rem' }}
                    title={isSw ? 'Hariri Wimbo Huu' : 'Edit Song'}
                  >
                    <Edit3 size={13} />
                    <span>{isSw ? 'Hariri' : 'Edit'}</span>
                  </button>

                  <button
                    onClick={() => handleDeleteSong(song.id)}
                    style={{
                      fontSize: '0.75rem',
                      padding: '0.3rem 0.65rem',
                      background: '#fef2f2',
                      color: '#dc2626',
                      border: '1px solid #fecaca',
                      borderRadius: '6px',
                      cursor: 'pointer',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '0.25rem'
                    }}
                    title={isSw ? 'Futa Wimbo' : 'Delete Song'}
                  >
                    <Trash2 size={13} />
                    <span>{isSw ? 'Futa' : 'Delete'}</span>
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* MODAL: NEW / EDIT SONG WITH CLOUDINARY UPLOAD */}
      {showSongModal && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(0,0,0,0.7)',
          zIndex: 1000,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '1rem'
        }}>
          <div className="church-card" style={{ maxWidth: '540px', width: '100%', maxHeight: '92vh', overflowY: 'auto' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '0.3rem', color: 'var(--text-headline)' }}>
              {editingSongId 
                ? (isSw ? 'Hariri Wimbo wa Kwaya' : 'Edit Choir Song')
                : (isSw ? 'Sajili / Pakia Wimbo Mpya' : 'Register / Upload New Song')}
            </h3>

            <form onSubmit={handleSaveSong} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
              <div>
                <label className="form-label">{isSw ? 'Jina la Wimbo' : 'Song Title'} *</label>
                <input 
                  type="text" 
                  required
                  placeholder={isSw ? 'mf. Bwana Ameichagua Sayuni' : 'e.g. Joyful Praise'}
                  value={songTitle}
                  onChange={(e) => setSongTitle(e.target.value)}
                  className="form-input"
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label className="form-label">{isSw ? 'Kwaya Inayoimba' : 'Choir'}</label>
                  <select 
                    value={choirName} 
                    onChange={(e) => setChoirName(e.target.value)}
                    className="form-select"
                  >
                    {CHURCH_CHOIRS.map(c => (
                      <option key={c.name} value={c.name}>{c.name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="form-label">{isSw ? 'Key ya Sauti (Musical Key)' : 'Musical Key'}</label>
                  <input 
                    type="text" 
                    placeholder="mf. G Major, C, F"
                    value={songKey}
                    onChange={(e) => setSongKey(e.target.value)}
                    className="form-input"
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label className="form-label">{isSw ? 'Tempo / Mwendo' : 'Tempo (BPM)'}</label>
                  <input 
                    type="text" 
                    placeholder="mf. 105 BPM"
                    value={tempo}
                    onChange={(e) => setTempo(e.target.value)}
                    className="form-input"
                  />
                </div>
                <div>
                  <label className="form-label">{isSw ? 'Siku & Saa ya Mazoezi' : 'Rehearsal Time'}</label>
                  <input 
                    type="text" 
                    placeholder="mf. Ijumaa Saa 10:00 Jioni"
                    value={rehearsalDate}
                    onChange={(e) => setRehearsalDate(e.target.value)}
                    className="form-input"
                  />
                </div>
              </div>

              {/* CLOUDINARY AUDIO UPLOAD SECTION */}
              <div style={{ background: 'var(--surface-container-low)', padding: '0.9rem', borderRadius: '10px', border: '1px dashed var(--border-subtle)' }}>
                <label className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                  <Cloud size={15} style={{ color: 'var(--primary)' }} />
                  <span>{isSw ? 'Pakia Faili la Wimbo (MP3 / WAV / Audio)' : 'Upload Audio Track (MP3 / WAV)'}</span>
                </label>

                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.65rem', alignItems: 'center', marginTop: '0.35rem' }}>
                  <label 
                    className="btn-primary"
                    style={{ 
                      cursor: isUploadingAudio ? 'not-allowed' : 'pointer', 
                      padding: '0.5rem 0.95rem', 
                      fontSize: '0.82rem',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '0.4rem'
                    }}
                  >
                    {isUploadingAudio ? <Loader2 size={15} className="animate-spin" /> : <Upload size={15} />}
                    <span>{isUploadingAudio ? (isSw ? 'Inapakia kwenye Cloudinary...' : 'Uploading...') : (isSw ? 'Chagua Faili la Sauti' : 'Select Audio File')}</span>
                    <input 
                      type="file" 
                      accept="audio/*,video/*"
                      style={{ display: 'none' }}
                      disabled={isUploadingAudio}
                      onChange={async (e) => {
                        const file = e.target.files?.[0];
                        if (!file) return;
                        setIsUploadingAudio(true);
                        setUploadSuccessMessage(null);
                        try {
                          const url = await uploadToCloudinary(file, 'zion_choir_audio');
                          setAudioUrl(url);
                          setUploadSuccessMessage(
                            isSw ? `Wimbo "${file.name}" umepakiwa kikamilifu!` : `File "${file.name}" uploaded successfully!`
                          );
                        } catch (err) {
                          console.error(err);
                        } finally {
                          setIsUploadingAudio(false);
                        }
                      }}
                    />
                  </label>

                  {audioUrl && (
                    <span style={{ fontSize: '0.78rem', color: '#16a34a', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.3rem' }}>
                      <CheckCircle2 size={14} />
                      <span>{isSw ? 'Sauti Ipo Tayari' : 'Audio Attached'}</span>
                    </span>
                  )}
                </div>

                {uploadSuccessMessage && (
                  <div style={{ marginTop: '0.5rem', fontSize: '0.78rem', color: '#166534', background: '#dcfce7', padding: '0.4rem 0.75rem', borderRadius: '6px', border: '1px solid #bbf7d0' }}>
                    ✓ {uploadSuccessMessage}
                  </div>
                )}

                <div style={{ marginTop: '0.6rem' }}>
                  <input 
                    type="url" 
                    placeholder="https://... au pakia faili hapo juu"
                    value={audioUrl}
                    onChange={(e) => setAudioUrl(e.target.value)}
                    className="form-input"
                    style={{ fontSize: '0.8rem' }}
                  />
                </div>
              </div>

              <div>
                <label className="form-label">{isSw ? 'Maneno ya Wimbo (Lyrics)' : 'Lyrics'} *</label>
                <textarea 
                  rows={4} 
                  required
                  placeholder={isSw ? 'Andika ubeti na kiitikio cha wimbo huu...' : 'Enter verses and chorus...'}
                  value={lyrics}
                  onChange={(e) => setLyrics(e.target.value)}
                  className="form-textarea"
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '0.5rem' }}>
                <button 
                  type="button" 
                  onClick={() => setShowSongModal(false)}
                  className="btn-secondary"
                >
                  {isSw ? 'Ghairi' : 'Cancel'}
                </button>
                <button type="submit" className="btn-gold">
                  <CheckCircle2 size={16} />
                  <span>{editingSongId ? (isSw ? 'Sasisha Wimbo' : 'Update Song') : (isSw ? 'Hifadhi Wimbo' : 'Save Song')}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: VIEW FULL LYRICS */}
      {selectedSongForLyrics && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(0,0,0,0.7)',
          zIndex: 1000,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '1rem'
        }}>
          <div className="church-card" style={{ maxWidth: '500px', width: '100%', maxHeight: '90vh', overflowY: 'auto' }}>
            <span className="badge badge-gold" style={{ marginBottom: '0.35rem' }}>
              {selectedSongForLyrics.choirName} • Key: {selectedSongForLyrics.key}
            </span>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, color: 'var(--primary-800)', margin: '0 0 1rem 0' }}>
              {selectedSongForLyrics.title}
            </h3>

            <div style={{ background: 'var(--bg-app)', padding: '1rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', whiteSpace: 'pre-wrap', lineHeight: 1.7, fontSize: '0.9rem', color: 'var(--text-headline)' }}>
              {selectedSongForLyrics.lyrics}
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '1rem' }}>
              <button 
                onClick={() => setSelectedSongForLyrics(null)}
                className="btn-primary"
              >
                {isSw ? 'Funga' : 'Close'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ChoirPortal;
