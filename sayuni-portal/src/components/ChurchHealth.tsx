import React from 'react';
import {
  BarChart3,
  Wallet,
  TrendingDown,
  Users,
  FileCheck2,
  Target,
  ShieldCheck,
  CheckCircle2,
  Clock3
} from 'lucide-react';
import type {
  Language,
  JumuiyaGroup,
  JumuiyaReport,
  FinancialRecord,
  FinancialProject,
  ChurchExpense
} from '../types';

interface ChurchHealthProps {
  language: Language;
  reports: JumuiyaReport[];
  finances: FinancialRecord[];
  expenses: ChurchExpense[];
  projects: FinancialProject[];
  groups: JumuiyaGroup[];
}

const monthKey = (date?: string): string =>
  date && date.length >= 7 ? date.slice(0, 7) : '';

const shiftMonth = (key: string, offset: number): string => {
  const [year, month] = key.split('-').map(Number);
  const date = new Date(year, month - 1 + offset, 1);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
};

const formatMoney = (amount: number): string =>
  `TSh ${Math.round(amount).toLocaleString('en-US')}`;

const monthName = (key: string, isSw: boolean): string => {
  const [year, month] = key.split('-').map(Number);
  return new Date(year, month - 1, 1).toLocaleDateString(isSw ? 'sw-TZ' : 'en-GB', {
    month: 'long',
    year: 'numeric'
  });
};

const shortMonth = (key: string, isSw: boolean): string => {
  const [year, month] = key.split('-').map(Number);
  return new Date(year, month - 1, 1).toLocaleDateString(isSw ? 'sw-TZ' : 'en-GB', {
    month: 'short'
  });
};

