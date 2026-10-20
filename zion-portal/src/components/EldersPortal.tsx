import React, { useState } from 'react';
import { 
  Users, 
  Heart, 
  Plus, 
  CheckCircle2,
  Shield,
  Calendar,
  FileText
} from 'lucide-react';
import type { Language, ElderCounselingCase } from '../types';
import { CHURCH_PROFILE, INITIAL_ELDER_CASES } from '../data/mockData';

interface EldersPortalProps {
  language: Language;
}

export const EldersPortal: React.FC<EldersPortalProps> = ({ language }) => {
  const isSw = language === 'sw';
  const [cases, setCases] = useState<ElderCounselingCase[]>(INITIAL_ELDER_CASES);
  const [showCaseModal, setShowCaseModal] = useState(false);
  const [caseTitle, setCaseTitle] = useState('');
  const [familyOrMember, setFamilyOrMember] = useState('');
  const [elderInCharge, setElderInCharge] = useState('Mzee Emmanuel Mtweve');
  const [category, setCategory] = useState<'Ndoa & Familia' | 'Ushauri Nasaha' | 'Maombi ya Wagonjwa' | 'Nidhamu'>('Ndoa & Familia');
  const [notes, setNotes] = useState('');
  const [filterCategory, setFilterCategory] = useState<string>('all');

  const handleCreateCase = (e: React.FormEvent) => {
    e.preventDefault();
    if (!caseTitle || !familyOrMember) return;

    const newCase: ElderCounselingCase = {
      id: `case-${Date.now()}`,
      title: caseTitle,
      memberOrFamily: familyOrMember,
      elderInCharge,
      category,
      status: 'active',
      date: new Date().toISOString().split('T')[0],
      notes
    };

    setCases([newCase, ...cases]);
    setShowCaseModal(false);
    setCaseTitle('');
    setFamilyOrMember('');
    setNotes('');
  };

  const handleStatusToggle = (id: string) => {
    setCases(cases.map(c => {
      if (c.id === id) {
        return {
          ...c,
          status: c.status === 'resolved' ? 'active' : 'resolved'
        };
      }
      return c;
    }));
  };

  const filteredCases = filterCategory === 'all' 
    ? cases 
    : cases.filter(c => c.category === filterCategory);

  const activeCount = cases.filter(c => c.status === 'active').length;
  const resolvedCount = cases.filter(c => c.status === 'resolved').length;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Elders Board Hero Banner - Sanctuary Navy & Electric Blue */}
      <div 
        className="dark-hero"
        style={{
          background: 'linear-gradient(135deg, #0A2540 0%, #082F70 55%, #0D52CD 100%)',
          color: '#ffffff',
          padding: '2rem',
          borderRadius: 'var(--radius-lg)',
          boxShadow: 'var(--shadow-lg)',
          position: 'relative',
          border: '1px solid rgba(13, 82, 205, 0.35)'
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem', marginBottom: '0.45rem' }}>
              <span className="badge" style={{ background: 'rgba(241, 218, 255, 0.22)', color: '#f1daff', border: '1px solid rgba(241, 218, 255, 0.45)' }}>
                <Shield size={13} />
                {isSw ? 'Uongozi wa Hekima & Nidhamu' : 'Wisdom & Governance Council'}
              </span>
              <span style={{ fontSize: '0.8rem', color: '#dee1ff' }}>
                {CHURCH_PROFILE.location}
              </span>
            </div>

            <h2 style={{ fontSize: '1.85rem', fontWeight: 800, margin: '0 0 0.4rem 0', letterSpacing: '-0.02em', color: '#ffffff' }}>
              {isSw ? 'Lango la Baraza la Wazee wa Kanisa' : 'Church Elders & Counseling Board'}
            </h2>

            <p style={{ fontSize: '0.88rem', color: '#dee1ff', margin: 0, maxWidth: '750px', lineHeight: 1.55 }}>
              {isSw 
                ? 'Kusimamia nidhamu ya kiroho, kutoa ushauri nasaha wa ndoa na familia, kufanya ziara za maombi kwa wagonjwa, na kusaidia maono ya Askofu Messi Mgala.'
                : 'Overseeing spiritual order, offering marital counseling, conducting sick visitations, and supporting Bishop Messi Mgala’s pastoral vision.'}
            </p>
          </div>

          <button 
            onClick={() => setShowCaseModal(true)}
            className="btn-primary"
            style={{ padding: '0.6rem 1.25rem', fontSize: '0.88rem', background: '#0D52CD', color: '#ffffff' }}
          >
            <Plus size={16} />
            <span>{isSw ? '+ Rekodi Kesi ya Ushauri' : '+ New Counseling Record'}</span>
          </button>
        </div>
      </div>

      {/* KPI Cards for Elders */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1rem' }}>
        <div className="church-card" style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '8px', background: 'var(--primary-100)', color: 'var(--primary-700)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Users size={24} />
          </div>
          <div>
            <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', fontWeight: 600 }}>{isSw ? 'KESI ZINAZOHUDUMIWA' : 'ACTIVE COUNSELING'}</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-headline)' }}>{activeCount}</div>
          </div>
        </div>

        <div className="church-card" style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '8px', background: 'var(--emerald-100)', color: 'var(--emerald-600)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <CheckCircle2 size={24} />
          </div>
          <div>
            <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', fontWeight: 600 }}>{isSw ? 'ZILIZOSULUHISHWA' : 'RESOLVED CASES'}</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-headline)' }}>{resolvedCount}</div>
          </div>
        </div>

        <div className="church-card" style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '8px', background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Heart size={24} />
          </div>
          <div>
            <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', fontWeight: 600 }}>{isSw ? 'ZIARA ZA WAGONJWA' : 'SICK VISITATIONS'}</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-headline)' }}>3 Kaya</div>
          </div>
        </div>
      </div>

      {/* Main Cases & Counseling Roster */}
      <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem' }}>
          <div>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
              {isSw ? 'Daftari la Ushauri Nasaha, Maridhiano & Ziara' : 'Counseling & Pastoral Visitation Registry'}
            </h3>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-muted)' }}>
              {isSw ? 'Kumbukumbu rasmi za Baraza la Wazee kwa usiri na uadilifu' : 'Confidential elder pastoral mediation registry'}
            </span>
          </div>

          <select 
            value={filterCategory} 
            onChange={(e) => setFilterCategory(e.target.value)}
            className="form-select"
            style={{ width: 'auto', fontSize: '0.85rem' }}
          >
            <option value="all">{isSw ? 'Kategoria Zote' : 'All Categories'}</option>
            <option value="Ndoa & Familia">Ndoa & Familia</option>
            <option value="Ushauri Nasaha">Ushauri Nasaha</option>
            <option value="Maombi ya Wagonjwa">Maombi ya Wagonjwa</option>
            <option value="Nidhamu">Nidhamu</option>
          </select>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
          {filteredCases.map((c) => (
            <div 
              key={c.id}
              style={{
                background: 'var(--bg-app)',
                border: '1px solid var(--border-subtle)',
                borderRadius: 'var(--radius-sm)',
                padding: '1.1rem',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.6rem'
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '0.5rem' }}>
                <div>
                  <h4 style={{ fontSize: '1.05rem', fontWeight: 700, color: 'var(--on-surface)', margin: '0 0 0.2rem 0' }}>
                    {c.title}
                  </h4>
                  <div style={{ fontSize: '0.82rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.4rem', flexWrap: 'wrap' }}>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                      <Users size={13} />
                      <span>{isSw ? 'Mshirika / Familia:' : 'Member/Family:'} <strong>{c.memberOrFamily}</strong></span>
                    </span>
                    <span>•</span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                      <Calendar size={13} />
                      <span>{c.date}</span>
                    </span>
                  </div>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <span className={`badge ${c.status === 'resolved' ? 'badge-emerald' : c.status === 'pending_pastor' ? 'badge-gold' : 'badge-purple'}`}>
                    {c.status === 'resolved' ? (isSw ? 'Imesuluhishwa' : 'Resolved') : c.status === 'pending_pastor' ? (isSw ? 'Kwa Askofu' : 'To Bishop') : (isSw ? 'Inaendelea' : 'Active')}
                  </span>
                  <button 
                    onClick={() => handleStatusToggle(c.id)}
                    className="btn-secondary"
                    style={{ fontSize: '0.75rem', padding: '0.35rem 0.75rem' }}
                  >
                    {c.status === 'resolved' ? (isSw ? 'Fungua Upya' : 'Reopen') : (isSw ? 'Tia Alama ya Suluhu' : 'Mark Resolved')}
                  </button>
                </div>
              </div>

              <div style={{ fontSize: '0.85rem', color: 'var(--text-body)', background: 'var(--surface-container-low)', padding: '0.65rem 0.85rem', borderRadius: 'var(--radius-sm)', display: 'flex', alignItems: 'flex-start', gap: '0.35rem' }}>
                <FileText size={15} style={{ color: 'var(--primary)', marginTop: '2px', flexShrink: 0 }} />
                <div>
                  <strong>{isSw ? 'Vidokezo vya Kikao / Ziara:' : 'Meeting/Visit Notes:'}</strong> {c.notes}
                </div>
              </div>

              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)', display: 'flex', justifyContent: 'space-between', borderTop: '1px solid var(--border-subtle)', paddingTop: '0.4rem' }}>
                <span>{isSw ? 'Mzee Msimamizi:' : 'Elder in Charge:'} <strong>{c.elderInCharge}</strong></span>
                <span style={{ color: 'var(--primary-700)', fontWeight: 600 }}>{c.category}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* MODAL: NEW COUNSELING CASE */}
      {showCaseModal && (
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
          <div className="church-card" style={{ maxWidth: '560px', width: '100%', maxHeight: '92vh', overflowY: 'auto' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '0.3rem', color: 'var(--text-headline)' }}>
              {isSw ? 'Rekodi Kesi ya Ushauri / Ziara ya Wazee' : 'Record New Counseling Case'}
            </h3>

            <form onSubmit={handleCreateCase} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
              <div>
                <label className="form-label">{isSw ? 'Kichwa cha Shauri / Kusudio la Ziara' : 'Case Subject'} *</label>
                <input 
                  type="text" 
                  required
                  placeholder={isSw ? 'mf. Ushauri wa Amani na Maridhiano ya Ndoa' : 'e.g. Marital Reconciliation Session'}
                  value={caseTitle}
                  onChange={(e) => setCaseTitle(e.target.value)}
                  className="form-input"
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label className="form-label">{isSw ? 'Jina la Mshirika / Kaya' : 'Member / Family Name'} *</label>
                  <input 
                    type="text" 
                    required
                    placeholder="mf. Familia ya Ndg. Peter"
                    value={familyOrMember}
                    onChange={(e) => setFamilyOrMember(e.target.value)}
                    className="form-input"
                  />
                </div>
                <div>
                  <label className="form-label">{isSw ? 'Kategoria ya Shauri' : 'Category'}</label>
                  <select 
                    value={category} 
                    onChange={(e) => setCategory(e.target.value as any)}
                    className="form-select"
                  >
                    <option value="Ndoa & Familia">Ndoa & Familia</option>
                    <option value="Ushauri Nasaha">Ushauri Nasaha</option>
                    <option value="Maombi ya Wagonjwa">Maombi ya Wagonjwa</option>
                    <option value="Nidhamu">Nidhamu</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="form-label">{isSw ? 'Mzee wa Kanisa Msimamizi' : 'Elder in Charge'}</label>
                <input 
                  type="text" 
                  value={elderInCharge}
                  onChange={(e) => setElderInCharge(e.target.value)}
                  className="form-input"
                />
              </div>

              <div>
                <label className="form-label">{isSw ? 'Vidokezo vya Mashauri na Makubaliano' : 'Session Notes & Actions'} *</label>
                <textarea 
                  rows={3} 
                  required
                  placeholder={isSw ? 'Andika muhtasari wa mazungumzo na hatua zilizochukuliwa...' : 'Enter mediation summary...'}
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="form-textarea"
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '0.5rem' }}>
                <button 
                  type="button" 
                  onClick={() => setShowCaseModal(false)}
                  className="btn-secondary"
                >
                  {isSw ? 'Ghairi' : 'Cancel'}
                </button>
                <button type="submit" className="btn-primary">
                  <CheckCircle2 size={16} />
                  <span>{isSw ? 'Hifadhi Kumbukumbu' : 'Save Record'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
