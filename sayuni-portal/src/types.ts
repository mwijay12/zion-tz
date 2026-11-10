export type UserRole = 
  | 'super_admin'
  | 'admin'
  | 'pastor' 
  | 'secretary' 
  | 'deacon'
  | 'treasurer'
  | 'usher'
  | 'jumuiya_leader'
  | 'choir_leader' 
  | 'children_teacher'
  | 'member'
  | 'guest';

export interface VisitorRecord {
  id: string;
  fullName: string;
  phone: string;
  residence: string;
  firstVisitDate: string;
  invitedBy?: string;
  prayerRequest?: string;
  assignedJumuiya: string;
  followUpStatus: 'Mpya' | 'Ametembelewa' | 'Amejiunga na Jumuiya' | 'Anahitaji Maombi';
  welfareNeeds?: string;
  registeredByDeacon?: string;
  createdAt?: string;
}

export interface ChoirSongRecord {
  id: string;
  title: string;
  choirName: string;
  audioUrl: string;
  lyrics?: string;
  keySignature: string;
  tempo?: string;
  duration: string;
  recordedDate?: string;
  uploadedBy?: string;
}

export interface SundaySchoolLesson {
  id: string;
  title: string;
  ageGroup: string;
  lessonScripture: string;
  memoryVerse: string;
  storySummary: string;
  youtubeVideoUrl?: string;
  lessonDate: string;
  teacherName?: string;
}

export type Language = 'sw' | 'en';

export interface ChurchMember {
  id: string;
  fullName: string;
  phone: string;
  gender: 'Male' | 'Female';
  ageGroup: 'Adult' | 'Youth' | 'Child';
  jumuiyaId: string;
  isBaptized: boolean;
  role: string;
  joinedDate: string;
}

export interface FinancialRecord {
  id: string;
  date: string;
  type: 'tithe' | 'offering' | 'project' | 'benevolence' | 'jumuiya';
  category: string;
  amount: number;
  donorName?: string;
  paymentMethod: 'Cash' | 'M-Pesa' | 'Tigo Pesa' | 'Airtel Money' | 'Bank';
  referenceNumber?: string;
  notes?: string;
  isAnonymous?: boolean;
}

export interface FinancialProject {
  id: string;
  title: string;
  titleEn: string;
  description: string;
  targetAmount: number;
  currentAmount: number;
  startDate: string;
  targetDate: string;
  status: 'active' | 'completed' | 'planning';
}

export interface ChurchExpense {
  id: string;
  date: string;
  title: string;
  category: 'Operations' | 'Evangelism' | 'Maintenance' | 'Benevolence' | 'Utilities';
  amount: number;
  approvedBy: string;
  isApproved: boolean;
  receiptUrl?: string;
}

export interface JumuiyaGroup {
  id: string;
  name: string;
  location: string;
  leaderName: string;
  leaderPhone: string;
  meetingDay: string;
  memberCount: number;
}

export interface JumuiyaReport {
  id: string;
  jumuiyaId: string;
  jumuiyaName: string;
  reportDate: string;
  hostFamily: string;
  attendeesMen: number;
  attendeesWomen: number;
  attendeesYouth: number;
  attendeesChildren: number;
  newVisitors: number;
  scriptureTopic: string;
  offeringAmount: number;
  prayerRequests: string;
  sickOrWelfareNeeds: string;
  submittedBy: string;
  submittedAt: string;
}

export type CertificateType = 
  | 'baptism' 
  | 'dedication' 
  | 'marriage' 
  | 'membership' 
  | 'service';

export interface CertificateData {
  id: string;
  type: CertificateType;
  recipientName: string;
  spouseName?: string;
  parentNames?: string;
  dateOfEvent: string;
  officiatingMinister: string;
  churchSecretary: string;
  scriptureVerse: string;
  serialNumber: string;
  issuedDate: string;
  notes?: string;
}

export interface BibleVerse {
  verse_number: string;
  verse_text: string;
  verse_text_en?: string;
}

export interface BibleChapter {
  chapter_number: string;
  VERSES: BibleVerse[];
}

export interface BibleBook {
  book_number: string;
  book_name: string;
  book_name_en?: string;
  testament?: 'Old' | 'New';
  category?: string;
  CHAPTER: BibleChapter[];
}

export interface TenziStanza {
  verse_number: number;
  text: string;
}