export const ChurchHealth: React.FC<ChurchHealthProps> = ({
  language,
  reports,
  finances,
  expenses,
  projects,
  groups
}) => {
  const isSw = language === 'sw';
  const currentMonth = monthKey(new Date().toISOString());
  const allDates = [
    ...finances.map(record => record.date),
    ...expenses.map(expense => expense.date),
    ...reports.map(report => report.reportDate)
  ].filter(Boolean);
  const sortedDates = [...allDates].sort();
  const latestDate = sortedDates[sortedDates.length - 1];
  const referenceMonth = allDates.some(date => date.startsWith(currentMonth))
    ? currentMonth
    : monthKey(latestDate) || currentMonth;

  const monthFinances = finances.filter(record => monthKey(record.date) === referenceMonth);
  const monthExpenses = expenses.filter(expense => monthKey(expense.date) === referenceMonth);
  const monthReports = reports.filter(report => monthKey(report.reportDate) === referenceMonth);

  const income = monthFinances.reduce((sum, record) => sum + record.amount, 0);
  const spent = monthExpenses.reduce((sum, expense) => sum + expense.amount, 0);
  const net = income - spent;
  const attendance = monthReports.reduce(
    (sum, report) =>
      sum +
      report.attendeesMen +
      report.attendeesWomen +
      report.attendeesYouth +
      report.attendeesChildren,
    0
  );
  const visitors = monthReports.reduce((sum, report) => sum + report.newVisitors, 0);
  const reportingGroupIds = new Set(monthReports.map(report => report.jumuiyaId));
  const reportingRate = groups.length
    ? Math.round((reportingGroupIds.size / groups.length) * 100)
    : 0;
  const pendingExpenses = expenses.filter(expense => !expense.isApproved).length;

  const trendMonths = Array.from({ length: 6 }, (_, index) =>
    shiftMonth(referenceMonth, index - 5)
  );
  const trend = trendMonths.map(month => ({
    month,
    income: finances
      .filter(record => monthKey(record.date) === month)
      .reduce((sum, record) => sum + record.amount, 0),
    spent: expenses
      .filter(expense => monthKey(expense.date) === month)
      .reduce((sum, expense) => sum + expense.amount, 0)
  }));
  const maxTrend = Math.max(
    ...trend.flatMap(item => [item.income, item.spent]),
    1
  );

  const groupStatus = groups.map(group => {
    const groupReports = reports
      .filter(report => report.jumuiyaId === group.id)
      .sort((a, b) => b.reportDate.localeCompare(a.reportDate));
    const latest = groupReports[0];
    return {
      ...group,
      latestDate: latest?.reportDate || '',
      submitted: monthKey(latest?.reportDate) === referenceMonth
    };
  });

  const activeProjects = projects.filter(project => project.status === 'active').slice(0, 3);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.35rem' }}>
      <div
        className="church-card"
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          gap: '1rem',
          flexWrap: 'wrap',
          background: 'var(--bg-surface)'
        }}
      >
        <div>
          <span className="badge badge-purple" style={{ marginBottom: '0.7rem' }}>
            <BarChart3 size={13} />
            {isSw ? 'Takwimu za Uongozi' : 'Leadership Analytics'}
          </span>
          <h2 style={{ fontSize: '1.55rem', fontWeight: 800, color: 'var(--text-headline)', marginBottom: '0.35rem' }}>
            {isSw ? 'Afya ya Kanisa' : 'Church Health'}
          </h2>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.92rem', maxWidth: '720px' }}>
            {isSw
              ? `Muhtasari wa jumla kwa ${monthName(referenceMonth, isSw)}. Hatuhifadhi tabia ya mtu mmoja; takwimu hizi ni za huduma na uongozi.`
              : `Aggregate overview for ${monthName(referenceMonth, isSw)}. We do not store individual behaviour; these metrics are for ministry and leadership.`}
          </p>
        </div>
        <span className="badge badge-emerald">
          <ShieldCheck size={13} />
          {isSw ? 'Bila data binafsi' : 'Privacy-first'}
        </span>
      </div>

      <div className="portal-metrics-grid">
        <div className="portal-metric-card">
          <div className="metric-icon" style={{ background: 'var(--emerald-container)', color: 'var(--emerald-text)' }}>
            <Wallet size={24} />
          </div>
          <div>
            <div className="metric-value" style={{ fontSize: '1.35rem' }}>{formatMoney(income)}</div>
            <div className="metric-label">{isSw ? 'Mapato ya Mwezi' : 'Monthly Income'}</div>
          </div>
        </div>

        <div className="portal-metric-card">
          <div className="metric-icon" style={{ background: 'var(--error-container)', color: 'var(--on-error-container)' }}>
            <TrendingDown size={24} />
          </div>
          <div>
            <div className="metric-value" style={{ fontSize: '1.35rem' }}>{formatMoney(spent)}</div>
            <div className="metric-label">{isSw ? 'Matumizi ya Mwezi' : 'Monthly Expenses'}</div>
          </div>
        </div>

        <div className="portal-metric-card">
          <div
            className="metric-icon"
            style={{
              background: net >= 0 ? 'var(--emerald-container)' : 'var(--error-container)',
              color: net >= 0 ? 'var(--emerald-text)' : 'var(--on-error-container)'
            }}
          >
            <Target size={24} />
          </div>
          <div>
            <div
              className="metric-value"
              style={{ fontSize: '1.35rem', color: net >= 0 ? 'var(--emerald-text)' : 'var(--error)' }}
            >
              {formatMoney(net)}
            </div>
            <div className="metric-label">{isSw ? 'Salio la Mwezi' : 'Net Balance'}</div>
          </div>
        </div>

        <div className="portal-metric-card">
          <div className="metric-icon" style={{ background: 'var(--primary-fixed)', color: 'var(--on-primary-fixed)' }}>
            <Users size={24} />
          </div>
          <div>
            <div className="metric-value" style={{ fontSize: '1.35rem' }}>{attendance.toLocaleString()}</div>
            <div className="metric-label">
              {isSw ? `Mahudhurio ya Jumuiya (wageni ${visitors})` : `Jumuiya Attendance (${visitors} visitors)`}
            </div>
          </div>
        </div>

        <div className="portal-metric-card">
          <div className="metric-icon" style={{ background: 'var(--amber-container)', color: 'var(--amber-text)' }}>
            <FileCheck2 size={24} />
          </div>
          <div>
            <div className="metric-value" style={{ fontSize: '1.35rem' }}>{reportingRate}%</div>
            <div className="metric-label">
              {isSw
                ? `Ripoti zilizowasilishwa (${reportingGroupIds.size}/${groups.length})`
                : `Reports submitted (${reportingGroupIds.size}/${groups.length})`}
            </div>
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))', gap: '1.25rem' }}>
        <div className="church-card" style={{ background: 'var(--bg-surface)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: '0.75rem', marginBottom: '1.25rem', flexWrap: 'wrap' }}>
            <div>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--text-headline)' }}>
                {isSw ? 'Mwelekeo wa Miezi 6' : '6-Month Trend'}
              </h3>
              <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                {isSw ? 'Mapato dhidi ya matumizi' : 'Income vs expenses'}
              </p>
            </div>
            <div style={{ display: 'flex', gap: '0.9rem', fontSize: '0.75rem', color: 'var(--text-muted)', alignItems: 'center' }}>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
                <span style={{ width: '9px', height: '9px', borderRadius: '50%', background: 'var(--emerald)' }} />
                {isSw ? 'Mapato' : 'Income'}
              </span>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: '0.35rem' }}>
                <span style={{ width: '9px', height: '9px', borderRadius: '50%', background: 'var(--error)' }} />
                {isSw ? 'Matumizi' : 'Expenses'}
              </span>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'flex-end', gap: '0.55rem', height: '190px' }}>
            {trend.map(item => (
              <div key={item.month} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '0.45rem', minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'flex-end', gap: '3px', height: '145px', width: '100%', justifyContent: 'center' }}>
                  <div
                    title={`${isSw ? 'Mapato' : 'Income'}: ${formatMoney(item.income)}`}
                    style={{
                      width: '38%',
                      height: `${Math.max(3, (item.income / maxTrend) * 100)}%`,
                      background: 'var(--emerald)',
                      borderRadius: '4px 4px 0 0'
                    }}
                  />
                  <div
                    title={`${isSw ? 'Matumizi' : 'Expenses'}: ${formatMoney(item.spent)}`}
                    style={{
                      width: '38%',
                      height: `${Math.max(3, (item.spent / maxTrend) * 100)}%`,
                      background: 'var(--error)',
                      borderRadius: '4px 4px 0 0'
                    }}
                  />
                </div>
                <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>
                  {shortMonth(item.month, isSw)}
                </span>
              </div>
            ))}
          </div>
        </div>

        <div className="church-card" style={{ background: 'var(--bg-surface)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: '0.75rem', marginBottom: '1rem', flexWrap: 'wrap' }}>
            <div>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--text-headline)' }}>
                {isSw ? 'Hali ya Viongozi wa Jumuiya' : 'Jumuiya Leader Status'}
              </h3>
              <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                {isSw ? 'Operesheni, si ufuatiliaji wa mtu' : 'Operational status, not personal tracking'}
              </p>
            </div>
            {pendingExpenses > 0 && (
              <span className="badge badge-gold">
                <Clock3 size={13} />
                {isSw ? `${pendingExpenses} idhini zinasubiri` : `${pendingExpenses} pending approvals`}
              </span>
            )}
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.82rem' }}>
              <thead>
                <tr style={{ textAlign: 'left', color: 'var(--text-muted)', borderBottom: '1px solid var(--border-subtle)' }}>
                  <th style={{ padding: '0.55rem 0.4rem', fontWeight: 700 }}>{isSw ? 'Jumuiya' : 'Group'}</th>
                  <th style={{ padding: '0.55rem 0.4rem', fontWeight: 700 }}>{isSw ? 'Kiongozi' : 'Leader'}</th>
                  <th style={{ padding: '0.55rem 0.4rem', fontWeight: 700 }}>{isSw ? 'Ripoti ya Mwisho' : 'Last Report'}</th>
                  <th style={{ padding: '0.55rem 0.4rem', fontWeight: 700 }}>{isSw ? 'Hali' : 'Status'}</th>
                </tr>
              </thead>
              <tbody>
                {groupStatus.map(group => (
                  <tr key={group.id} style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                    <td style={{ padding: '0.65rem 0.4rem', fontWeight: 600, color: 'var(--text-body)' }}>{group.name}</td>
                    <td style={{ padding: '0.65rem 0.4rem', color: 'var(--text-muted)' }}>{group.leaderName}</td>
                    <td style={{ padding: '0.65rem 0.4rem', color: 'var(--text-muted)' }}>
                      {group.latestDate || (isSw ? 'Hakuna' : 'None')}
                    </td>
                    <td style={{ padding: '0.65rem 0.4rem' }}>
                      <span className={group.submitted ? 'badge badge-emerald' : 'badge badge-gold'} style={{ whiteSpace: 'nowrap' }}>
                        {group.submitted ? <CheckCircle2 size={12} /> : <Clock3 size={12} />}
                        {group.submitted
                          ? (isSw ? 'Amewasilisha' : 'Submitted')
                          : (isSw ? 'Inasubiri' : 'Pending')}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div className="church-card" style={{ background: 'var(--bg-surface)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
          <Target size={17} style={{ color: 'var(--primary)' }} />
          <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: 'var(--text-headline)' }}>
            {isSw ? 'Maendeleo ya Miradi' : 'Project Progress'}
          </h3>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1rem' }}>
          {activeProjects.map(project => {
            const percent = project.targetAmount > 0
              ? Math.min(100, Math.round((project.currentAmount / project.targetAmount) * 100))
              : 0;

            return (
              <div key={project.id} style={{ padding: '0.9rem', background: 'var(--bg-app)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-sm)' }}>
                <div style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--text-headline)', marginBottom: '0.25rem' }}>
                  {isSw ? project.title : project.titleEn}
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '0.6rem' }}>
                  {formatMoney(project.currentAmount)} / {formatMoney(project.targetAmount)}
                </div>
                <div style={{ height: '8px', borderRadius: '999px', background: 'var(--surface-container)', overflow: 'hidden' }}>
                  <div style={{ width: `${percent}%`, height: '100%', borderRadius: '999px', background: 'var(--primary)' }} />
                </div>
                <div style={{ marginTop: '0.35rem', fontSize: '0.72rem', fontWeight: 700, color: 'var(--primary)' }}>
                  {percent}%
                </div>
              </div>
            );
          })}
        </div>

        <p style={{ marginTop: '1rem', fontSize: '0.76rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
          <ShieldCheck size={14} />
          {isSw
            ? 'Takwimu hizi zinatokana na ripoti za jumla na hazionyeshi taarifa binafsi za waumini.'
            : 'These metrics come from aggregate reports and do not expose personal member information.'}
        </p>
      </div>
    </div>
  );
};
