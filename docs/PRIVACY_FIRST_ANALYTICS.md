# Privacy-First Analytics, Data Inventory & Content Plan

**Status:** Phase 0 started 2026-11-03  
**Scope:** `sayuni-portal`, `sayuni` (Flutter), Firestore, Cloud Functions  
**Rule:** collect the minimum personal data needed for church operations; analytics must use aggregates, not individual profiles.

> This is an engineering and operations plan, not legal advice. Confirm registration,
> exemptions, retention and cross-border processing with the Tanzania Personal Data
> Protection Commission (PDPC) or PDPA counsel before launch.

---

## 1. Non-negotiable principles

1. **Aggregate first.** Dashboards show totals, trends and operational status. They do not score individual members.
2. **No third-party tracking.** No Google Analytics, Meta Pixel, heatmaps, device fingerprinting or advertising SDKs in the member app.
3. **Purpose before field.** A field is added only when a named church task needs it.
4. **Least privilege.** A leader sees only the data required for their role and branch.
5. **Retention is defined.** Every collection has a retention rule and a deletion path.
6. **Consent is evidence.** Consent records are append-only and versioned.
7. **Children and sensitive data get extra protection.** No child photos or counselling details in public content.
8. **Truthful notices.** The privacy notice must match the services actually used: Firebase/Google, Cloudinary, Gemini (if enabled), radio-browser, and any future processor.

---

## 2. Data inventory and minimum fields

| Data set | Where | Minimum fields | Purpose | Sensitivity | Retention | Who may access |
|---|---|---|---|---|---|---|
| Member profile | `members/{uid}`, `profiles/{uid}`, local cache | uid, full name, phone, gender, age group, jumuiya, baptized, joined date, status | Membership care and directory | Confidential | While active + 12 months after leaving | Self; secretary, pastor, admin |
| Visitor card | `visitors_registry` | name, phone, residence, first visit, invited by, assigned jumuiya, follow-up status, consent | Welcome and follow-up | Sensitive | 90 days after last contact unless the person joins | Deacon, secretary, pastor, admin |
| Prayer request | `prayer_requests` | author uid or anonymous flag, request text, category, date | Pastoral prayer | Sensitive (health/grief possible) | 30 days after resolution, or 90 days | Author; pastoral desk |
| Jumuiya report | `jumuiya_reports` | group, date, attendance counts, visitors, offering total, topic, submitted by | Home-cell oversight | Confidential | 24 months | Jumuiya leader, secretary, pastor, admin |
| Income record | `income_records` (planned) / portal ledger | date, type, category, amount, method, reference, branch | Financial stewardship | Confidential | 7 years (finance/audit) | Treasurer, secretary, pastor, admin |
| Expense record | `expense_records` (planned) / portal ledger | date, category, amount, payee, approval, receipt URL | Expense control | Confidential | 7 years | Treasurer, pastor, admin |
| Counselling case | `elder_cases` / local | case title, family/member reference, category, elder, status, notes | Pastoral care | Highly sensitive | 12 months after resolution | Elders/pastor only; no analytics |
| Consent record | `consent_records` | uid, purposes, version, timestamp, channel | Proof of lawful basis | Legal evidence | 7 years | Self; secretary, admin; server erasure |
| Audit log | `audit_logs` | actor, role, action, path, before/after, timestamp | Accountability | Confidential | 7 years | Admin, secretary |
| Public content | `announcements`, `sermons`, `choir_songs`, posters | title, body, media URL, date | Public ministry | Public / low | While published + archive | Public read; authorised writers |
| Analytics aggregate | `analytics_monthly` (planned) | month, branch, income total, expense total, attendance total, visitor total, report rate | Leadership trends | Non-personal if threshold met | 36 months | Leaders by role |

### Fields we should not collect

- NIDA numbers, full date of birth, home GPS coordinates, biometrics, device IDs.
- Health diagnoses or counselling notes in general member records.
- Donor names or phone numbers in analytics rows.
- Photos of minors for social media without documented parental consent.
- Free-text prayer/welfare details in public announcements.
- “Last seen”, location history or individual engagement scores.

If a field is already present but not needed for a named task, remove it or stop displaying it.

---

## 3. Analytics specification

### Metrics shown to leaders