export interface TenziHymn {
  number: number;
  title: string;
  category: string;
  key: string;
  time_signature: string;
  stanzas: TenziStanza[];
  chorus?: string;
  /** 'tenzi' or 'nyimbo' — both ship full offline lyrics. */
  collection?: 'tenzi' | 'nyimbo';
}

export interface NyimboSong {
  siteNumber: number;
  title: string;
  collection: 'nyimbo';
  /** Original Swahili translations of classic public-domain hymns. */
  stanzas: TenziStanza[];
  chorus?: string;
  lyricsNote?: string;
}


export interface DevotionalVerse {
  id: string;
  swahiliText: string;
  englishText: string;
  reference: string;
  category: 'Amani' | 'Upendo' | 'Nguvu' | 'Ujasiri' | 'Imani';
  pastoralReflection: string;
  reflectionEn: string;
  prayer: string;
}

export interface ChoirItem {
  name: string;
  leader: string;
  desc: string;
}

export interface SundayScheduleItem {
  time: string;
  title: string;
  desc: string;
}

export interface BulletinNotice {
  id: string;
  title: string;
  category: 'Taarifa Kuu' | 'Vikundi vya Nyumba' | 'Fedha & Michango' | 'Kwaya' | 'Dharura' | 'Ibada' | 'Ujenzi' | 'Semina' | 'Mkesha';
  content: string;
  date: string;
  isUrgent?: boolean;
  targetAudience?: 'all' | 'leaders' | 'elders' | 'choir' | 'jumuiya' | 'member';
  /** Firebase UID of one specific member (personalized message). */
  targetUid?: string;
  /** Jumuiya name for group targeting. */
  targetJumuiya?: string;
  type?: 'normal' | 'urgent' | 'bereavement';
  branch?: string;
  authorRole?: string;
  authorEmail?: string;
  /** Leader asks the Super Admin for a poster design of this announcement. */
  posterRequest?: boolean;
  posterStatus?: 'none' | 'requested' | 'ready';
  posterTheme?: string;
  posterAuthor?: string;
  /** Structured event details (used by the Poster Desk). */
  eventDate?: string;
  eventTime?: string;
  venue?: string;
  themeVerse?: string;
}

export interface SermonItem {
  id: string;
  title: string;
  preacher: string;
  date: string;
  scripture: string;
  summary: string;
  mediaType: 'video' | 'audio' | 'text';
  mediaUrl?: string;
  category: 'Imani' | 'Uponyaji' | 'Familia' | 'Uongozi' | 'Kusifu' | 'Upendo' | 'Maendeleo' | 'Bidii' | 'Sunday School' | 'Maombi' | 'Ukombozi' | 'Kwaya';
  likesCount: number;
  fullArticle?: string;
  readTime?: string;
  keyVerse?: string;
  scriptureList?: string[];
  takeaways?: string[];
  pastoralPrayer?: string;
  imageUrl?: string;
}

export interface PastoralPoster {
  id: string;
  title: string;
  eventDate: string;
  location: string;
  imageUrl: string;
  description: string;
  speaker: string;
  status: 'active' | 'upcoming' | 'archived';
}

export interface ElderCounselingCase {
  id: string;
  title: string;
  memberOrFamily: string;
  elderInCharge: string;
  category: 'Ndoa & Familia' | 'Ushauri Nasaha' | 'Maombi ya Wagonjwa' | 'Nidhamu';
  date: string;
  status: 'active' | 'resolved' | 'pending_pastor';
  notes: string;
}

export interface ChoirSong {
  id: string;
  title: string;
  choirName: string;
  key: string;
  tempo: string;
  audioDemoUrl?: string;
  lyrics: string;
  rehearsalDate: string;
}

export interface DepartmentInfo {
  id: string;
  name: string;
  nameSw: string;
  leader: string;
  phone: string;
  memberCount: number;
  meetingSchedule: string;
  currentProject: string;
  upcomingEvent: string;
  description: string;
}

export interface ChurchFastingCampaign {
  id: string;
  title: string;
  themeVerse: string;
  startDate: string;
  endDate: string;
  fastType: string;
  guidelines: string;
  isActive: boolean;
  participantsCount: number;
}

export interface MemberSkillListing {
  id: string;
  fullName: string;
  profession: string;
  category: string;
  description: string;
  phone: string;
  location: string;
  jumuiya: string;
  experienceYears: string;
  isApproved: boolean;
  isVerifiedMember: boolean;
  createdAt: string;
}
