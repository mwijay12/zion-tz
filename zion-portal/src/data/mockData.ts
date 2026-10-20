import type { 
  ChurchMember, 
  FinancialRecord, 
  FinancialProject, 
  ChurchExpense, 
  JumuiyaGroup, 
  JumuiyaReport, 
  DevotionalVerse,
  CertificateData,
  ChoirItem,
  SundayScheduleItem,
  BulletinNotice,
  SermonItem,
  PastoralPoster,
  ElderCounselingCase,
  ChoirSong,
  DepartmentInfo
} from '../types';

export const CHURCH_PROFILE = {
  name: 'ZION JERUSALEM CHURCH',
  nameSw: 'KANISA LA SAYUNI YERUSALEMU',
  motto: 'Mwanga wa Mataifa na Nyumba ya Maombi',
  mottoEn: 'Light of the Nations and House of Prayer',
  headPastor: 'Mchungaji Askofu Messi Mgala',
  bishopHusband: 'James Robert',
  eldersBoard: 'Baraza la Wazee wa Kanisa',
  churchSecretary: 'Sekretarieti ya Kanisa',
  churchTreasurer: 'Kamati ya Hazina & Fedha',
  location: 'Kwa Matope, Mbagala, Dar es Salaam, Tanzania',
  poBox: 'Kwa Matope, Mbagala, Dar es Salaam',
  phone: '+255 754 000 001 / +255 713 000 002',
  email: 'huduma@zionjerusalem.org',
  paymentChannels: {
    mpesaTill: '5624108',
    mpesaName: 'ZION JERUSALEM - KWA MATOPE',
    airtelMoney: '+255 784 555 123',
    bankName: 'CRDB Bank - Mbagala Branch',
    accountNumber: '0150248967300',
    accountName: 'ZION JERUSALEM CHURCH'
  }
};

export const CHURCH_CHOIRS: ChoirItem[] = [
  {
    name: 'Kwaya ya Galilaya',
    leader: 'Uongozi wa Kwaya ya Galilaya',
    desc: 'Kwaya kuu ya uinjilisti na sifa za Jumapili, yenye uimbaji thabiti wa kiroho.'
  },
  {
    name: 'Kwaya ya Upendo',
    leader: 'Uongozi wa Kwaya ya Upendo',
    desc: 'Kwaya inayobeba huduma ya upendo, mshikamano wa kindugu na nyimbo za faraja.'
  },
  {
    name: 'Kwaya ya Wamama',
    leader: 'Idara ya Wanawake',
    desc: 'Huduma ya akina mama ya maombi, uimbaji, na kulea familia katika misingi ya kiungu.'
  },
  {
    name: 'Kwaya ya Vijana',
    leader: 'Idara ya Vijana',
    desc: 'Kwaya yenye nguvu, ubunifu, na uhamasishaji wa vijana kumtumikia Bwana.'
  },
  {
    name: 'Praise & Worship Team',
    leader: 'Timu ya Kusifu na Kuabudu',
    desc: 'Inaongoza kusanyiko katika maingilio matakatifu ya sifa na kuabudu kabla ya neno.'
  }
];

export const SUNDAY_SCHEDULE: SundayScheduleItem[] = [
  {
    time: '08:30 - 09:00',
    title: 'Maombi ya Asubuhi (Morning Intercession)',
    desc: 'Maombi ya ufunguzi, toba, na kuombea ibada na taifa.'
  },
  {
    time: '09:00 - 10:00',
    title: 'Sunday School (Huduma ya Watoto)',
    desc: 'Kujifunza neno la Mungu, nyimbo za watoto na kukariri mistari.'
  },
  {
    time: '10:00 - 11:15',
    title: 'Praise & Worship & Huduma ya Kwaya',
    desc: 'Sifa na kuabudu ikihudumiwa na Galilaya, Upendo, Wamama na Vijana.'
  },
  {
    time: '11:15 - 11:30',
    title: 'Kipindi cha Katibu (Matangazo ya Haraka & Bulletin)',
    desc: 'Muhtasari mfupi wa dakika 2. Taarifa zote kamili ziko kwenye App na Ubao wa Matangazo.'
  },
  {
    time: '11:30 - 13:00',
    title: 'Neno la Mungu & Maombezi',
    desc: 'Ujumbe kuu kutoka kwa Mchungaji Askofu Messi Mgala na maombi ya hitaji.'
  }
];