| Metric | Definition | Source | Personal data? |
|---|---|---|---|
| Monthly income | Sum of income records in month | Finance ledger | No (totals only) |
| Monthly expenses | Sum of expense records in month | Expense ledger | No (totals only) |
| Net balance | Income minus expenses | Derived | No |
| Jumuiya attendance | Sum of attendance counts in reports | `jumuiya_reports` | No (group totals) |
| New visitors | Sum of `newVisitors` in reports | `jumuiya_reports` | No (aggregate) |
| Reporting rate | Groups with a report / active groups | `jumuiya_groups` + reports | No |
| Leader status | Last report date and pending approvals | Reports + expenses | Operational, not behavioural |
| Project progress | Current amount / target amount | Projects | No |

### Rules

- Do not show donor-level giving, individual attendance or member engagement rankings.
- Apply a **minimum group size of 5** before showing a sensitive breakdown; otherwise show “not enough data”.
- Store aggregate counters only. Do not create a raw event stream containing user IDs.
- The current `Church Health` tab computes totals from the leader’s already-authorised records. The next step is a server-side monthly aggregate written by a Cloud Function after Blaze is enabled.
- Aggregate rows must not contain names, phone numbers, emails, UIDs, IP addresses or device identifiers.

---

## 4. PDPA controls

### Lawful basis and notice

- Membership, giving and safeguarding records: document the lawful basis used by the church.
- Visitor follow-up, prayer requests and media: explicit consent where required.
- Provide a plain Kiswahili and English privacy notice at onboarding and in the profile.
- Maintain a register of processing activities: purpose, data categories, recipients, retention, security.

### Data-subject rights

- Access/export: existing `exportMyData` path; extend it to portal records.
- Correction: secretary/admin workflow with audit log.
- Erasure: existing `deleteMyData` path; keep financial records required by law and anonymise where possible.
- Withdraw consent: existing consent centre; stop optional processing and record the change.

### Security and accountability

- Firebase custom claims are the authority; Firestore rules enforce role and branch.
- `consent_records` and `audit_logs` are append-only from clients.
- Encrypt in transit and at rest; remove cleartext traffic exceptions in release.
- Restrict exports and bulk reads to named roles.
- Log privileged actions: role grants, finance changes, deletions, exports.
- Review access quarterly and remove inactive leaders promptly.
- Have a breach response contact and a 72-hour internal escalation target; confirm statutory timelines with counsel.

### Processors to disclose

- Google Firebase / Cloud Firestore / Cloud Functions / Cloud Storage.
- Cloudinary (media hosting).
- Gemini API if AI features remain enabled.
- Radio Browser or other third-party content sources.
- Any social platform used for publishing.

---

## 5. Content and social-media workflow

1. Church brand kit: logo, colours, fonts, approved Kiswahili/English phrases.
2. Templates: verse card, sermon quote, event poster, announcement, choir promo, Sunday school.
3. Content record: title, caption, scripture, date, speaker, asset URL, approval status, consent status.
4. Approval: pastor/secretary/admin approves before export.
5. Export PNG/PDF; publish manually first. No auto-posting until a separate review.
6. Media consent: record who consented, for which channel, and when. Do not tag or mention minors.
7. Social insights: enter aggregate reach/likes manually or use official platform APIs; never import follower personal data.
8. Archive assets and remove expired content from public folders.

---

## 6. Delivery sequence

| Phase | Deliverable | Acceptance test |
|---|---|---|
| 0 | This inventory, retention rules, privacy-notice copy, role matrix | Every collection has a purpose, retention and owner |
| 1 | Remove unnecessary fields; mask phone numbers; consent gaps closed | No sensitive field visible outside its role |
| 2 | `Church Health` tab (done) + monthly aggregate counters | Leaders see totals without donor/member detail |
| 3 | Leader readiness, approvals inbox, Sunday checklist | A leader can see what is pending without tracking people |
| 4 | Content studio with brand templates and consent flags | Poster/verse card can be approved and exported |
| 5 | DSAR/erasure operations, retention jobs, audit review | Export and erasure work end to end after Blaze |
| 6 | Monthly review: metrics, access, incidents | Report signed by church leadership |

---

## 7. Phase 0 checklist

- [x] Inventory the current portal types and Firestore collections.
- [x] Define the first aggregate metrics with no personal data.
- [x] Add the privacy-first `Church Health` tab for authorised leaders.
- [ ] Confirm retention periods with church leadership and counsel.
- [ ] Confirm PDPC registration/exemption position.
- [ ] Update the privacy notice with processors and DPO contact.
- [ ] Remove or hide every field not listed in the inventory.
- [ ] Add the `analytics_monthly` aggregate function after Blaze is enabled.
