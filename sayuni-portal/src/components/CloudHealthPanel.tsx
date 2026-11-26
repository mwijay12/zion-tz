import React, { useState } from 'react';
import {
  Activity,
  AlertTriangle,
  CheckCircle2,
  CloudOff,
  Loader2,
  MinusCircle,
  RefreshCw,
  ShieldCheck,
  XCircle,
} from 'lucide-react';
import type { Language } from '../types';
import {
  runCloudHealthCheck,
  type HealthReport,
  type HealthStep,
  type CheckStatus,
} from '../services/cloudHealthService';

interface CloudHealthPanelProps {
  language: Language;
  /** Set when the session is a local demo — it can never write to the cloud. */
  isDemo?: boolean;
  currentUserName?: string;
}

const STATUS_ICON: Record<CheckStatus, React.ReactNode> = {
  ok: <CheckCircle2 size={15} style={{ color: 'var(--emerald)' }} />,
  warn: <AlertTriangle size={15} style={{ color: 'var(--amber)' }} />,
  fail: <XCircle size={15} style={{ color: 'var(--error)' }} />,
  skip: <MinusCircle size={15} style={{ color: 'var(--text-subtle)' }} />,
};

/**
 * "Is Firebase actually working?" — answered by evidence, not by a green dot.
 *
 * The sidebar used to show a permanent "Firebase Sync Active" badge whether or
 * not the signed-in account could write anything. This panel runs a real,
 * reversible write through Firestore and reports each precondition
 * separately, so a leader learns whether the problem is sign-in, verification,
 * a missing role claim, undeployed functions, or the network.
 */
export const CloudHealthPanel: React.FC<CloudHealthPanelProps> = ({
  language,
  isDemo,
  currentUserName,
}) => {
  const isSw = language === 'sw';
  const [report, setReport] = useState<HealthReport | null>(null);
  const [running, setRunning] = useState(false);

  const run = async () => {
    setRunning(true);
    setReport(null);
    try {
      const result = await runCloudHealthCheck();
      setReport(result);
    } finally {
      setRunning(false);
    }
  };

  const stepLabel = (step: HealthStep) => (isSw ? step.labelSw : step.labelEn);
  const stepDetail = (step: HealthStep) => (isSw ? step.detailSw : step.detailEn);

  const headline = () => {
    if (!report) return null;
    if (report.cloudWrites) {
      return {
        tone: 'ok' as const,
        icon: <ShieldCheck size={16} />,
        text: isSw
          ? 'Firebase inafanya kazi kwa akaunti hii — maandishi yote ya kanisa yanafika wingu.'
          : 'Firebase works for this account — church writes reach the cloud.',
      };
    }
    return {
      tone: 'fail' as const,
      icon: <CloudOff size={16} />,
      text: isSw
        ? 'Firebase HAIKUBALI maandishi ya akaunti hii. Kila tangazo au mahubiri unayoweka yatabaki kwenye kifaa hiki pekee.'
        : 'Firebase is NOT accepting writes from this account. Anything you publish stays on this device only.',
    };
  };

  const summary = headline();

  return (
    <div className="cloud-health">
      <button
        type="button"
        className="cloud-health-trigger"
        onClick={() => void run()}
        disabled={running}
        aria-busy={running}
        title={isSw ? 'Pima kama Firebase inafanya kazi kwa akaunti hii' : 'Test whether Firebase works for this account'}
      >
        {running ? <Loader2 size={13} className="spin" /> : <Activity size={13} />}
        <span>{running ? (isSw ? 'Inakagua…' : 'Checking…') : (isSw ? 'Kagua Wingu' : 'Check cloud')}</span>
      </button>

      {report && (
        <div className={`cloud-health-result tone-${summary?.tone ?? 'fail'}`}>
          <div className="cloud-health-headline">
            {summary?.icon}
            <span>{summary?.text}</span>
          </div>

          {isDemo && (
            <p className="cloud-health-note">
              {isSw
                ? `Umeingia kama ${currentUserName || 'demo'}. Demo haifanyi maandishi yoyote ya wingu kwa makusudi — hii si hitilafu.`
                : `Signed in as ${currentUserName || 'demo'}. A demo session never writes to the cloud by design — this is not a fault.`}
            </p>
          )}

          <ul className="cloud-health-steps">
            {report.steps.map((step) => (
              <li key={step.id} className="cloud-health-step">
                {STATUS_ICON[step.status]}
                <div>
                  <div className="cloud-health-step-label">{stepLabel(step)}</div>
                  <div className="cloud-health-step-detail">{stepDetail(step)}</div>
                  {step.raw && (
                    <code className="cloud-health-raw">{step.raw}</code>
                  )}
                </div>
              </li>
            ))}
          </ul>

          <div className="cloud-health-actions">
            <button type="button" className="btn-secondary btn-sm" onClick={() => void run()} disabled={running}>
              <RefreshCw size={12} />
              <span>{isSw ? 'Pima Tena' : 'Re-run'}</span>
            </button>
            <span className="cloud-health-stamp">
              {new Date(report.finishedAt).toLocaleTimeString(isSw ? 'sw-TZ' : 'en-GB', { hour: '2-digit', minute: '2-digit' })}
            </span>
          </div>
        </div>
      )}
    </div>
  );
};

export default CloudHealthPanel;