export const INITIAL_BULLETIN_NOTICES: BulletinNotice[] = [
  {
    id: 'bul-1',
    title: 'Ripoti ya Sadaka za Vikundi vya Nyumba kwa Nyumba',
    category: 'Vikundi vya Nyumba',
    content: 'Vikundi vyote 5 vya maombi vya Kwa Matope, Mbagala Kuu, Rangi Tatu, Chamazi na Charambe vilikutana Ijumaa. Jumla ya Sh 385,000 imekusanywa na kuwasilishwa kwa mhazini.',
    date: 'Ijumaa, 04 Septemba 2026',
    isUrgent: false
  },
  {
    id: 'bul-2',
    title: 'Mkutano Maalum wa Wazee wa Kanisa na Askofu Messi Mgala',
    category: 'Taarifa Kuu',
    content: 'Baraza la Wazee wa Kanisa litakutana na Mchungaji Askofu Messi Mgala na Ndg. James Robert mara baada ya ibada ya pili kwa ajili ya mapitio ya robo mwaka.',
    date: 'Jumapili, 06 Septemba 2026',
    isUrgent: true
  },
  {
    id: 'bul-3',
    title: 'Mazoezi ya Pamoja ya Kwaya ya Galilaya na Upendo',
    category: 'Kwaya',
    content: 'Kwaya ya Galilaya na Kwaya ya Upendo zitakuwa na mkesha mfupi wa maombi na mazoezi siku ya Jumamosi kujiandaa na Jumapili ya Mavuno.',
    date: 'Jumamosi, 05 Septemba 2026',
    isUrgent: false
  },
  {
    id: 'bul-4',
    title: 'Utoaji wa Vyeti vya Ubatizo na Ndoa',
    category: 'Taarifa Kuu',
    content: 'Waumini waliotimiza maombi ya vyeti vya ubatizo na ndoa wanaweza kuchukua vyeti vyao vilivyoidhinishwa ofisi ya katibu au kuvipakua kwenye mfumo.',
    date: 'Jumapili, 06 Septemba 2026',
    isUrgent: false
  }
];

export const INITIAL_JUMUIYA_GROUPS: JumuiyaGroup[] = [
  {
    id: 'jum-1',
    name: 'Jumuiya ya Kwa Matope',
    location: 'Kwa Matope - Karibu na Kanisa',
    leaderName: 'Mzee Emmanuel Mtweve',
    leaderPhone: '+255 754 332 110',
    meetingDay: 'Ijumaa Saa 11:30 Jioni',
    memberCount: 34
  },
  {
    id: 'jum-2',
    name: 'Jumuiya ya Mbagala Kuu',
    location: 'Mbagala Kuu / Kizuiani',
    leaderName: 'Mwl. Daudi Msechu',
    leaderPhone: '+255 712 445 667',
    meetingDay: 'Ijumaa Saa 11:30 Jioni',
    memberCount: 28
  },
  {
    id: 'jum-3',
    name: 'Jumuiya ya Rangi Tatu',
    location: 'Mbagala Rangi Tatu',
    leaderName: 'Mama Sarah Mkude',
    leaderPhone: '+255 768 778 990',
    meetingDay: 'Ijumaa Saa 11:30 Jioni',
    memberCount: 31
  },
  {
    id: 'jum-4',
    name: 'Jumuiya ya Chamazi',
    location: 'Chamazi / Dovya',
    leaderName: 'Ndg. Baraka Mlay',
    leaderPhone: '+255 784 112 334',
    meetingDay: 'Ijumaa Saa 12:00 Jioni',
    memberCount: 25
  },
  {
    id: 'jum-5',
    name: 'Jumuiya ya Charambe',
    location: 'Charambe / Nzasa',
    leaderName: 'Bi. Rehema Makonda',
    leaderPhone: '+255 713 667 889',
    meetingDay: 'Ijumaa Saa 11:30 Jioni',
    memberCount: 22
  }
];

