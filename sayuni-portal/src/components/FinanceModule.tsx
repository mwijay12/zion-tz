import React, { useState } from 'react';
import { 
  Plus, 
  Printer, 
  CheckCircle2, 
  Clock, 
  DollarSign, 
  ShieldCheck,
  Wallet,
  Calendar
} from 'lucide-react';
import type { Language, UserRole, FinancialRecord, FinancialProject, ChurchExpense } from '../types';
import { CHURCH_PROFILE } from '../data/mockData';

interface FinanceModuleProps {
  language: Language;
  userRole: UserRole;
  finances: FinancialRecord[];
  setFinances: React.Dispatch<React.SetStateAction<FinancialRecord[]>>;
  projects: FinancialProject[];
  setProjects: React.Dispatch<React.SetStateAction<FinancialProject[]>>;
  expenses: ChurchExpense[];
  setExpenses: React.Dispatch<React.SetStateAction<ChurchExpense[]>>;
}

export const FinanceModule: React.FC<FinanceModuleProps> = ({
  language,
  userRole,
  finances,
  setFinances,
  projects,
  setProjects,
  expenses,
  setExpenses
}) => {
  const isSw = language === 'sw';
  const [activeSubTab, setActiveSubTab] = useState<'income' | 'expenses' | 'projects' | 'report'>('income');
  const [showAddIncomeModal, setShowAddIncomeModal] = useState(false);
  const [showAddExpenseModal, setShowAddExpenseModal] = useState(false);

  // Form states for new Income
  const [newType, setNewType] = useState<'tithe' | 'offering' | 'project' | 'benevolence' | 'jumuiya'>('tithe');
  const [newAmount, setNewAmount] = useState<string>('');
  const [newDonor, setNewDonor] = useState<string>('');
  const [newMethod, setNewMethod] = useState<'Cash' | 'M-Pesa' | 'Tigo Pesa' | 'Airtel Money' | 'Bank'>('M-Pesa');
  const [newRef, setNewRef] = useState<string>('');
  const [newNotes, setNewNotes] = useState<string>('');

  // Form states for new Expense
  const [expTitle, setExpTitle] = useState('');
  const [expCategory, setExpCategory] = useState<'Operations' | 'Evangelism' | 'Maintenance' | 'Benevolence' | 'Utilities'>('Operations');
  const [expAmount, setExpAmount] = useState('');

  const totalIncome = finances.reduce((acc, curr) => acc + curr.amount, 0);
  const totalExpenses = expenses.reduce((acc, curr) => acc + curr.amount, 0);
  const balance = totalIncome - totalExpenses;

  const handleAddIncome = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newAmount || Number(newAmount) <= 0) return;

    const record: FinancialRecord = {
      id: `fin-${Date.now().toString().slice(-4)}`,
      date: new Date().toISOString().split('T')[0],
      type: newType,
      category: newType === 'tithe' ? 'Fungu la Kumi' : newType === 'offering' ? 'Sadaka ya Ibada' : newType === 'project' ? 'Mchango wa Mradi' : 'Msaada / Jumuiya',
      amount: Number(newAmount),
      donorName: newDonor || (isSw ? 'Muumini Asiyetajwa' : 'Anonymous Member'),
      paymentMethod: newMethod,
      referenceNumber: newRef,
      notes: newNotes
    };

    setFinances([record, ...finances]);

    // If it's for a project, update the active project
    if (newType === 'project' && projects.length > 0) {
      setProjects(projects.map(p => p.id === projects[0].id ? { ...p, currentAmount: p.currentAmount + Number(newAmount) } : p));
    }

    setNewAmount('');
    setNewDonor('');
    setNewRef('');
    setNewNotes('');
    setShowAddIncomeModal(false);
  };

  const handleAddExpense = (e: React.FormEvent) => {
    e.preventDefault();
    if (!expAmount || Number(expAmount) <= 0 || !expTitle) return;

    const newExp: ChurchExpense = {
      id: `exp-${Date.now().toString().slice(-4)}`,
      date: new Date().toISOString().split('T')[0],
      title: expTitle,
      category: expCategory,
      amount: Number(expAmount),
      approvedBy: userRole === 'pastor' ? CHURCH_PROFILE.headPastor : (isSw ? 'Inasubiri Uhakiki' : 'Pending Approval'),
      isApproved: userRole === 'pastor'
    };

    setExpenses([newExp, ...expenses]);
    setExpTitle('');
    setExpAmount('');
    setShowAddExpenseModal(false);
  };

  const handleApproveExpense = (id: string) => {
    setExpenses(expenses.map(e => e.id === id ? { ...e, isApproved: true, approvedBy: CHURCH_PROFILE.headPastor } : e));
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Title & Action Bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <span className="badge badge-purple" style={{ marginBottom: '0.35rem', display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
            <Wallet size={13} />
            <span>{isSw ? 'Uwakili na Uwazi wa Fedha' : 'Financial Stewardship & Accountability'}</span>
          </span>
          <h2 style={{ fontFamily: 'var(--font-cinzel)', fontSize: '1.65rem', fontWeight: 800, color: 'var(--text-headline)' }}>
            {isSw ? 'Usimamizi wa Fedha za Kanisa' : 'Church Financial Ledger'}
          </h2>
        </div>

        <div style={{ display: 'flex', gap: '0.65rem' }}>
          {(userRole === 'pastor' || userRole === 'treasurer') && (
            <>
              <button 
                onClick={() => setShowAddIncomeModal(true)} 
                className="btn-primary"
                style={{ fontSize: '0.85rem' }}
              >
                <Plus size={16} />
                <span>{isSw ? 'Rekodi Sadaka / Fungu' : 'Add Tithe / Offering'}</span>
              </button>
              <button 
                onClick={() => setShowAddExpenseModal(true)} 
                className="btn-secondary"
                style={{ fontSize: '0.85rem' }}
              >
                <DollarSign size={16} />
                <span>{isSw ? 'Rekodi Matumizi' : 'Record Expense'}</span>
              </button>
            </>
          )}
        </div>
      </div>

      {/* Financial Summary Cards */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
        gap: '1.15rem'
      }}>
        {/* Total Collections */}
        <div className="church-card">
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>
            {isSw ? 'JUMLA YA MAPATO' : 'TOTAL REVENUE'}
          </span>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--emerald-600)', marginTop: '0.35rem' }}>
            Tsh {totalIncome.toLocaleString()}
          </div>
          <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
            {isSw ? 'Mafungu, Sadaka & Michango' : 'Tithes, Offerings & Pledges'}
          </span>
        </div>

        {/* Total Expenses */}
        <div className="church-card">
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>
            {isSw ? 'JUMLA YA MATUMIZI' : 'TOTAL EXPENSES'}
          </span>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: '#e11d48', marginTop: '0.35rem' }}>
            Tsh {totalExpenses.toLocaleString()}
          </div>
          <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
            {isSw ? 'Uendeshaji, Umeme & Matengenezo' : 'Operations, Utilities & Care'}
          </span>
        </div>

        {/* Net Balance */}
        <div className="church-card gold-border">
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontWeight: 600 }}>
            {isSw ? 'SALIO LILILOPO KANISANI' : 'NET CHURCH BALANCE'}
          </span>
          <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--primary-700)', marginTop: '0.35rem' }}>
            Tsh {balance.toLocaleString()}
          </div>
          <span style={{ fontSize: '0.78rem', color: 'var(--gold-700)', fontWeight: 600 }}>
            {isSw ? 'Akaunti ya Benki & M-Pesa' : 'Bank Account & Cash Reserves'}
          </span>
        </div>
      </div>

      {/* Sub-Navigation Tabs */}
      <div style={{ display: 'flex', gap: '0.5rem', borderBottom: '1px solid var(--border-subtle)', paddingBottom: '0.5rem' }}>
        <button
          onClick={() => setActiveSubTab('income')}
          className={`nav-item ${activeSubTab === 'income' ? 'active' : ''}`}
          style={{ padding: '0.45rem 1rem', fontSize: '0.85rem' }}
        >
          <span>{isSw ? 'Mapato na Sadaka' : 'Income & Tithes'}</span>
        </button>
        <button
          onClick={() => setActiveSubTab('expenses')}
          className={`nav-item ${activeSubTab === 'expenses' ? 'active' : ''}`}
          style={{ padding: '0.45rem 1rem', fontSize: '0.85rem' }}
        >
          <span>{isSw ? 'Matumizi ya Kanisa' : 'Church Expenses'}</span>
        </button>
        <button
          onClick={() => setActiveSubTab('projects')}
          className={`nav-item ${activeSubTab === 'projects' ? 'active' : ''}`}
          style={{ padding: '0.45rem 1rem', fontSize: '0.85rem' }}
        >
          <span>{isSw ? 'Miradi ya Maendeleo' : 'Building Projects'}</span>
        </button>
        <button
          onClick={() => setActiveSubTab('report')}
          className={`nav-item ${activeSubTab === 'report' ? 'active' : ''}`}
          style={{ padding: '0.45rem 1rem', fontSize: '0.85rem' }}
        >
          <Printer size={15} />
          <span>{isSw ? 'Ripoti Kamili (Print Statement)' : 'Statement Report'}</span>
        </button>
      </div>

      {/* Tab 1: Income Ledger */}
      {activeSubTab === 'income' && (
        <div className="church-card">
          <h3 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '1rem', color: 'var(--text-headline)' }}>
            {isSw ? 'Kumbukumbu ya Sadaka, Mafungu ya Kumi na Michango' : 'Tithe & Offering Transaction Ledger'}
          </h3>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.88rem' }}>
              <thead>
                <tr style={{ borderBottom: '2px solid var(--border-subtle)', color: 'var(--text-muted)' }}>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Tarehe' : 'Date'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Aina ya Sadaka' : 'Type'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Mtoa Sadaka' : 'Donor / Member'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Njia ya Malipo' : 'Channel'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Kumbukumbu / Ref' : 'Ref Code'}</th>
                  <th style={{ padding: '0.75rem 0.5rem', textAlign: 'right' }}>{isSw ? 'Kiasi (Tsh)' : 'Amount'}</th>
                </tr>
              </thead>
              <tbody>
                {finances.map((rec) => (
                  <tr key={rec.id} style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                    <td style={{ padding: '0.75rem 0.5rem', color: 'var(--text-muted)' }}>{rec.date}</td>
                    <td style={{ padding: '0.75rem 0.5rem', fontWeight: 600 }}>
                      <span className={`badge ${rec.type === 'tithe' ? 'badge-blue' : rec.type === 'project' ? 'badge-gold' : 'badge-emerald'}`}>
                        {rec.category}
                      </span>
                    </td>
                    <td style={{ padding: '0.75rem 0.5rem' }}>{rec.donorName || '—'}</td>
                    <td style={{ padding: '0.75rem 0.5rem' }}>
                      <span style={{ background: 'var(--bg-app)', padding: '0.2rem 0.5rem', borderRadius: '4px', fontSize: '0.78rem', fontWeight: 600 }}>
                        {rec.paymentMethod}
                      </span>
                    </td>
                    <td style={{ padding: '0.75rem 0.5rem', fontFamily: 'monospace', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                      {rec.referenceNumber || '—'}
                    </td>
                    <td style={{ padding: '0.75rem 0.5rem', textAlign: 'right', fontWeight: 700, color: 'var(--emerald-600)' }}>
                      {rec.amount.toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab 2: Expenses */}
      {activeSubTab === 'expenses' && (
        <div className="church-card">
          <h3 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '1rem', color: 'var(--text-headline)' }}>
            {isSw ? 'Kumbukumbu ya Matumizi na Idhini ya Kichungaji' : 'Church Expenses & Pastoral Approval'}
          </h3>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.88rem' }}>
              <thead>
                <tr style={{ borderBottom: '2px solid var(--border-subtle)', color: 'var(--text-muted)' }}>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Tarehe' : 'Date'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Maelezo ya Matumizi' : 'Expense Details'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Idara' : 'Category'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Kiasi (Tsh)' : 'Amount'}</th>
                  <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Hali ya Idhini' : 'Approval Status'}</th>
                  {userRole === 'pastor' && <th style={{ padding: '0.75rem 0.5rem' }}>{isSw ? 'Kitendo' : 'Action'}</th>}
                </tr>
              </thead>
              <tbody>
                {expenses.map((exp) => (
                  <tr key={exp.id} style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                    <td style={{ padding: '0.75rem 0.5rem', color: 'var(--text-muted)' }}>{exp.date}</td>
                    <td style={{ padding: '0.75rem 0.5rem', fontWeight: 600 }}>{exp.title}</td>
                    <td style={{ padding: '0.75rem 0.5rem' }}>
                      <span className="badge badge-blue">{exp.category}</span>
                    </td>
                    <td style={{ padding: '0.75rem 0.5rem', fontWeight: 700, color: '#e11d48' }}>
                      {exp.amount.toLocaleString()}
                    </td>
                    <td style={{ padding: '0.75rem 0.5rem' }}>
                      {exp.isApproved ? (
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.3rem', color: 'var(--emerald-600)', fontSize: '0.8rem', fontWeight: 600 }}>
                          <CheckCircle2 size={14} />
                          {isSw ? 'Imeidhinishwa' : 'Approved'}
                        </span>
                      ) : (
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.3rem', color: 'var(--gold-600)', fontSize: '0.8rem', fontWeight: 600 }}>
                          <Clock size={14} />
                          {isSw ? 'Inasubiri Idhini' : 'Pending'}
                        </span>
                      )}
                    </td>
                    {userRole === 'pastor' && (
                      <td style={{ padding: '0.75rem 0.5rem' }}>
                        {!exp.isApproved && (
                          <button
                            onClick={() => handleApproveExpense(exp.id)}
                            className="btn-gold"
                            style={{ padding: '0.3rem 0.75rem', fontSize: '0.75rem' }}
                          >
                            <ShieldCheck size={14} />
                            <span>{isSw ? 'Idhinisha' : 'Approve'}</span>
                          </button>
                        )}
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab 3: Projects */}
      {activeSubTab === 'projects' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          {projects.map((proj) => {
            const percent = Math.round((proj.currentAmount / proj.targetAmount) * 100);
            return (
              <div key={proj.id} className="church-card gold-border" style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '0.5rem' }}>
                  <div>
                    <span className="badge badge-purple" style={{ marginBottom: '0.3rem' }}>
                      {proj.status.toUpperCase()}
                    </span>
                    <h3 style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--text-headline)' }}>
                      {isSw ? proj.title : proj.titleEn}
                    </h3>
                    <p style={{ fontSize: '0.88rem', color: 'var(--text-muted)' }}>{proj.description}</p>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <span style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--primary)' }}>
                      {percent}%
                    </span>
                  </div>
                </div>

                <div>
                  <div className="progress-container" style={{ height: '14px' }}>
                    <div className="progress-fill-purple" style={{ width: `${percent}%` }} />
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '0.5rem', fontSize: '0.86rem' }}>
                    <span style={{ fontWeight: 700, color: 'var(--emerald)' }}>
                      {isSw ? 'Zilizokusanywa:' : 'Raised:'} Tsh {proj.currentAmount.toLocaleString()}
                    </span>
                    <span style={{ color: 'var(--text-muted)' }}>
                      {isSw ? 'Lengo:' : 'Target:'} Tsh {proj.targetAmount.toLocaleString()}
                    </span>
                  </div>
                </div>

                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                    <Calendar size={13} />
                    <span>{isSw ? 'Mwisho wa Mradi:' : 'Target Date:'} {proj.targetDate}</span>
                  </span>
                  <span>{isSw ? 'Kiasi Kilichobaki:' : 'Remaining:'} Tsh {(proj.targetAmount - proj.currentAmount).toLocaleString()}</span>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Tab 4: Printable Financial Statement */}
      {activeSubTab === 'report' && (
        <div className="church-card" style={{ padding: '2.5rem', background: '#ffffff', color: '#0f172a' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '2px solid #1e3a8a', paddingBottom: '1rem', marginBottom: '1.5rem' }}>
            <div>
              <h2 style={{ fontFamily: 'var(--font-cinzel)', fontSize: '1.4rem', color: '#1e3a8a', fontWeight: 800 }}>
                {CHURCH_PROFILE.name}
              </h2>
              <p style={{ fontSize: '0.85rem', color: '#64748b' }}>
                {CHURCH_PROFILE.location} • {CHURCH_PROFILE.phone}
              </p>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 700, marginTop: '0.4rem', color: '#d97706' }}>
                {isSw ? 'TAARIFA YA MAPATO NA MATUMIZI YA FEDHA' : 'MONTHLY FINANCIAL STATEMENT REPORT'}
              </h3>
            </div>
            <button 
              onClick={() => window.print()} 
              className="btn-primary no-print"
              style={{ padding: '0.5rem 1rem', fontSize: '0.85rem' }}
            >
              <Printer size={16} />
              <span>{isSw ? 'Chapisha Taarifa (Print / PDF)' : 'Print Report'}</span>
            </button>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', marginBottom: '1.5rem' }}>
            <div>
              <h4 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#059669', marginBottom: '0.5rem' }}>
                1. {isSw ? 'MUHTASARI WA MAPATO' : 'INCOME SUMMARY'}
              </h4>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.35rem 0', borderBottom: '1px solid #e2e8f0' }}>
                <span>{isSw ? 'Mafungu ya Kumi' : 'Tithes'}</span>
                <strong>Tsh {finances.filter(f => f.type === 'tithe').reduce((a, c) => a + c.amount, 0).toLocaleString()}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.35rem 0', borderBottom: '1px solid #e2e8f0' }}>
                <span>{isSw ? 'Sadaka za Ibada Kuu' : 'Sunday Offerings'}</span>
                <strong>Tsh {finances.filter(f => f.type === 'offering').reduce((a, c) => a + c.amount, 0).toLocaleString()}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.35rem 0', borderBottom: '1px solid #e2e8f0' }}>
                <span>{isSw ? 'Michango ya Miradi' : 'Building Funds'}</span>
                <strong>Tsh {finances.filter(f => f.type === 'project').reduce((a, c) => a + c.amount, 0).toLocaleString()}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.35rem 0', borderBottom: '1px solid #e2e8f0' }}>
                <span>{isSw ? 'Sadaka za Jumuiya' : 'Cell Group Offerings'}</span>
                <strong>Tsh {finances.filter(f => f.type === 'jumuiya').reduce((a, c) => a + c.amount, 0).toLocaleString()}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.5rem 0', fontWeight: 800, color: '#059669', fontSize: '1rem' }}>
                <span>{isSw ? 'Jumla ya Mapato' : 'Total Revenue'}</span>
                <span>Tsh {totalIncome.toLocaleString()}</span>
              </div>
            </div>

            <div>
              <h4 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#e11d48', marginBottom: '0.5rem' }}>
                2. {isSw ? 'MUHTASARI WA MATUMIZI' : 'EXPENSES SUMMARY'}
              </h4>
              {expenses.map(e => (
                <div key={e.id} style={{ display: 'flex', justifyContent: 'space-between', padding: '0.35rem 0', borderBottom: '1px solid #e2e8f0' }}>
                  <span>{e.title}</span>
                  <strong>Tsh {e.amount.toLocaleString()}</strong>
                </div>
              ))}
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.5rem 0', fontWeight: 800, color: '#e11d48', fontSize: '1rem' }}>
                <span>{isSw ? 'Jumla ya Matumizi' : 'Total Expenses'}</span>
                <span>Tsh {totalExpenses.toLocaleString()}</span>
              </div>
            </div>
          </div>

          <div style={{ background: '#f8fafc', padding: '1rem', borderRadius: '8px', border: '1.5px solid #cbd5e1', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '1.05rem', fontWeight: 800, color: '#1e3a8a' }}>
              {isSw ? 'SALIO KUU LINALOBAKI BENKI / MIKONONI' : 'NET BALANCE CARRIED FORWARD'}:
            </span>
            <span style={{ fontSize: '1.35rem', fontWeight: 800, color: '#059669' }}>
              Tsh {balance.toLocaleString()}
            </span>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '3rem', paddingTop: '1rem', borderTop: '1px dashed #cbd5e1', fontSize: '0.85rem', color: '#64748b' }}>
            <div style={{ textAlign: 'center' }}>
              <div style={{ borderBottom: '1px solid #000', width: '180px', margin: '0 auto 0.4rem auto' }}></div>
              <span>{CHURCH_PROFILE.headPastor}</span><br />
              <strong>{isSw ? 'Mchungaji Kiongozi' : 'Senior Pastor'}</strong>
            </div>
            <div style={{ textAlign: 'center' }}>
              <div style={{ borderBottom: '1px solid #000', width: '180px', margin: '0 auto 0.4rem auto' }}></div>
              <span>{CHURCH_PROFILE.churchTreasurer}</span><br />
              <strong>{isSw ? 'Mhazini wa Kanisa' : 'Church Treasurer'}</strong>
            </div>
          </div>
        </div>
      )}

      {/* Modal: Add New Income */}
      {showAddIncomeModal && (
        <div style={{
          position: 'fixed',
          top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0, 0, 0, 0.65)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100,
          padding: '1rem'
        }}>
          <div className="church-card" style={{ maxWidth: '500px', width: '100%', maxHeight: '90vh', overflowY: 'auto' }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '1rem', color: 'var(--text-headline)' }}>
              {isSw ? 'Rekodi Sadaka, Fungu la Kumi au Mchango' : 'Record New Income / Tithe'}
            </h3>

            <form onSubmit={handleAddIncome}>
              <div className="form-group">
                <label className="form-label">{isSw ? 'Aina ya Mapato' : 'Income Category'}</label>
                <select 
                  className="form-select"
                  value={newType}
                  onChange={(e) => setNewType(e.target.value as any)}
                >
                  <option value="tithe">{isSw ? 'Fungu la Kumi' : 'Tithe'}</option>
                  <option value="offering">{isSw ? 'Sadaka ya Ibada Kuu' : 'Sunday Offering'}</option>
                  <option value="project">{isSw ? 'Mchango wa Ujenzi / Mradi' : 'Building / Project Pledge'}</option>
                  <option value="jumuiya">{isSw ? 'Sadaka ya Jumuiya' : 'Cell Group Offering'}</option>
                  <option value="benevolence">{isSw ? 'Mfuko wa Huruma' : 'Benevolence Fund'}</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">{isSw ? 'Kiasi (Tsh)' : 'Amount (Tsh)'}</label>
                <input 
                  type="number" 
                  className="form-input"
                  placeholder="Mfano: 50000"
                  value={newAmount}
                  onChange={(e) => setNewAmount(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">{isSw ? 'Jina la Mtoaji (Hiari)' : 'Member Name (Optional)'}</label>
                <input 
                  type="text" 
                  className="form-input"
                  placeholder={isSw ? 'Jina la muumini au acha tupu kwa siri' : 'Leave empty for anonymous'}
                  value={newDonor}
                  onChange={(e) => setNewDonor(e.target.value)}
                />
              </div>

              <div className="form-group">
                <label className="form-label">{isSw ? 'Njia ya Malipo' : 'Payment Method'}</label>
                <select 
                  className="form-select"
                  value={newMethod}
                  onChange={(e) => setNewMethod(e.target.value as any)}
                >
                  <option value="M-Pesa">M-Pesa</option>
                  <option value="Cash">{isSw ? 'Pesa Taslimu (Cash)' : 'Cash'}</option>
                  <option value="Tigo Pesa">Tigo Pesa</option>
                  <option value="Airtel Money">Airtel Money</option>
                  <option value="Bank">{isSw ? 'Benki (CRDB)' : 'Bank Transfer'}</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">{isSw ? 'Kumbukumbu ya Muamala / Ref' : 'Transaction Reference / Code'}</label>
                <input 
                  type="text" 
                  className="form-input"
                  placeholder="Mfano: QA8823901"
                  value={newRef}
                  onChange={(e) => setNewRef(e.target.value)}
                />
              </div>

              <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1.5rem' }}>
                <button type="submit" className="btn-primary" style={{ flex: 1 }}>
                  {isSw ? 'Hifadhi Kumbukumbu' : 'Save Record'}
                </button>
                <button 
                  type="button" 
                  onClick={() => setShowAddIncomeModal(false)}
                  className="btn-secondary"
                >
                  {isSw ? 'Ghairi' : 'Cancel'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Add New Expense */}
      {showAddExpenseModal && (
        <div style={{
          position: 'fixed',
          top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0, 0, 0, 0.65)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100,
          padding: '1rem'
        }}>
          <div className="church-card" style={{ maxWidth: '500px', width: '100%' }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '1rem', color: 'var(--text-headline)' }}>
              {isSw ? 'Rekodi Matumizi Mapya ya Kanisa' : 'Record New Expense'}
            </h3>

            <form onSubmit={handleAddExpense}>
              <div className="form-group">
                <label className="form-label">{isSw ? 'Maelezo ya Matumizi' : 'Expense Title'}</label>
                <input 
                  type="text" 
                  className="form-input"
                  placeholder={isSw ? 'Mfano: Malipo ya Umeme LUKU' : 'e.g. Utility Bills'}
                  value={expTitle}
                  onChange={(e) => setExpTitle(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">{isSw ? 'Idara / Aina' : 'Category'}</label>
                <select 
                  className="form-select"
                  value={expCategory}
                  onChange={(e) => setExpCategory(e.target.value as any)}
                >
                  <option value="Operations">{isSw ? 'Uendeshaji wa Ibada' : 'Operations'}</option>
                  <option value="Utilities">{isSw ? 'Umeme & Maji' : 'Utilities'}</option>
                  <option value="Maintenance">{isSw ? 'Matengenezo ya Jengo' : 'Maintenance'}</option>
                  <option value="Benevolence">{isSw ? 'Msaada wa Wajane/Wagonjwa' : 'Benevolence'}</option>
                  <option value="Evangelism">{isSw ? 'Uinjilisti & Mikutano' : 'Evangelism'}</option>
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">{isSw ? 'Kiasi (Tsh)' : 'Amount (Tsh)'}</label>
                <input 
                  type="number" 
                  className="form-input"
                  placeholder="Mfano: 150000"
                  value={expAmount}
                  onChange={(e) => setExpAmount(e.target.value)}
                  required
                />
              </div>

              <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1.5rem' }}>
                <button type="submit" className="btn-primary" style={{ flex: 1 }}>
                  {isSw ? 'Wasilisha Matumizi' : 'Submit Expense'}
                </button>
                <button 
                  type="button" 
                  onClick={() => setShowAddExpenseModal(false)}
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
