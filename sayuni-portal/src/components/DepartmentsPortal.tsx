import React, { useState } from 'react';
import { 
  Calendar, 
  Briefcase, 
  Phone, 
  Clock, 
  Plus, 
  CheckCircle2,
  Heart,
  Users
} from 'lucide-react';
import type { Language, DepartmentInfo } from '../types';
import { INITIAL_DEPARTMENTS } from '../data/mockData';

interface DepartmentsPortalProps {
  language: Language;
}

export const DepartmentsPortal: React.FC<DepartmentsPortalProps> = ({ language }) => {
  const isSw = language === 'sw';
  const [departments, setDepartments] = useState<DepartmentInfo[]>(INITIAL_DEPARTMENTS);
  const [activeDeptId, setActiveDeptId] = useState<string>(departments[0]?.id || 'dept-wamama');
  const [showUpdateModal, setShowUpdateModal] = useState(false);
  const [updateText, setUpdateText] = useState('');
  const [newEventTitle, setNewEventTitle] = useState('');

  const activeDept = departments.find(d => d.id === activeDeptId) || departments[0];

  const handleUpdateDept = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newEventTitle && !updateText) return;

    setDepartments(departments.map(d => {
      if (d.id === activeDeptId) {
        return {
          ...d,
          upcomingEvent: newEventTitle || d.upcomingEvent,
          currentProject: updateText || d.currentProject
        };
      }
      return d;
    }));

    setShowUpdateModal(false);
    setUpdateText('');
    setNewEventTitle('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Top Banner */}
      {/* Hero Banner - Sanctuary Navy & Electric Blue */}
      <div 
        className="dark-hero"
        style={{
          background: 'linear-gradient(135deg, #0A2540 0%, #082F70 55%, #0D52CD 100%)',
          color: '#ffffff',
          padding: '2rem',
          borderRadius: 'var(--radius-lg)',
          boxShadow: 'var(--shadow-lg)',
          border: '1px solid rgba(13, 82, 205, 0.35)'
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem', marginBottom: '0.45rem' }}>
              <span className="badge" style={{ background: 'rgba(241, 218, 255, 0.22)', color: '#f1daff', border: '1px solid rgba(241, 218, 255, 0.45)' }}>
                <Heart size={13} />
                {isSw ? 'Idara za Jamii & Huduma' : 'Demographic Fellowships'}
              </span>
              <span style={{ fontSize: '0.8rem', color: '#dee1ff' }}>
                Zion Fellowship Church
              </span>
            </div>

            <h2 style={{ fontSize: '1.85rem', fontWeight: 800, margin: '0 0 0.4rem 0', letterSpacing: '-0.02em', color: '#ffffff' }}>
              {isSw ? 'Lango la Idara Kuu za Kanisa' : 'Church Fellowship Departments'}
            </h2>

            <p style={{ fontSize: '0.88rem', color: '#dee1ff', margin: 0, maxWidth: '750px', lineHeight: 1.55 }}>
              {isSw 
                ? 'Umoja wa Wanawake (Wamama), Umoja wa Wanaume (Wababa), Vijana (Youth), na Sunday School (Watoto). Kusimamia miradi, ratiba na maendeleo yao.'
                : 'Women, Men, Youth, and Children ministries managing fellowship schedules, projects, and spiritual growth.'}
            </p>
          </div>

          <button 
            onClick={() => setShowUpdateModal(true)}
            className="btn-primary"
            style={{ padding: '0.6rem 1.25rem', fontSize: '0.88rem', background: '#0D52CD', color: '#ffffff' }}
          >
            <Plus size={16} />
            <span>{isSw ? '+ Sasisha Mradi wa Idara' : '+ Update Dept Project'}</span>
          </button>
        </div>
      </div>

      {/* Touch-Friendly Department Selector */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '0.75rem' }}>
        {departments.map((dept) => (
          <button
            key={dept.id}
            onClick={() => setActiveDeptId(dept.id)}
            style={{
              padding: '1rem',
              borderRadius: 'var(--radius-sm)',
              border: activeDeptId === dept.id ? '2px solid var(--primary)' : '1px solid var(--border-subtle)',
              background: activeDeptId === dept.id ? 'var(--surface-container-high)' : 'var(--surface-container-lowest)',
              textAlign: 'left',
              cursor: 'pointer',
              display: 'flex',
              flexDirection: 'column',
              gap: '0.35rem'
            }}
          >
            <strong style={{ color: activeDeptId === dept.id ? 'var(--primary)' : 'var(--on-surface)', fontSize: '0.95rem' }}>
              {isSw ? dept.nameSw : dept.name}
            </strong>
            <span style={{ fontSize: '0.78rem', color: 'var(--on-surface-variant)', display: 'flex', alignItems: 'center', gap: '0.3rem' }}>
              <Users size={13} /> {dept.memberCount} {isSw ? 'Wanachama' : 'Members'}
            </span>
          </button>
        ))}
      </div>

      {/* Active Department Details Canvas */}
      {activeDept && (
        <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '0.75rem', borderBottom: '1px solid var(--border-subtle)', paddingBottom: '1rem' }}>
            <div>
              <span className="badge badge-gold" style={{ marginBottom: '0.3rem' }}>
                {isSw ? activeDept.nameSw : activeDept.name}
              </span>
              <h3 style={{ fontSize: '1.35rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
                {isSw ? activeDept.nameSw : activeDept.name}
              </h3>
              <p style={{ fontSize: '0.88rem', color: 'var(--text-muted)', margin: '0.3rem 0 0 0' }}>
                {activeDept.description}
              </p>
            </div>

            <div style={{ background: 'var(--bg-app)', padding: '0.75rem 1rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', textAlign: 'right' }}>
              <div style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>{isSw ? 'Kiongozi Msimamizi:' : 'Leader:'}</div>
              <strong style={{ fontSize: '0.95rem', color: 'var(--primary-800)' }}>{activeDept.leader}</strong>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: '0.25rem', marginTop: '0.2rem' }}>
                <Phone size={12} /> {activeDept.phone}
              </div>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.25rem' }}>
            {/* Meeting Schedule */}
            <div style={{ background: 'var(--bg-app)', padding: '1.1rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.45rem', color: 'var(--primary-700)', fontWeight: 700, fontSize: '0.92rem' }}>
                <Clock size={16} />
                <span>{isSw ? 'Ratiba ya Mikutano & Maombi' : 'Meeting & Prayer Schedule'}</span>
              </div>
              <div style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--text-headline)' }}>
                {activeDept.meetingSchedule}
              </div>
              <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                {isSw ? 'Ukumbi wa Kanisa / Kwa Matope' : 'Church Hall / Kwa Matope'}
              </span>
            </div>

            {/* Current Project */}
            <div style={{ background: 'var(--bg-app)', padding: '1.1rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.45rem', color: 'var(--gold-700)', fontWeight: 700, fontSize: '0.92rem' }}>
                <Briefcase size={16} />
                <span>{isSw ? 'Mradi Unaotekelezwa Sasa' : 'Current Ministry Project'}</span>
              </div>
              <div style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--text-headline)' }}>
                {activeDept.currentProject}
              </div>
              <span style={{ fontSize: '0.78rem', color: 'var(--emerald-600)', fontWeight: 600 }}>
                {isSw ? 'Michango na Utendaji Unaendelea' : 'Active and On Track'}
              </span>
            </div>

            {/* Upcoming Event */}
            <div style={{ background: 'var(--bg-app)', padding: '1.1rem', borderRadius: 'var(--radius-sm)', border: '1px solid var(--border-subtle)', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.45rem', color: '#7c3aed', fontWeight: 700, fontSize: '0.92rem' }}>
                <Calendar size={16} />
                <span>{isSw ? 'Tukio au Semina Inayofuata' : 'Upcoming Seminar / Event'}</span>
              </div>
              <div style={{ fontSize: '1rem', fontWeight: 800, color: 'var(--text-headline)' }}>
                {activeDept.upcomingEvent}
              </div>
              <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                {isSw ? 'Imepangwa kwenye Kalenda ya Kanisa' : 'Scheduled on Church Calendar'}
              </span>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: UPDATE DEPT */}
      {showUpdateModal && (
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
          <div className="church-card" style={{ maxWidth: '520px', width: '100%', maxHeight: '92vh', overflowY: 'auto' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '0.3rem', color: 'var(--text-headline)' }}>
              {isSw ? `Sasisha Taarifa: ${activeDept.nameSw}` : `Update: ${activeDept.name}`}
            </h3>

            <form onSubmit={handleUpdateDept} style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
              <div>
                <label className="form-label">{isSw ? 'Mradi Mpya au Maendeleo' : 'Project Update'}</label>
                <input 
                  type="text" 
                  placeholder={activeDept.currentProject}
                  value={updateText}
                  onChange={(e) => setUpdateText(e.target.value)}
                  className="form-input"
                />
              </div>

              <div>
                <label className="form-label">{isSw ? 'Tukio / Semina Inayofuata' : 'Upcoming Event'}</label>
                <input 
                  type="text" 
                  placeholder={activeDept.upcomingEvent}
                  value={newEventTitle}
                  onChange={(e) => setNewEventTitle(e.target.value)}
                  className="form-input"
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '0.5rem' }}>
                <button 
                  type="button" 
                  onClick={() => setShowUpdateModal(false)}
                  className="btn-secondary"
                >
                  {isSw ? 'Ghairi' : 'Cancel'}
                </button>
                <button type="submit" className="btn-primary">
                  <CheckCircle2 size={16} />
                  <span>{isSw ? 'Hifadhi Mabadiliko' : 'Save Changes'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