export const INITIAL_PROJECTS: FinancialProject[] = [
  {
    id: 'proj-1',
    title: 'Ukarabati wa Paa la Kanisa & Dari',
    titleEn: 'Church Roof & Ceiling Renovation',
    description: 'Kuweka bati za kisasa za kuzuia joto na kupunguza kelele za mvua wakati wa ibada.',
    targetAmount: 12000000,
    currentAmount: 8900000,
    startDate: '2026-01-15',
    targetDate: '2026-10-30',
    status: 'active'
  },
  {
    id: 'proj-2',
    title: 'Vyombo vya Kisasa vya Muziki na Sauti',
    titleEn: 'Modern Audio & Live Stream Sound System',
    description: 'Kununua digital mixer ya kisasa, maikrofoni zisizo na waya, na spika za ndani.',
    targetAmount: 6500000,
    currentAmount: 5200000,
    startDate: '2026-03-01',
    targetDate: '2026-09-30',
    status: 'active'
  },
  {
    id: 'proj-3',
    title: 'Basi la Uinjilisti & Huduma ya Watoto',
    titleEn: 'Mission & Sunday School Shuttle Bus',
    description: 'Gari litakalowasaidia wazee na watoto kufika ibadani na kutumika katika mikutano ya injili.',
    targetAmount: 25000000,
    currentAmount: 7800000,
    startDate: '2026-02-10',
    targetDate: '2026-12-31',
    status: 'active'
  }
];

export const INITIAL_FINANCES: FinancialRecord[] = [
  {
    id: 'fin-001',
    date: '2026-09-03',
    type: 'tithe',
    category: 'Fungu la Kumi',
    amount: 350000,
    donorName: 'J. Mwakyusa',
    paymentMethod: 'M-Pesa',
    referenceNumber: 'QA892JK9L1',
    notes: 'Fungu la kumi la mwezi Agosti'
  },
  {
    id: 'fin-002',
    date: '2026-09-03',
    type: 'offering',
    category: 'Sadaka ya Ibada Kuu',
    amount: 1250000,
    paymentMethod: 'Cash',
    notes: 'Ibada ya Pili ya Jumapili'
  },
  {
    id: 'fin-003',
    date: '2026-09-02',
    type: 'project',
    category: 'Mradi wa Paa',
    amount: 500000,
    donorName: 'Familia ya Mzee Peter',
    paymentMethod: 'Bank',
    referenceNumber: 'TRX-99421',
    notes: 'Ahadi ya ujenzi'
  },
  {
    id: 'fin-004',
    date: '2026-09-01',
    type: 'jumuiya',
    category: 'Sadaka ya Jumuiya ya Bethlehemu',
    amount: 85000,
    paymentMethod: 'M-Pesa',
    referenceNumber: 'QA776652',
    notes: 'Kikao cha nyumba kwa nyumba'
  },
  {
    id: 'fin-005',
    date: '2026-08-30',
    type: 'benevolence',
    category: 'Mfuko wa Huruma',
    amount: 200000,
    donorName: 'Muumini Asiyetajwa',
    paymentMethod: 'Cash',
    isAnonymous: true,
    notes: 'Kusaidia wajane na wagonjwa'
  }
];

export const INITIAL_EXPENSES: ChurchExpense[] = [
  {
    id: 'exp-01',
    date: '2026-09-02',
    title: 'Malipo ya Umeme (LUKU) & Maji ya Kanisa Kwa Matope',
    category: 'Utilities',
    amount: 180000,
    approvedBy: 'Mchungaji Askofu Messi Mgala',
    isApproved: true
  },
  {
    id: 'exp-02',
    date: '2026-09-01',
    title: 'Vifaa vya Sunday School & Vitabu vya Rangi',
    category: 'Operations',
    amount: 95000,
    approvedBy: 'James Robert',
    isApproved: true
  },
  {
    id: 'exp-03',
    date: '2026-08-28',
    title: 'Msaada wa Dawa kwa Mjane Mama Anna - Mbagala',
    category: 'Benevolence',
    amount: 150000,
    approvedBy: 'Mchungaji Askofu Messi Mgala',
    isApproved: true
  },
  {
    id: 'exp-04',
    date: '2026-09-04',
    title: 'Matengenezo ya Jenereta na Mafuta ya Akiba',
    category: 'Maintenance',
    amount: 220000,
    approvedBy: 'Inasubiri Uhakiki wa Mhazini',
    isApproved: false
  }
];

