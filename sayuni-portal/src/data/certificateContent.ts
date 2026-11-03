import type { CertificateType, Language } from '../types';

export interface CertificateDefinition {
  titleSw: string;
  titleEn: string;
  bodySw: string;
  bodyEn: string;
  defaultVerse: string;
  serialCode: string;
}

export const CERTIFICATE_DEFINITIONS: Record<CertificateType, CertificateDefinition> = {
  baptism: {
    titleSw: 'CHETI CHA UBATIZO WA MAJI TELE',
    titleEn: 'CERTIFICATE OF HOLY BAPTISM',
    bodySw: 'Amepokea ubatizo wa maji tele kulingana na agizo la Bwana wetu Yesu Kristo na mafundisho ya Maandiko Matakatifu.',
    bodyEn: 'Has received holy water baptism in obedience to our Lord Jesus Christ and the teachings of the Holy Scriptures.',
    defaultVerse: 'Warumi 6:4 - "Basi tulizikwa pamoja naye kwa njia ya ubatizo katika mauti yake..."',
    serialCode: 'BAP'
  },
  dedication: {
    titleSw: 'CHETI CHA WAKFU WA MTOTO',
    titleEn: 'CERTIFICATE OF CHILD DEDICATION',
    bodySw: 'Amewekwa wakfu mbele za Bwana Mungu na kusanyiko la watakatifu, kwa maombi na baraka za kiuchungaji.',
    bodyEn: 'Has been dedicated unto the Lord God before the congregation, through prayer and pastoral blessings.',
    defaultVerse: '1 Samweli 1:27-28 - "Naliomba mtoto huyu; Bwana akanipa dua yangu niliyomwomba..."',
    serialCode: 'DED'
  },
  marriage: {
    titleSw: 'CHETI CHA NDOA TAKATIFU',
    titleEn: 'CERTIFICATE OF HOLY MATRIMONY',
    bodySw: 'Wameunganishwa katika Ndoa Takatifu mbele za Mungu na mashahidi wengi kwa mujibu wa Neno la Mungu.',
    bodyEn: 'Have been united in Holy Matrimony before God and witnesses in accordance with the Word of God.',
    defaultVerse: 'Mathayo 19:6 - "Hata wamekuwa si wawili tena bali mwili mmoja. Basi alichokiunganisha Mungu, mwanadamu asikitenganishe."',
    serialCode: 'MAR'
  },
  membership: {
    titleSw: 'CHETI CHA USHIRIKA KAMILI WA KANISA',
    titleEn: 'CERTIFICATE OF FULL CHURCH MEMBERSHIP',
    bodySw: 'Ametambuliwa rasmi kama mshirika kamili wa Kanisa la Sayuni Yerusalemu mwenye haki na wajibu wote wa kiroho.',
    bodyEn: 'Has been recognized as a full registered member of Sayuni Jerusalem Church with all spiritual fellowship privileges.',
    defaultVerse: 'Waefeso 2:19 - "Basi tangu sasa ninyi si wageni wala wapitaji, bali ninyi ni wenyeji pamoja na watakatifu..."',
    serialCode: 'MEM'
  },
  service: {
    titleSw: 'CHETI CHA SHUKRANI NA UTUMISHI MWEMA',
    titleEn: 'CERTIFICATE OF APPRECIATION & SERVICE',
    bodySw: 'Kwa kutambua utumishi wake mwema, uaminifu, na kujitolea kwa dhati katika ujenzi wa ufalme wa Mungu.',
    bodyEn: 'In grateful recognition of faithful service, dedication, and steadfast contribution to the kingdom of God.',
    defaultVerse: '1 Wakorintho 15:58 - "Basi, ndugu zangu wapendwa, mwimarike, msitikisike, mkizidi sana kutenda kazi ya Bwana sikuzote..."',
    serialCode: 'SVC'
  }
};

export const CERTIFICATE_TYPE_ORDER: CertificateType[] = [
  'baptism',
  'dedication',
  'marriage',
  'membership',
  'service'
];

export function certificateTitle(type: CertificateType, language: Language): string {
  const definition = CERTIFICATE_DEFINITIONS[type];
  return language === 'sw' ? definition.titleSw : definition.titleEn;
}

export function certificateBody(type: CertificateType, language: Language): string {
  const definition = CERTIFICATE_DEFINITIONS[type];
  return language === 'sw' ? definition.bodySw : definition.bodyEn;
}
