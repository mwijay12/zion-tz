import React, { useState } from 'react';
import { 
  UserPlus, 
  Search, 
  Filter, 
  CheckCircle, 
  XCircle, 
  Phone, 
  Home,
  Users
} from 'lucide-react';
import type { Language, UserRole, ChurchMember } from '../types';
import { INITIAL_MEMBERS, INITIAL_JUMUIYA_GROUPS } from '../data/mockData';

interface MembersModuleProps {
  language: Language;
  userRole: UserRole;
}

export const MembersModule: React.FC<MembersModuleProps> = ({
  language,
  userRole
}) => {
  const isSw = language === 'sw';
  const [members, setMembers] = useState<ChurchMember[]>(INITIAL_MEMBERS);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedJumuiya, setSelectedJumuiya] = useState('all');
  const [showAddModal, setShowAddModal] = useState(false);

  // New member form
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [gender, setGender] = useState<'Male' | 'Female'>('Male');
  const [ageGroup, setAgeGroup] = useState<'Adult' | 'Youth' | 'Child'>('Adult');
  const [jumId, setJumId] = useState(INITIAL_JUMUIYA_GROUPS[0].id);
  const [roleTitle, setRoleTitle] = useState('');
  const [baptized, setBaptized] = useState(true);

  const handleAddMember = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name) return;

    const newM: ChurchMember = {
      id: `mem-${Date.now().toString().slice(-4)}`,
      fullName: name,
      phone: phone || '+255 700 000 000',
      gender: gender,
      ageGroup: ageGroup,
      jumuiyaId: jumId,
      isBaptized: baptized,
      role: roleTitle || (isSw ? 'Mshirika' : 'Member'),
      joinedDate: new Date().toISOString().split('T')[0]
    };

    setMembers([newM, ...members]);
    setName('');
    setPhone('');
    setRoleTitle('');
    setShowAddModal(false);
  };

  const filteredMembers = members.filter((m) => {
    const matchesSearch = m.fullName.toLowerCase().includes(searchTerm.toLowerCase()) || m.phone.includes(searchTerm);
    const matchesJumuiya = selectedJumuiya === 'all' || m.jumuiyaId === selectedJumuiya;
    return matchesSearch && matchesJumuiya;
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Title & Action Bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <span className="badge badge-purple" style={{ marginBottom: '0.35rem', display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
            <Users size={13} />
            <span>{isSw ? 'Daftari Rasmi la Kanisa' : 'Official Church Registry'}</span>
          </span>
          <h2 style={{ fontFamily: 'var(--font-cinzel)', fontSize: '1.65rem', fontWeight: 800, color: 'var(--text-headline)' }}>
            {isSw ? 'Daftari la Waumini na Mahudhurio' : 'Church Members & Attendance'}
          </h2>
        </div>

        {(userRole === 'pastor' || userRole === 'cell_leader' || userRole === 'treasurer') && (
          <button 
            onClick={() => setShowAddModal(true)} 
            className="btn-primary"
          >
            <UserPlus size={16} />
            <span>{isSw ? 'Sajili Muumini Mpya' : 'Register New Member'}</span>
          </button>
        )}
      </div>

      {/* Filter and Search Bar */}
      <div className="church-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.85rem', alignItems: 'center' }}>
          <div style={{ flex: 1, minWidth: '240px', position: 'relative' }}>
            <Search size={16} style={{ position: 'absolute', left: '0.85rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }} />
            <input 
              type="text" 
              className="form-input"
              placeholder={isSw ? 'Tafuta kwa jina au namba ya simu...' : 'Search by name or phone...'}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              style={{ paddingLeft: '2.4rem' }}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Filter size={16} style={{ color: 'var(--text-muted)' }} />
            <select 
              className="form-select"
              value={selectedJumuiya}
              onChange={(e) => setSelectedJumuiya(e.target.value)}
              style={{ width: 'auto' }}
            >
              <option value="all">{isSw ? 'Jumuiya Zote' : 'All Home Cells'}</option>
              {INITIAL_JUMUIYA_GROUPS.map(g => (
                <option key={g.id} value={g.id}>{g.name}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Members Directory Table */}
      <div className="church-card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h3 style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-headline)' }}>
            {isSw ? `Waumini Walioorodheshwa (${filteredMembers.length})` : `Listed Members (${filteredMembers.length})`}
          </h3>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.88rem' }}>
            <thead>
              <tr style={{ borderBottom: '2px solid var(--border-subtle)', color: 'var(--text-muted)' }}>
                <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Jina Kamili' : 'Full Name'}</th>
                <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Mawasiliano' : 'Phone'}</th>
                <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Kundi / Jinsia' : 'Group / Gender'}</th>
                <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Jumuiya' : 'Home Cell'}</th>
                <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Wadhifa / Huduma' : 'Ministry Role'}</th>
                <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Ubatizo' : 'Baptism'}</th>
              </tr>
            </thead>
            <tbody>
              {filteredMembers.map((m) => {
                const jum = INITIAL_JUMUIYA_GROUPS.find(g => g.id === m.jumuiyaId);
                return (
                  <tr key={m.id} style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                    <td style={{ padding: '0.75rem 0.5rem', fontWeight: 700, color: 'var(--primary-800)' }}>
                      {m.fullName}
                    </td>
                    <td style={{ padding: '0.75rem 0.5rem', color: 'var(--text-body)' }}>
                      <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.3rem' }}>
                        <Phone size={13} style={{ color: 'var(--text-muted)' }} />
                        {m.phone}
                      </span>
                    </td>
                    <td style={{ padding: '0.75rem 0.5rem' }}>
                      <span className="badge badge-blue">
                        {m.gender === 'Male' ? (isSw ? 'Mwanaume' : 'Male') : (isSw ? 'Mwanamke' : 'Female')} • {m.ageGroup}
                      </span>
                    </td>
                    <td style={{ padding: '0.75rem 0.5rem' }}>
                      <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.25rem', color: 'var(--text-headline)', fontWeight: 500 }}>
                        <Home size={13} style={{ color: 'var(--gold-600)' }} />
                        {jum ? jum.name : '—'}
                      </span>
                    </td>
                    <td style={{ padding: '0.75rem 0.5rem', fontWeight: 600, color: 'var(--gold-800)' }}>
                      {m.role}
                    </td>
                    <td style={{ padding: '0.75rem 0.5rem' }}>
                      {m.isBaptized ? (
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.25rem', color: 'var(--emerald-600)', fontWeight: 600, fontSize: '0.8rem' }}>
                          <CheckCircle size={14} />
                          {isSw ? 'Amebatizwa' : 'Baptized'}
                        </span>
                      ) : (
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.25rem', color: 'var(--text-muted)', fontSize: '0.8rem' }}>
                          <XCircle size={14} />
                          {isSw ? 'Bado' : 'Not yet'}
                        </span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal: Add New Member */}
      {showAddModal && (
        <div style={{
          position: 'fixed',
          top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0, 0, 0, 0.7)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100,
          padding: '1rem'
        }}>
          <div className="church-card" style={{ maxWidth: '520px', width: '100%', maxHeight: '90vh', overflowY: 'auto' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '0.35rem', color: 'var(--text-headline)' }}>
              {isSw ? 'Sajili Mshirika Mpya wa Sayuni' : 'Register New Member'}
            </h3>
            <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', marginBottom: '1.25rem' }}>
              {isSw ? 'Ingiza taarifa za muumini kwenye kanzidata rasmi ya kanisa' : 'Enter member details into the official church roster'}
            </p>

            <form onSubmit={handleAddMember}>
              <div className="form-group">
                <label className="form-label">{isSw ? 'Jina Kamili' : 'Full Name'}</label>
                <input 
                  type="text" 
                  className="form-input"
                  placeholder="Mfano: Daudi Emanuel Mwita"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">{isSw ? 'Namba ya Simu' : 'Phone Number'}</label>
                <input 
                  type="text" 
                  className="form-input"
                  placeholder="Mfano: +255 754 112 233"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div className="form-group">
                  <label className="form-label">{isSw ? 'Jinsia' : 'Gender'}</label>
                  <select 
                    className="form-select"
                    value={gender}
                    onChange={(e) => setGender(e.target.value as any)}
                  >
                    <option value="Male">{isSw ? 'Mwanaume' : 'Male'}</option>
                    <option value="Female">{isSw ? 'Mwanamke' : 'Female'}</option>
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">{isSw ? 'Kundi la Umri' : 'Age Group'}</label>
                  <select 
                    className="form-select"
                    value={ageGroup}
                    onChange={(e) => setAgeGroup(e.target.value as any)}
                  >
                    <option value="Adult">{isSw ? 'Mtu Mzima' : 'Adult'}</option>
                    <option value="Youth">{isSw ? 'Kijana' : 'Youth'}</option>
                    <option value="Child">{isSw ? 'Mtoto / Sunday School' : 'Child'}</option>
                  </select>
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">{isSw ? 'Jumuiya ya Nyumbani' : 'Home Cell Group'}</label>
                <select 
                  className="form-select"
                  value={jumId}
                  onChange={(e) => setJumId(e.target.value)}
                >
                  {INITIAL_JUMUIYA_GROUPS.map(g => (
                    <option key={g.id} value={g.id}>{g.name} ({g.location})</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">{isSw ? 'Wadhifa au Idara ya Huduma' : 'Ministry Role'}</label>
                <input 
                  type="text" 
                  className="form-input"
                  placeholder={isSw ? 'Mfano: Mwimbaji wa Kwaya, Mwalimu, Uamsho' : 'e.g. Choir, Usher, Intercessor'}
                  value={roleTitle}
                  onChange={(e) => setRoleTitle(e.target.value)}
                />
              </div>

              <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <input 
                  type="checkbox" 
                  id="baptized-check"
                  checked={baptized}
                  onChange={(e) => setBaptized(e.target.checked)}
                  style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                />
                <label htmlFor="baptized-check" style={{ cursor: 'pointer', fontWeight: 600, fontSize: '0.88rem' }}>
                  {isSw ? 'Ameshapokea Ubatizo wa Maji Tele' : 'Has received water baptism'}
                </label>
              </div>

              <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1.5rem' }}>
                <button type="submit" className="btn-primary" style={{ flex: 1 }}>
                  {isSw ? 'Kamilisha Usajili' : 'Register Member'}
                </button>
                <button 
                  type="button" 
                  onClick={() => setShowAddModal(false)}
                  className="btn-secondary"
                >
                  {isSw ? 'Ghairi' : 'Cancel'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