export const INITIAL_JUMUIYA_REPORTS: JumuiyaReport[] = [
  {
    id: 'rep-001',
    jumuiyaId: 'jum-1',
    jumuiyaName: 'Jumuiya ya Kwa Matope',
    reportDate: '2026-09-04',
    hostFamily: 'Kaya ya Mzee Emmanuel Mtweve',
    attendeesMen: 8,
    attendeesWomen: 14,
    attendeesYouth: 6,
    attendeesChildren: 7,
    newVisitors: 3,
    scriptureTopic: 'Kudumu Katika Maombi na Upendo wa Kidugu (Waebrania 13:1)',
    offeringAmount: 95000,
    prayerRequests: 'Kumuombea kijana Samuel anayefanya mitihani ya kidato cha nne na uponyaji wa watoto.',
    sickOrWelfareNeeds: 'Mama Joyce anasumbuliwa na mguu, anaomba kutembelewa na timu ya maombi ya kanisa.',
    submittedBy: 'Mzee Emmanuel Mtweve',
    submittedAt: '2026-09-04 20:30'
  },
  {
    id: 'rep-002',
    jumuiyaId: 'jum-2',
    jumuiyaName: 'Jumuiya ya Mbagala Kuu',
    reportDate: '2026-09-04',
    hostFamily: 'Kaya ya Ndg. Charles Swai',
    attendeesMen: 9,
    attendeesWomen: 12,
    attendeesYouth: 5,
    attendeesChildren: 4,
    newVisitors: 1,
    scriptureTopic: 'Nguvu ya Neno la Mungu Maishani (Zaburi 119:105)',
    offeringAmount: 85000,
    prayerRequests: 'Kushukuru kwa ajili ya uzazi salama wa dada Grace.',
    sickOrWelfareNeeds: 'Wote wazima kwa neema ya Mungu, hakuna mgonjwa wiki hii.',
    submittedBy: 'Mwl. Daudi Msechu',
    submittedAt: '2026-09-04 21:00'
  }
];

export const INITIAL_MEMBERS: ChurchMember[] = [
  {
    id: 'mem-1',
    fullName: 'Mchungaji Askofu Messi Mgala',
    phone: '+255 754 000 001',
    gender: 'Female',
    ageGroup: 'Adult',
    jumuiyaId: 'jum-1',
    isBaptized: true,
    role: 'Mchungaji Kiongozi & Askofu',
    joinedDate: '2012-01-01'
  },
  {
    id: 'mem-2',
    fullName: 'James Robert',
    phone: '+255 754 000 002',
    gender: 'Male',
    ageGroup: 'Adult',
    jumuiyaId: 'jum-1',
    isBaptized: true,
    role: 'Mume wa Askofu / Mshauri wa Uongozi',
    joinedDate: '2012-01-01'
  },
  {
    id: 'mem-3',
    fullName: 'Mzee Emmanuel Mtweve',
    phone: '+255 754 332 110',
    gender: 'Male',
    ageGroup: 'Adult',
    jumuiyaId: 'jum-1',
    isBaptized: true,
    role: 'Mzee wa Kanisa & Kiongozi wa Jumuiya',
    joinedDate: '2015-03-10'
  },
  {
    id: 'mem-4',
    fullName: 'Mama Sarah Mkude',
    phone: '+255 768 778 990',
    gender: 'Female',
    ageGroup: 'Adult',
    jumuiyaId: 'jum-3',
    isBaptized: true,
    role: 'Kiongozi wa Kwaya ya Upendo',
    joinedDate: '2017-06-14'
  },
  {
    id: 'mem-5',
    fullName: 'Ndg. Baraka Mlay',
    phone: '+255 784 112 334',
    gender: 'Male',
    ageGroup: 'Adult',
    jumuiyaId: 'jum-4',
    isBaptized: true,
    role: 'Kiongozi wa Kwaya ya Galilaya',
    joinedDate: '2018-09-01'
  }
];

