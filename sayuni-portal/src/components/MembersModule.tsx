import React, { useEffect, useState } from 'react';
import { 
  UserPlus, 
  Search, 
  Filter, 
  CheckCircle, 
  XCircle, 
  Phone, 
  Home,
  Users,
  ShieldCheck,
  KeyRound,
  Mail,
  Lock
} from 'lucide-react';
import type { Language, UserRole, ChurchMember } from '../types';
import { INITIAL_JUMUIYA_GROUPS } from '../data/mockData';
import { createId } from '../utils/id';
import { useMembers } from '../services/memberStore';
import { AuthService, type PortalUser } from '../services/authService';
import { provisionLeaderRole, revokeLeaderRole, describeProvisionError } from '../services/churchRoleService';
import { Modal } from './ui/Modal';
import { useToast } from './ui/toastStore';
import { EmptyState } from './ui/States';

interface MembersModuleProps {
  language: Language;
  userRole: UserRole;
  /** Needed to provision the real Firebase custom claim when adding a leader. */
  currentUser?: PortalUser | null;
}

export interface LeaderAccount {
  id: string;
  name: string;
  email: string;
  phone: string;
  role: UserRole;
  roleTitleSw: string;
  branch: string;
  status: 'active' | 'suspended';
  lastLogin: string;
}

const INITIAL_LEADER_ACCOUNTS: LeaderAccount[] = [
  {
    id: 'lead-1',
    name: 'Askofu Mercy James',
    email: 'pastor@zionjerusalem.org',
    phone: '+255 754 123 456',
    role: 'pastor',
    roleTitleSw: 'Mchungaji Askofu Kiongozi',
    branch: 'Mbagala Kwa Matope (HQ)',
    status: 'active',
    lastLogin: 'Leo, 18:30'
  },
  {
    id: 'lead-2',
    name: 'Mwl. Peter Mwita',
    email: 'secretary@zionjerusalem.org',
    phone: '+255 765 889 001',
    role: 'secretary',
    roleTitleSw: 'Katibu Mkuu wa Kanisa',
    branch: 'Mbagala Kwa Matope (HQ)',
    status: 'active',
    lastLogin: 'Leo, 17:45'
  },
  {
    id: 'lead-3',
    name: 'Mzee Daudi Erick Mwijage',
    email: 'admin@zionjerusalem.org',
    phone: '+255 620 641 695',
    role: 'super_admin',
    roleTitleSw: 'Msimamizi Mkuu wa Mifumo (Super Admin)',
    branch: 'Mbagala HQ / Matawi Yote',
    status: 'active',
    lastLogin: 'Leo, 18:40'
  },
  {
    id: 'lead-4',
    name: 'Mhazini Rehema John',
    email: 'treasurer@zionjerusalem.org',
    phone: '+255 784 990 122',
    role: 'treasurer',
    roleTitleSw: 'Mhazini Mkuu wa Kanisa',
    branch: 'Mbagala Kwa Matope (HQ)',
    status: 'active',
    lastLogin: 'Jana, 14:10'
  },
  {
    id: 'lead-5',
    name: 'Mzee James Robert',
    email: 'elders@zionjerusalem.org',
    phone: '+255 712 345 678',
    role: 'deacon',
    roleTitleSw: 'Mwenyekiti wa Baraza la Wazee',
    branch: 'Mbagala Kwa Matope (HQ)',
    status: 'active',
    lastLogin: '02 Nov 2026'
  },
  {
    id: 'lead-6',
    name: 'Mwl. Joshua S. Mrema',
    email: 'choir@zionjerusalem.org',
    phone: '+255 756 789 012',
    role: 'choir_leader',
    roleTitleSw: 'Mkurugenzi wa Idara ya Muziki & Kwaya',
    branch: 'Mbagala Kwa Matope (HQ)',
    status: 'active',
    lastLogin: 'Jana, 19:20'
  }
];