export const DEVOTIONAL_VERSES: DevotionalVerse[] = [
  {
    id: 'devo-1',
    swahiliText: 'Bwana ndiye mchungaji wangu, sitapungukiwa na kitu. Katika malisho ya majani mabichi hunilaza, kando ya maji ya utulivu huniongoza.',
    englishText: 'The Lord is my shepherd; I shall not want. He maketh me to lie down in green pastures: he leadeth me beside the still waters.',
    reference: 'Zaburi 23:1-2',
    category: 'Amani',
    pastoralReflection: 'Mungu anapokuwa kiongozi na mchungaji wa maisha yako, mashaka yote ya kesho yanakoma. Amini uongozi wake leo hata katika nyakati ngumu.',
    reflectionEn: 'When the Lord shepherds your life, all anxieties about tomorrow fade away. Trust His faithful guidance today.',
    prayer: 'Ee Bwana, ninaweka maisha yangu na familia yangu mikononi mwako. Niongoze kando ya maji ya utulivu na unipe amani yako ipitayo akili zote. Amina.'
  },
  {
    id: 'devo-2',
    swahiliText: 'Nayaweza mambo yote katika yeye anitiaye nguvu.',
    englishText: 'I can do all things through Christ which strengtheneth me.',
    reference: 'Wafilipi 4:13',
    category: 'Nguvu',
    pastoralReflection: 'Nguvu yako haitokani na uwezo wa kibinadamu bali inatoka kwa Kristo anayeishi ndani yako. Usikate tamaa mbele ya jaribu lolote.',
    reflectionEn: 'Your strength does not rely on human might, but upon the living Christ within you. Never lose heart.',
    prayer: 'Bwana Yesu, nitie nguvu mpya leo. Kazi na mipango yangu ikapate ushindi kupitia uwezo wako mkuu. Amina.'
  },
  {
    id: 'devo-3',
    swahiliText: 'Maana jinsi hii Mungu aliupenda ulimwengu, hata akamtoa Mwanawe pekee, ili kila mtu amwaminiye asipotee, bali awe na uzima wa milele.',
    englishText: 'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
    reference: 'Yohana 3:16',
    category: 'Upendo',
    pastoralReflection: 'Upendo wa Mungu hauna masharti na haupimiki. Alitoa kilicho cha thamani zaidi ili uwe na uzima. Ishi leo ukijua unathaminiwa na Baba.',
    reflectionEn: 'Gods unconditional love gave heaven’s greatest gift for you. Walk today knowing you are deeply cherished.',
    prayer: 'Asante Baba kwa upendo wako mkuu. Nifundishe kupenda wengine kama ulivyonipenda mimi. Amina.'
  },
  {
    id: 'devo-4',
    swahiliText: 'Bwana ni nuru yangu na wokovu wangu, nimwogope nani? Bwana ni ngome ya uzima wangu, nimhofu nani?',
    englishText: 'The Lord is my light and my salvation; whom shall I fear? The Lord is the strength of my life; of whom shall I be afraid?',
    reference: 'Zaburi 27:1',
    category: 'Ujasiri',
    pastoralReflection: 'Hofu haina nafasi pale Mungu aliye ngome ya milele anapokuwa upande wako. Simama imara na ujazwe ujasiri wa kiungu.',
    reflectionEn: 'Fear has no stronghold when the eternal God is your fortress. Stand firm with godly boldness.',
    prayer: 'Ee Mungu ngome yangu, ondoa kila hofu na mashaka rohoni mwangu. Nitembee kwa ujasiri wa ushindi. Amina.'
  },
  {
    id: 'devo-5',
    swahiliText: 'Basi imani ni kuwa na hakika ya mambo yatarajiwayo, ni bayana ya mambo yasiyoonekana.',
    englishText: 'Now faith is the substance of things hoped for, the evidence of things not seen.',
    reference: 'Waebrania 11:1',
    category: 'Imani',
    pastoralReflection: 'Imani haisubiri kuona ndipo iamini; imani inaona ahadi za Mungu zikiwa zimekamilika tayari. Endelea kuomba bila kulegea.',
    reflectionEn: 'Faith does not wait to see to believe; it sees God’s promises already accomplished. Keep praying steadfastly.',
    prayer: 'Bwana niongezee imani. Nikaweze kuona miujiza yako ikitendeka katika maisha yangu na kanisa lako Sayuni. Amina.'
  }
];

export const INITIAL_CERTIFICATES: CertificateData[] = [
  {
    id: 'cert-101',
    type: 'baptism',
    recipientName: 'Neema J. Mwakyusa',
    dateOfEvent: '2026-08-16',
    officiatingMinister: 'Mchungaji Kiongozi',
    churchSecretary: 'Katibu wa Kanisa',
    scriptureVerse: 'Matendo ya Mitume 2:38 - "Tubuni mkabatizwe kila mmoja kwa jina lake Yesu Kristo mpate ondoleo la dhambi zenu"',
    serialNumber: 'ZJ-BAP-2026-0042',
    issuedDate: '2026-08-16',
    notes: 'Ubatizo wa maji tele - Zion Jerusalem, Mbagala Kwa Matope.'
  },
  {
    id: 'cert-102',
    type: 'dedication',
    recipientName: 'Baraka J. Mushi',
    parentNames: 'Ndg. J. Mushi & Bi. A. Mlay',
    dateOfEvent: '2026-07-12',
    officiatingMinister: 'Mchungaji Kiongozi',
    churchSecretary: 'Katibu wa Kanisa',
    scriptureVerse: '1 Samweli 1:27-28 - "Naliomba mtoto huyu; Bwana akanipa dua yangu niliyomwomba"',
    serialNumber: 'ZJ-DED-2026-0018',
    issuedDate: '2026-07-12',
    notes: 'Wakfu wa mtoto madhabahuni mbele ya kusanyiko la Sayuni.'
  }
];

export const INITIAL_SERMONS: SermonItem[] = [
  {
    id: 'sermon-1',
    title: 'Kusimama Imara Katika Maombi na Tabia ya Uadilifu',
    preacher: 'Mchungaji Askofu Messi Mgala',
    date: '2026-08-30',
    scripture: 'Waefeso 6:10-18',
    summary: 'Mafundisho maalum ya kiaskofu juu ya silaha zote za Mungu, ushindi dhidi ya majaribu ya nyakati hizi, na umuhimu wa nidhamu ya maombi ya siri na ya pamoja.',
    mediaType: 'video',
    mediaUrl: 'https://youtube.com/watch?v=zion-sermon-1',
    category: 'Imani',
    likesCount: 64
  },
  {
    id: 'sermon-2',
    title: 'Nguvu ya Neno la Mungu Ndani ya Familia na Ndoa',
    preacher: 'Mchungaji Askofu Messi Mgala',
    date: '2026-08-23',
    scripture: 'Kumbukumbu la Torati 6:4-9',
    summary: 'Umuhimu wa madhabahu ya familia nyumbani (Family Altar), kulea watoto katika njia impasayo, na jinsi amani ya ndoa inavyofungua milango ya baraka za kiuchumi.',
    mediaType: 'audio',
    mediaUrl: 'https://soundcloud.com/zion-church/family-sermon',
    category: 'Familia',
    likesCount: 52
  },
  {
    id: 'sermon-3',
    title: 'Upatanisho na Ushirika wa Kweli Katika Kristo',
    preacher: 'Ndg. James Robert',
    date: '2026-08-16',
    scripture: '2 Wakorintho 5:17-21',
    summary: 'Huduma ya upatanisho, kuondoa vinyongo kanisani na majumbani, na kuwa mabalozi wazuri wa Yesu Kristo katika eneo letu la Kwa Matope na Mbagala nzima.',
    mediaType: 'text',
    category: 'Uongozi',
    likesCount: 45
  }
];