export const MembersModule: React.FC<MembersModuleProps> = ({
  language,
  userRole,
  currentUser
}) => {
  const isSw = language === 'sw';
  const { push: toast } = useToast();
  const [activeSubTab, setActiveSubTab] = useState<'members' | 'leaders'>('members');
  const [members, setMembers] = useMembers();
  const [leaders, setLeaders] = useState<LeaderAccount[]>(() => {
    try {
      const saved = localStorage.getItem('zion_portal_leader_accounts');
      return saved ? JSON.parse(saved) : INITIAL_LEADER_ACCOUNTS;
    } catch {
      return INITIAL_LEADER_ACCOUNTS;
    }
  });

  const [searchTerm, setSearchTerm] = useState('');
  const [selectedJumuiya, setSelectedJumuiya] = useState('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const [showAddLeaderModal, setShowAddLeaderModal] = useState(false);

  // New leader form state
  const [leaderName, setLeaderName] = useState('');
  const [leaderEmail, setLeaderEmail] = useState('');
  const [leaderPhone, setLeaderPhone] = useState('');
  const [leaderRole, setLeaderRole] = useState<UserRole>('deacon');
  const [leaderBranch, setLeaderBranch] = useState('Mbagala Kwa Matope (HQ)');

  // New member form
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [gender, setGender] = useState<'Male' | 'Female'>('Male');
  const [ageGroup, setAgeGroup] = useState<'Adult' | 'Youth' | 'Child'>('Adult');
  const [jumId, setJumId] = useState(INITIAL_JUMUIYA_GROUPS[0].id);
  const [roleTitle, setRoleTitle] = useState('');
  const [baptized, setBaptized] = useState(true);

  useEffect(() => {
    try {
      localStorage.setItem('zion_portal_leader_accounts', JSON.stringify(leaders));
    } catch {}
  }, [leaders]);

  /** Accepts +255…, 0755…, 255… and 7xxxxxxxx; returns a canonical 07… form. */
  const normaliseTzPhone = (raw: string): string | null => {
    const digits = raw.replace(/[^0-9]/g, '');
    if (!digits) return null;
    let local = digits;
    if (local.startsWith('255')) local = local.slice(3);
    if (local.startsWith('0')) local = local.slice(1);
    // Tanzanian mobile numbers are 9 digits after the leading 0.
    return local.length === 9 ? local : null;
  };

  const handleAddMember = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    // A phone number is how the church actually reaches a member (SMS,
    // WhatsApp, care follow-up). Accepting a placeholder silently poisons the
    // register, so validate instead of defaulting to "+255 700 000 000".
    const localPhone = normaliseTzPhone(phone);
    if (phone.trim() && !localPhone) {
      toast({
        tone: 'error',
        title: isSw ? 'Namba ya simu si sahihi' : 'Invalid phone number',
        message: isSw
          ? 'Tumia namba ya Tanzania, mfano 0754 112 233 au +255 754 112 233.'
          : 'Use a Tanzanian number, e.g. 0754 112 233 or +255 754 112 233.',
      });
      return;
    }

    const newM: ChurchMember = {
      id: createId('mem'),
      fullName: name.trim(),
      phone: localPhone ? `+255 ${localPhone.slice(0, 3)} ${localPhone.slice(3, 6)} ${localPhone.slice(6)}` : (isSw ? 'Haijatolewa' : 'Not provided'),
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
    toast({
      tone: 'success',
      title: isSw ? 'Muumini amesajiliwa' : 'Member registered',
      message: isSw ? `${newM.fullName} ameongezwa kwenye daftari la kanisa.` : `${newM.fullName} was added to the church register.`,
    });
  };

  const handleAddLeader = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!leaderName || !leaderEmail) return;

    const roleTitles: Record<UserRole, string> = {
      super_admin: 'Msimamizi wa Mifumo',
      admin: 'Msimamizi Mkuu',
      pastor: 'Mchungaji / Askofu',
      secretary: 'Katibu wa Kanisa',
      deacon: 'Mzee wa Kanisa / Shemasi',
      treasurer: 'Mhazini wa Kanisa',
      usher: 'Mkaribishaji (Usher)',
      jumuiya_leader: 'Kiongozi wa Jumuiya',
      choir_leader: 'Kiongozi wa Kwaya',
      children_teacher: 'Mwalimu wa Watoto',
      member: 'Muumini',
      guest: 'Mgeni'
    };

    const newLeader: LeaderAccount = {
      id: createId('lead'),
      name: leaderName,
      email: leaderEmail,
      phone: leaderPhone || '+255 700 000 000',
      role: leaderRole,
      roleTitleSw: roleTitles[leaderRole] || 'Kiongozi wa Kanisa',
      branch: leaderBranch,
      status: 'active',
      lastLogin: 'Hajawahi kuingia'
    };

    setLeaders(prev => [newLeader, ...prev]);

    // The registry entry alone is only a local note. Actually provision the
    // Firebase custom claim (server-side) so this person can sign in with the
    // role on any device. Demo sessions are explicitly excluded.
    const canProvision = AuthService.canGrantRoles(currentUser) && !currentUser?.isDemo;
    let provisioned = false;
    let provisionNote = isSw
      ? ' Ingia kwa akaunti halisi ya Super Admin ili kugawa ruhusa za Firebase.'
      : ' Sign in as a real Super Admin to grant Firebase permissions.';
    if (canProvision) {
      try {
        await provisionLeaderRole({
          email: newLeader.email,
          role: newLeader.role,
          branch: newLeader.branch,
          reason: `Daftari la Waumini: ${newLeader.name}`,
        });
        provisioned = true;
        provisionNote = isSw
          ? ' Ruhusa halisi ya Firebase imewekwa — anaweza kuingia sasa kwenye portal na app.'
          : ' Real Firebase role granted — they can now sign in on the portal and app.';
      } catch (err) {
        provisionNote = isSw
          ? ` Jina limehifadhiwa, lakini ruhusa ya Firebase haijatolewa: ${describeProvisionError(err)}`
          : ` Name saved, but the Firebase role was not granted: ${describeProvisionError(err)}`;
      }
    }

    setLeaderName('');
    setLeaderEmail('');
    setLeaderPhone('');
    setShowAddLeaderModal(false);

    toast({
      tone: provisioned ? 'success' : 'warning',
      title: isSw ? `Akaunti ya ${newLeader.name}` : `${newLeader.name}'s account`,
      message: (isSw
        ? `Imeundwa kwa wadhifa wa ${newLeader.roleTitleSw}.`
        : `Created with the ${newLeader.roleTitleSw} role.`) + provisionNote,
      durationMs: provisioned ? 5000 : 11000,
    });
  };

  const [pendingLeaderId, setPendingLeaderId] = useState<string | null>(null);

  const handleToggleLeaderStatus = async (lead: LeaderAccount) => {
    const suspending = lead.status === 'active';

    setLeaders(prev => prev.map(item =>
      item.id === lead.id ? { ...item, status: suspending ? 'suspended' : 'active' } : item
    ));

    const canProvision = AuthService.canGrantRoles(currentUser) && !currentUser?.isDemo;

    // Suspension only means something if the cloud claim goes away too.
    // Re-activation restores the role from the registry entry.
    if (!canProvision) {
      toast({
        tone: 'warning',
        title: isSw ? 'Hali imebadilika (kifaa hiki pekee)' : 'Status changed (this device only)',
        message: isSw
          ? 'Ili kuzuia au kurudisha ufikiaji wa Firebase, ingia kwa akaunti halisi ya Super Admin.'
          : 'Sign in with a real Super Admin account to suspend or restore Firebase access.',
      });
      return;
    }

    setPendingLeaderId(lead.id);
    try {
      if (suspending) {
        await revokeLeaderRole({
          email: lead.email,
          reason: `Imesitishwa: ${lead.name} (Daftari la Waumini)`,
        });
        toast({
          tone: 'success',
          title: isSw ? `${lead.name} amesitishwa` : `${lead.name} suspended`,
          message: isSw
            ? 'Wadhifa wake kwenye Firebase umeondolewa. Hatafungua portal tena.'
            : 'Their Firebase role was revoked. They can no longer open the portal.',
        });
      } else {
        await provisionLeaderRole({
          email: lead.email,
          role: lead.role,
          branch: lead.branch,
          reason: `Amewezeshwa tena: ${lead.name} (Daftari la Waumini)`,
        });
        toast({
          tone: 'success',
          title: isSw ? `${lead.name} amewezeshwa` : `${lead.name} reactivated`,
          message: isSw
            ? 'Wadhifa wake umerudishwa kwenye Firebase.'
            : 'Their Firebase role has been restored.',
        });
      }
    } catch (err) {
      // Roll the optimistic toggle back — the cloud never changed.
      setLeaders(prev => prev.map(item =>
        item.id === lead.id ? { ...item, status: lead.status } : item
      ));
      toast({
        tone: 'error',
        title: isSw ? 'Mabadiliko hayakufanikiwa' : 'Change failed',
        message: describeProvisionError(err),
        durationMs: 10000,
      });
    } finally {
      setPendingLeaderId(null);
    }
  };

  const handleResetPassword = (lead: LeaderAccount) => {
    // Honest copy: the portal cannot send a reset mail yet (that needs the
    // Firebase Admin SDK behind a callable), so we do not claim it did.
    toast({
      tone: 'info',
      title: isSw ? 'Weka upya nenosiri' : 'Password reset',
      message: isSw
        ? `Tuma kiungo cha Firebase kwa ${lead.email}. Kupanga upya nenosiri moja kwa moja kutoka portal bado hakujawekwa.`
        : `Send a Firebase reset link to ${lead.email}. In-portal password reset is not wired yet.`,
      durationMs: 7000,
    });
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
            <span>{isSw ? 'Utawala wa Watu & Akaunti' : 'People & Account Governance'}</span>
          </span>
          <h2 style={{ fontFamily: 'var(--font-cinzel)', fontSize: '1.65rem', fontWeight: 800, color: 'var(--text-headline)' }}>
            {activeSubTab === 'members' 
              ? (isSw ? 'Daftari la Waumini na Mahudhurio' : 'Church Members & Attendance')
              : (isSw ? 'Usimamizi wa Akaunti za Viongozi (RBAC)' : 'Leadership Accounts & Access Control')}
          </h2>
        </div>

        <div style={{ display: 'flex', gap: '0.65rem', flexWrap: 'wrap' }}>
          {activeSubTab === 'members' ? (
            (userRole === 'pastor' || userRole === 'secretary' || userRole === 'admin' || userRole === 'super_admin') && (
              <button 
                onClick={() => setShowAddModal(true)} 
                className="btn-primary"
              >
                <UserPlus size={16} />
                <span>{isSw ? 'Sajili Muumini Mpya' : 'Register New Member'}</span>
              </button>
            )
          ) : (
            (userRole === 'admin' || userRole === 'super_admin' || userRole === 'pastor') && (
              <button 
                onClick={() => setShowAddLeaderModal(true)} 
                className="btn-primary"
              >
                <KeyRound size={16} />
                <span>{isSw ? '+ Sajili Akaunti ya Kiongozi' : '+ New Leader Account'}</span>
              </button>
            )
          )}
        </div>
      </div>

      {/* Subtabs Switcher */}
      <div style={{ display: 'flex', gap: '0.65rem', borderBottom: '1px solid var(--border-subtle)', paddingBottom: '0.75rem' }}>
        <button
          onClick={() => setActiveSubTab('members')}
          style={{
            padding: '0.55rem 1.15rem',
            borderRadius: '20px',
            border: activeSubTab === 'members' ? '2px solid #0D52CD' : '1px solid var(--border-color)',
            backgroundColor: activeSubTab === 'members' ? 'rgba(13, 82, 205, 0.12)' : 'var(--surface)',
            color: activeSubTab === 'members' ? '#0D52CD' : 'var(--text-main)',
            fontWeight: 700,
            fontSize: '0.85rem',
            cursor: 'pointer',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.45rem'
          }}
        >
          <Users size={15} />
          <span>{isSw ? `Daftari la Waumini (${members.length})` : `Church Members (${members.length})`}</span>
        </button>

        <button
          onClick={() => setActiveSubTab('leaders')}
          style={{
            padding: '0.55rem 1.15rem',
            borderRadius: '20px',
            border: activeSubTab === 'leaders' ? '2px solid #0D52CD' : '1px solid var(--border-color)',
            backgroundColor: activeSubTab === 'leaders' ? 'rgba(13, 82, 205, 0.12)' : 'var(--surface)',
            color: activeSubTab === 'leaders' ? '#0D52CD' : 'var(--text-main)',
            fontWeight: 700,
            fontSize: '0.85rem',
            cursor: 'pointer',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '0.45rem'
          }}
        >
          <ShieldCheck size={15} />
          <span>{isSw ? `Akaunti za Viongozi (${leaders.length})` : `Leader Accounts (${leaders.length})`}</span>
        </button>
      </div>

      {activeSubTab === 'members' ? (
        <>
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
                        <td style={{ padding: '0.85rem 0.5rem', fontWeight: 700, color: 'var(--text-headline)' }}>
                          {m.fullName}
                        </td>
                        <td style={{ padding: '0.85rem 0.5rem' }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', color: 'var(--text-muted)' }}>
                            <Phone size={13} />
                            <span>{m.phone}</span>
                          </div>
                        </td>
                        <td style={{ padding: '0.85rem 0.5rem' }}>
                          <span className={`badge ${m.gender === 'Female' ? 'badge-purple' : 'badge-blue'}`} style={{ fontSize: '0.72rem' }}>
                            {m.gender === 'Female' ? 'Mwanamke' : 'Mwanaume'} • {m.ageGroup}
                          </span>
                        </td>
                        <td style={{ padding: '0.85rem 0.5rem' }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                            <Home size={13} style={{ color: 'var(--primary)' }} />
                            <span>{jum?.name || 'Sayuni Kuu'}</span>
                          </div>
                        </td>
                        <td style={{ padding: '0.85rem 0.5rem', fontWeight: 600 }}>
                          {m.role || '-'}
                        </td>
                        <td style={{ padding: '0.85rem 0.5rem' }}>
                          {m.isBaptized ? (
                            <span style={{ color: '#059669', display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.75rem', fontWeight: 700 }}>
                              <CheckCircle size={14} /> {isSw ? 'Amebatizwa' : 'Baptized'}
                            </span>
                          ) : (
                            <span style={{ color: '#dc2626', display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.75rem', fontWeight: 700 }}>
                              <XCircle size={14} /> {isSw ? 'Bado' : 'Not yet'}
                            </span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {filteredMembers.length === 0 && (
              <EmptyState
                icon={<Users size={20} />}
                title={isSw ? 'Hakuna muumini anayelingana' : 'No matching member'}
                hint={isSw
                  ? 'Badilisha neno la utafutaji au chagua jumuiya nyingine.'
                  : 'Try a different search term or choose another home cell.'}
                action={
                  (searchTerm || selectedJumuiya !== 'all') ? (
                    <button
                      type="button"
                      className="btn-secondary btn-sm"
                      onClick={() => { setSearchTerm(''); setSelectedJumuiya('all'); }}
                    >
                      {isSw ? 'Ondoa vichujio' : 'Clear filters'}
                    </button>
                  ) : undefined
                }
              />
            )}
          </div>
        </>
      ) : (
        /* LEADERSHIP ACCOUNTS & RBAC TAB */
        <div className="church-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem', flexWrap: 'wrap', gap: '0.75rem' }}>
            <div>
              <h3 style={{ fontSize: '1.15rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
                {isSw ? 'Watumishi na Viongozi Wenye Idhini ya Kuingia Kwenye Mfumo' : 'Authorized Church Leaders & System Roles'}
              </h3>
              <p style={{ fontSize: '0.82rem', color: 'var(--text-muted)', margin: '0.25rem 0 0 0' }}>
                {isSw ? 'Usimamizi wa usalama, ruhusa (RBAC), na akaunti rasmi za kanisa' : 'Security, role-based access control, and official credentials'}
              </p>
            </div>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.88rem' }}>
              <thead>
                <tr style={{ borderBottom: '2px solid var(--border-subtle)', color: 'var(--text-muted)' }}>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Kiongozi' : 'Leader Name'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Barua Pepe / Kuingilia' : 'Email (Login)'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Wadhifa & Ruhusa' : 'Role & Level'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Kituo / Tawi' : 'Station / Branch'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Hali' : 'Status'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Muingio wa Mwisho' : 'Last Active'}</th>
                  <th style={{ padding: '0.75rem 0.5rem', textAlign: 'right' }}>{isSw ? 'Vitendo' : 'Actions'}</th>
                </tr>
              </thead>
              <tbody>
                {leaders.map((lead) => (
                  <tr key={lead.id} style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                    <td style={{ padding: '0.85rem 0.5rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                        <div style={{
                          width: '32px',
                          height: '32px',
                          borderRadius: '50%',
                          backgroundColor: 'var(--primary)',
                          color: '#ffffff',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontWeight: 800,
                          fontSize: '0.8rem'
                        }}>
                          {lead.name.charAt(0)}
                        </div>
                        <div>
                          <div style={{ fontWeight: 800, color: 'var(--text-headline)' }}>{lead.name}</div>
                          <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{lead.phone}</div>
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '0.85rem 0.5rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', color: 'var(--primary-700)', fontWeight: 600 }}>
                        <Mail size={13} />
                        <span>{lead.email}</span>
                      </div>
                    </td>
                    <td style={{ padding: '0.85rem 0.5rem' }}>
                      <span className={`badge ${lead.role === 'super_admin' ? 'badge-gold' : (lead.role === 'pastor' ? 'badge-purple' : 'badge-blue')}`}>
                        <ShieldCheck size={12} />
                        <span>{lead.roleTitleSw}</span>
                      </span>
                    </td>
                    <td style={{ padding: '0.85rem 0.5rem', color: 'var(--text-muted)' }}>
                      {lead.branch}
                    </td>
                    <td style={{ padding: '0.85rem 0.5rem' }}>
                      <span style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.3rem',
                        fontSize: '0.75rem',
                        fontWeight: 700,
                        color: lead.status === 'active' ? '#059669' : '#dc2626'
                      }}>
                        <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: lead.status === 'active' ? '#059669' : '#dc2626' }} />
                        <span>{lead.status === 'active' ? (isSw ? 'Hai (Active)' : 'Active') : (isSw ? 'Imesitishwa' : 'Suspended')}</span>
                      </span>
                    </td>
                    <td style={{ padding: '0.85rem 0.5rem', fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                      {lead.lastLogin}
                    </td>
                    <td style={{ padding: '0.85rem 0.5rem', textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '0.45rem' }}>
                        <button
                          onClick={() => handleResetPassword(lead)}
                          className="btn-secondary"
                          style={{ padding: '0.35rem 0.65rem', fontSize: '0.74rem' }}
                          title={isSw ? 'Weka upya nenosiri la kiongozi huyu' : 'Reset password'}
                        >
                          <Lock size={12} />
                          <span>{isSw ? 'Nenosiri' : 'Password'}</span>
                        </button>

                        {lead.role !== 'super_admin' && (
                          <button
                            onClick={() => void handleToggleLeaderStatus(lead)}
                            disabled={pendingLeaderId === lead.id}
                            aria-busy={pendingLeaderId === lead.id}
                            style={{
                              padding: '0.35rem 0.65rem',
                              fontSize: '0.74rem',
                              borderRadius: '6px',
                              border: lead.status === 'active' ? '1px solid #fca5a5' : '1px solid #86efac',
                              backgroundColor: lead.status === 'active' ? '#fee2e2' : '#dcfce7',
                              color: lead.status === 'active' ? '#991b1b' : '#166534',
                              cursor: 'pointer',
                              fontWeight: 700
                            }}
                          >
                            {lead.status === 'active' ? (isSw ? 'Sitisha' : 'Suspend') : (isSw ? 'Wezesha' : 'Activate')}
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {leaders.length === 0 && (
            <EmptyState
              icon={<ShieldCheck size={20} />}
              title={isSw ? 'Hakuna akaunti ya kiongozi' : 'No leader accounts yet'}
              hint={isSw
                ? 'Sajili akaunti ya kwanza ya kiongozi ili mtu aweze kuingia kwenye portal.'
                : 'Register the first leader account so someone can sign in to the portal.'}
            />
          )}
        </div>
      )}
      {/* Modal: Add New Leader Account */}
      <Modal
        open={showAddLeaderModal}
        onClose={() => setShowAddLeaderModal(false)}
        width={540}
        title={isSw ? 'Sajili Akaunti Mpya ya Kiongozi' : 'New Leader Account'}
        subtitle={isSw
          ? 'Unda kitambulisho rasmi cha kuingia mfumo. Mhusika lazima awe amejisajili kwanza kwenye app ili wadhifa utumike kwenye Firebase.'
          : 'Create official portal access. The person must have signed up in the member app first for the role to apply in Firebase.'}
      >
        <form onSubmit={handleAddLeader}>
          <div className="form-group">
            <label className="form-label" htmlFor="lead-name">{isSw ? 'Jina Kamili la Kiongozi' : 'Leader Full Name'} *</label>
            <input
              id="lead-name"
              type="text"
              className="form-input"
              placeholder="Mfano: Mchungaji / Shemasi..."
              value={leaderName}
              onChange={(e) => setLeaderName(e.target.value)}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="lead-email">{isSw ? 'Barua Pepe Rasmi (Email/Login)' : 'Official Email'} *</label>
            <input
              id="lead-email"
              type="email"
              className="form-input"
              placeholder="kiongozi@zionjerusalem.org"
              value={leaderEmail}
              onChange={(e) => setLeaderEmail(e.target.value)}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="lead-phone">{isSw ? 'Namba ya Simu (WhatsApp)' : 'Phone Number'}</label>
            <input
              id="lead-phone"
              type="text"
              className="form-input"
              placeholder="+255 7..."
              value={leaderPhone}
              onChange={(e) => setLeaderPhone(e.target.value)}
            />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="lead-role">{isSw ? 'Wadhifa & Ruhusa za Mfumo (Role)' : 'Role & Access Level'}</label>
            <select
              id="lead-role"
              className="form-select"
              value={leaderRole}
              onChange={(e) => setLeaderRole(e.target.value as UserRole)}
            >
              <option value="pastor">{isSw ? 'Mchungaji / Askofu (Pastoral Access)' : 'Pastor / Bishop'}</option>
              <option value="secretary">{isSw ? 'Katibu wa Kanisa (Full Office & Records)' : 'General Secretary'}</option>
              <option value="treasurer">{isSw ? 'Mhazini (Financial Ledger & Tithes)' : 'Treasurer'}</option>
              <option value="deacon">{isSw ? 'Mzee wa Kanisa / Shemasi (Deacons & Elders)' : 'Elder / Deacon'}</option>
              <option value="usher">{isSw ? 'Mkaribishaji / Usher (Mapokezi ya Wageni)' : 'Usher (Visitor Reception)'}</option>
              <option value="jumuiya_leader">{isSw ? 'Kiongozi wa Jumuiya (Home Cell Reports)' : 'Cell Leader'}</option>
              <option value="choir_leader">{isSw ? 'Kiongozi wa Muziki na Kwaya' : 'Choir Director'}</option>
              <option value="children_teacher">{isSw ? 'Mwalimu wa Watoto / Shule ya Jumapili' : 'Sunday School Teacher'}</option>
              <option value="admin">{isSw ? 'Msimamizi wa Mfumo (Admin)' : 'Administrator'}</option>
            </select>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="lead-branch">{isSw ? 'Tawi la Kanisa' : 'Church Branch'}</label>
            <input
              id="lead-branch"
              type="text"
              className="form-input"
              value={leaderBranch}
              onChange={(e) => setLeaderBranch(e.target.value)}
            />
          </div>

          <div className="ui-modal-footer">
            <button type="submit" className="btn-primary">
              {isSw ? 'Unda & Wezesha Akaunti' : 'Create & Enable Account'}
            </button>
            <button type="button" onClick={() => setShowAddLeaderModal(false)} className="btn-secondary">
              {isSw ? 'Ghairi' : 'Cancel'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Modal: Add New Member */}
      <Modal
        open={showAddModal}
        onClose={() => setShowAddModal(false)}
        width={520}
        title={isSw ? 'Sajili Mshirika Mpya wa Sayuni' : 'Register New Member'}
        subtitle={isSw
          ? 'Ingiza taarifa za muumini kwenye kanzidata rasmi ya kanisa.'
          : 'Enter member details into the official church roster.'}
      >
        <form onSubmit={handleAddMember}>
          <div className="form-group">
            <label className="form-label" htmlFor="mem-name">{isSw ? 'Jina Kamili' : 'Full Name'} *</label>
            <input
              id="mem-name"
              type="text"
              className="form-input"
              placeholder="Mfano: Daudi Emanuel Mwita"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="mem-phone">{isSw ? 'Namba ya Simu' : 'Phone Number'}</label>
            <input
              id="mem-phone"
              type="tel"
              inputMode="tel"
              className="form-input"
              placeholder="Mfano: 0754 112 233"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
            <div className="form-group">
              <label className="form-label" htmlFor="mem-gender">{isSw ? 'Jinsia' : 'Gender'}</label>
              <select
                id="mem-gender"
                className="form-select"
                value={gender}
                onChange={(e) => setGender(e.target.value as 'Male' | 'Female')}
              >
                <option value="Male">{isSw ? 'Mwanaume' : 'Male'}</option>
                <option value="Female">{isSw ? 'Mwanamke' : 'Female'}</option>
              </select>
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="mem-age">{isSw ? 'Kundi la Umri' : 'Age Group'}</label>
              <select
                id="mem-age"
                className="form-select"
                value={ageGroup}
                onChange={(e) => setAgeGroup(e.target.value as 'Adult' | 'Youth' | 'Child')}
              >
                <option value="Adult">{isSw ? 'Mtu Mzima' : 'Adult'}</option>
                <option value="Youth">{isSw ? 'Kijana' : 'Youth'}</option>
                <option value="Child">{isSw ? 'Mtoto / Sunday School' : 'Child'}</option>
              </select>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="mem-jumuiya">{isSw ? 'Jumuiya ya Nyumbani' : 'Home Cell Group'}</label>
            <select
              id="mem-jumuiya"
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
            <label className="form-label" htmlFor="mem-role">{isSw ? 'Wadhifa au Idara ya Huduma' : 'Ministry Role'}</label>
            <input
              id="mem-role"
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

          <div className="ui-modal-footer">
            <button type="submit" className="btn-primary">
              {isSw ? 'Kamilisha Usajili' : 'Register Member'}
            </button>
            <button type="button" onClick={() => setShowAddModal(false)} className="btn-secondary">
              {isSw ? 'Ghairi' : 'Cancel'}
            </button>
          </div>
        </form>
      </Modal>

    </div>
  );
};