export const INITIAL_POSTERS: PastoralPoster[] = [
  {
    id: 'post-1',
    title: 'Kongamano Kuu la Sayuni — Mkesha wa Baraka na Uponyaji',
    eventDate: 'Ijumaa, 25 Septemba 2026 • Saa 3:00 Usiku Mpaka Asubuhi',
    location: 'Kanisa Kuu la Sayuni Yerusalemu, Kwa Matope - Mbagala',
    imageUrl: 'pastoral_leadership.jpg',
    description: 'Mkesha mkubwa wa maombezi, kufunguliwa, na kuvuka viwango vya kiroho. Huduma ya maombezi itaongozwa na Mchungaji Askofu Messi Mgala.',
    speaker: 'Mchungaji Askofu Messi Mgala & Wachungaji Wageni',
    status: 'active'
  },
  {
    id: 'post-2',
    title: 'Semina ya Vijana & Maendeleo: Kijana Simama Imara',
    eventDate: 'Jumamosi, 18 Septemba 2026 • Saa 8:00 Mchana',
    location: 'Ukumbi wa Kanisa, Mbagala Kwa Matope',
    imageUrl: 'zion_worship_choir.jpg',
    description: 'Semina ya kipekee inayofundisha stadi za maisha, biashara, uchumi, maadili ya kikristo, na kuepuka mitego ya ujana.',
    speaker: 'Ndg. James Robert & Walimu Waliobobea',
    status: 'upcoming'
  },
  {
    id: 'post-3',
    title: 'Tamasha la Sifa & Sikukuu ya Mavuno',
    eventDate: 'Jumapili, 04 Oktoba 2026 • Saa 2:30 Asubuhi',
    location: 'Uwanja wa Kanisa, Kwa Matope',
    imageUrl: 'zion_worship_choir.jpg',
    description: 'Tamasha kubwa la uimbaji linalohusisha Kwaya ya Galilaya, Kwaya ya Upendo, Kwaya ya Wamama, Kwaya ya Vijana na Praise & Worship Team.',
    speaker: 'Mchungaji Askofu Messi Mgala',
    status: 'upcoming'
  }
];

export const INITIAL_ELDER_CASES: ElderCounselingCase[] = [
  {
    id: 'eld-01',
    title: 'Ushauri wa Amani na Maridhiano ya Kifamilia',
    memberOrFamily: 'Familia ya Ndg. Peter & Mama Joyce',
    elderInCharge: 'Mzee Emmanuel Mtweve',
    category: 'Ndoa & Familia',
    date: '2026-09-02',
    status: 'resolved',
    notes: 'Kikao cha ushauri kilifanyika ofisi ya wazee. Maelewano yamerudi na wamekabidhiwa maombi ya pamoja ya nyumbani.'
  },
  {
    id: 'eld-02',
    title: 'Ziara ya Kichungaji kwa Mgonjwa Aliyelazwa',
    memberOrFamily: 'Mzee Lucas Kavishe (Mbagala Kizuiani)',
    elderInCharge: 'Mzee Yohana Kilonzo',
    category: 'Maombi ya Wagonjwa',
    date: '2026-09-04',
    status: 'active',
    notes: 'Timu ya wazee wawili itatembelea kaya yake Jumamosi saa 9:00 alasiri kwa maombi na kumpatia ushirika mtakatifu.'
  },
  {
    id: 'eld-03',
    title: 'Maandalizi ya Vijana Wanaotarajia Ndoa',
    memberOrFamily: 'Ndg. Samuel & Dada Esther',
    elderInCharge: 'Mzee Emmanuel Mtweve',
    category: 'Ushauri Nasaha',
    date: '2026-09-01',
    status: 'pending_pastor',
    notes: 'Vipindi 4 vya awali vya mafundisho ya wazee vimekamilika. Wanaripotiwa kwa Askofu Messi Mgala kwa hatua ya mwisho ya kiuchungaji.'
  }
];

export const INITIAL_CHOIR_SONGS: ChoirSong[] = [
  {
    id: 'song-01',
    title: 'Bwana Ameichagua Sayuni (Zaburi 132)',
    choirName: 'Kwaya ya Galilaya',
    key: 'G Major',
    tempo: '108 BPM',
    audioDemoUrl: 'https://audio.zionjerusalem.org/choir/sayuni.mp3',
    lyrics: 'Kwa kuwa Bwana ameichagua Sayuni; Ameitamani akae ndani yake. Hapa ndipo pumziko langu...',
    rehearsalDate: 'Ijumaa Saa 10:00 Jioni'
  },
  {
    id: 'song-02',
    title: 'Upendo wa Ajabu wa Msalaba',
    choirName: 'Kwaya ya Upendo',
    key: 'F Major',
    tempo: '82 BPM',
    audioDemoUrl: 'https://audio.zionjerusalem.org/choir/upendo.mp3',
    lyrics: 'Upendo gani huu Baba alionao kwangu, hata akamtoa mwanawe wa pekee afe msalabani...',
    rehearsalDate: 'Jumamosi Saa 9:00 Alasiri'
  },
  {
    id: 'song-03',
    title: 'Yesu Ni Mwamba wa Milele',
    choirName: 'Kwaya ya Wamama',
    key: 'C Major',
    tempo: '96 BPM',
    lyrics: 'Mwamba uliopasuka kwa ajili yangu, nijifiche ndani yako...',
    rehearsalDate: 'Jumanne Saa 10:30 Jioni'
  },
  {
    id: 'song-04',
    title: 'Simama Imara Ewe Kijana',
    choirName: 'Kwaya ya Vijana',
    key: 'D Major',
    tempo: '124 BPM',
    lyrics: 'Mtegemee Bwana kwa moyo wako wote, wala usizitegemee akili zako mwenyewe...',
    rehearsalDate: 'Jumamosi Saa 11:00 Jioni'
  },
  {
    id: 'song-05',
    title: 'Mtakatifu Bwana wa Majeshi (Praise Entry)',
    choirName: 'Praise & Worship Team',
    key: 'E Major',
    tempo: '74 BPM',
    lyrics: 'Mtakatifu, mtakatifu, mbingu na nchi zimejaa utukufu wako Ee Bwana...',
    rehearsalDate: 'Alhamisi Saa 11:00 Jioni'
  }
];

export const INITIAL_DEPARTMENTS: DepartmentInfo[] = [
  {
    id: 'dept-wamama',
    name: "Women's Fellowship",
    nameSw: 'Umoja wa Wanawake (Wamama)',
    leader: 'Mama Sarah Mkude',
    phone: '+255 768 778 990',
    memberCount: 58,
    meetingSchedule: 'Kila Jumanne Saa 10:30 Jioni',
    currentProject: 'Mfuko wa Huruma & Kusaidia Wajane na Yatima',
    upcomingEvent: 'Semina ya Mama Mjenzi wa Nyumba (12 Septemba)',
    description: 'Idara inayolea akina mama kiroho, kimaombi, na kifamilia, ikiwa nguzo imara ya mshikamano wa kanisa la Sayuni.'
  },
  {
    id: 'dept-wanaume',
    name: "Men's Fellowship",
    nameSw: 'Umoja wa Wanaume (Wababa)',
    leader: 'Mzee Emmanuel Mtweve',
    phone: '+255 754 332 110',
    memberCount: 42,
    meetingSchedule: 'Jumamosi ya Mwisho wa Mwezi Saa 1:00 Asubuhi',
    currentProject: 'Ujenzi wa Maegesho na Ukarabati wa Paa',
    upcomingEvent: 'Mkutano wa Kiamsha Kinywa cha Wanaume (26 Septemba)',
    description: 'Kuwaandaa wanaume kuwa makuhani wa familia zao, viongozi wenye mifano mema, na wasimamizi wakuu wa miradi ya kanisa.'
  },
  {
    id: 'dept-vijana',
    name: 'Youth Ministry',
    nameSw: 'Umoja wa Vijana (Youth)',
    leader: 'Ndg. Baraka Mlay',
    phone: '+255 784 112 334',
    memberCount: 46,
    meetingSchedule: 'Kila Jumamosi Saa 10:00 Jioni',
    currentProject: 'Vyombo vya Muziki na Utangazaji wa Kidijitali',
    upcomingEvent: 'Tamasha la Uinjilisti Mitaani Mbagala (19 Septemba)',
    description: 'Kuinua kizazi chenye hofu ya Mungu, ubunifu wa biashara na kazi, na uhodari katika huduma ya uinjilisti na vyombo vya habari.'
  },
  {
    id: 'dept-watoto',
    name: 'Children & Sunday School',
    nameSw: 'Idara ya Watoto (Sunday School)',
    leader: 'Mwl. Grace Mollel',
    phone: '+255 754 998 877',
    memberCount: 35,
    meetingSchedule: 'Kila Jumapili Saa 3:00 Asubuhi',
    currentProject: 'Vitabu vya Hadithi za Biblia & Rangi',
    upcomingEvent: 'Sikukuu ya Watoto Kukariri Mistari ya Biblia (27 Septemba)',
    description: 'Kujenga msingi imara wa kiroho kwa watoto tangu wakiwa wadogo kwa upendo, hadithi za kimaandiko, na nyimbo za sifa.'
  }
];
