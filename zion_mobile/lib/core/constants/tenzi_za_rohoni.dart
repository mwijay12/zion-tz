class TenziSong {
  final int number;
  final String title;
  final String lyrics;
  final String key;
  final String tempo;

  const TenziSong({
    required this.number,
    required this.title,
    required this.lyrics,
    this.key = 'G',
    this.tempo = 'Moderato',
  });
}

class TenziZaRohoniData {
  static const List<TenziSong> songs = [
    TenziSong(
      number: 1,
      title: 'Takuandama Mwokozi',
      lyrics: '''1. Takuandama Mwokozi, popote uendapo,
   Takuandama Mwokozi, popote uendapo.
   Popote uendapo, nami nitakuandama,
   Popote uendapo, nami nitakuandama.

2. Katika kila jaribu, utanishika mkono,
   Katika kila jaribu, utanishika mkono.
   Nishike mkono wangu, unipitishe salama,
   Nishike mkono wangu, unipitishe salama.

3. Nitakapofika mwisho, wa safari ya dunia,
   Nitakapofika mwisho, wa safari ya dunia.
   Unipokee mbinguni, nikae nawe milele,
   Unipokee mbinguni, nikae nawe milele.''',
      key: 'F',
      tempo: 'Andante',
    ),
    TenziSong(
      number: 2,
      title: 'Salama Rohoni (It Is Well)',
      lyrics: '''1. Nionapo amani kama mto,
   Au nionapo shida;
   Kwa hali yoyote umenifundisha,
   Ni salama, rohoni mwangu.

   Kionjo:
   Salama, rohoni,
   Ni salama rohoni mwangu.

2. Ijapokuwa Shetani atanitesa,
   Na majaribu yatanijia,
   Lakini najua Mwokozi yu hai,
   Amenifia msalabani.

3. Dhambi zangu zote, naam, zote pia,
   Zimeoshwa kwa damu yake;
   Sizikumbuki tena, asifiwe Bwana,
   Ni salama rohoni mwangu.''',
      key: 'C',
      tempo: 'Slow',
    ),
    TenziSong(
      number: 3,
      title: 'Twende kwa Yesu',
      lyrics: '''1. Twende kwa Yesu, Mkombozi wetu,
   Naye atatukaribisha kwake.
   Tupate heri na uzima tele,
   Twende kwa Yesu sasa hivi.

   Kionjo:
   Twende kwa Yesu, twende sasa,
   Twende kwa Yesu, twende sasa.

2. Dhambi zetu zote atazifuta,
   Na Roho Mtakatifu atatujaza.
   Atatuongoza katika kweli,
   Twende kwa Yesu sasa hivi.''',
      key: 'Bb',
      tempo: 'Cheerful',
    ),
    TenziSong(
      number: 4,
      title: 'Yesu Unijaze Leo',
      lyrics: '''1. Yesu unijaze leo kwa Roho Mtakatifu,
   Nipate nguvu ya kushinda majaribu yote.
   Niongoze katika njia ya utakatifu,
   Yesu unijaze leo, Bwana nakuomba.

   Kionjo:
   Unijaze leo, unijaze leo,
   Bwana unijaze leo kwa Roho wako.

2. Ninakuhitaji kila saa na kila dakika,
   Bila wewe siwezi kufanya jambo lolote.
   Nijaze upendo na imani ya kweli,
   Yesu unijaze leo, Bwana nakuomba.''',
      key: 'G',
      tempo: 'Prayerfully',
    ),
    TenziSong(
      number: 5,
      title: 'Damu ya Yesu',
      lyrics: '''1. Damu ya Yesu inasafisha,
   Inasafisha kuliko barafu.
   Dhambi zangu zote zimeondolewa,
   Kwa damu ya Yesu msalabani.

   Kionjo:
   Inasafisha, inasafisha,
   Damu ya Yesu inasafisha.

2. Alikufa kwa ajili yangu mimi,
   Aliteswa ili nipate uzima.
   Sifa na utukufu kwa Mwana wa Mungu,
   Damu ya Yesu inasafisha.''',
      key: 'E',
      tempo: 'Worship',
    ),
    TenziSong(
      number: 108,
      title: 'Twenenda Sayuni',
      lyrics: '''1. Mpendao Bwana, mtoe sifa zenu,
   Na mshiriki kwa furaha, na mshiriki kwa furaha,
   Kuzunguka kiti, kuzunguka kiti cha enzi.

   Kionjo:
   Twenenda Sayuni, Sayuni nzuri sana,
   Twenenda Sayuni, mji mzuri wa Mungu.

2. Wasio mcha Mungu, wasimbe sifa hizi,
   Bali wana wa Mbinguni, bali wana wa Mbinguni,
   Hueneza sifa, hueneza sifa zake.

3. Milima ya Sayuni, hutoa baraka tele,
   Kabla hatujafika, kabla hatujafika,
   Kwenye mitaa ya dhahabu, kwenye mitaa ya dhahabu.''',
      key: 'G',
      tempo: 'Joyful',
    ),
    TenziSong(
      number: 114,
      title: 'Bwana Mungu, Nashangaa Kabisa',
      lyrics: '''1. Bwana Mungu, nashangaa kabisa,
   Nikifikiri kote ulikounda,
   Naona nyota, nasikia radi,
   Nguvu yako kote inadhihirika.

   Kionjo:
   Roho yangu na ikuimbie,
   Jinsi wewe ulivyo mkuu.
   Roho yangu na ikuimbie,
   Jinsi wewe ulivyo mkuu.

2. Nikitembea sasa msituni,
   Nasikia ndege wakiimba,
   Milima mirefu nikitazama,
   Naona upepo na maji yakishuka.

3. Nikifikiri jinsi Mungu Baba,
   Alivyomtoa Mwanae mpenzi,
   Alikufa apate nikuokoa,
   Abebe dhambi zangu msalabani.''',
      key: 'Bb',
      tempo: 'Grand',
    ),
    TenziSong(
      number: 129,
      title: 'Karibu Na Wewe',
      lyrics: '''1. Karibu na Wewe, Mungu wangu,
   Hata kwa mateso, ni karibu.
   Wimbo wangu uwe, Karibu na Wewe,
   Karibu na Wewe, Mungu wangu.

2. Hata nikichoka, na jua kushuka,
   Giza likiingia, nitasema;
   Ndoto yangu iwe, Karibu na Wewe,
   Karibu na Wewe, Mungu wangu.

3. Njia ya mbinguni, iwe wazi sasa,
   Yote unayotuma, yawe heri.
   Malaika waniite, Karibu na Wewe,
   Karibu na Wewe, Mungu wangu.''',
      key: 'G',
      tempo: 'Slow',
    ),
    TenziSong(
      number: 130,
      title: 'Niongoze Bwana Mungu',
      lyrics: '''1. Niongoze Bwana Mungu, mimi ni mgeni huku,
   Wewe una nguvu tele, mimi ni mnyonge sana.
   Mkate wa mbinguni, mkate wa mbinguni,
   Unilishe sasa na hata milele.

2. Fungua sasa chemchemi, ya maji ya uzima,
   Wingu na moto wa mbinguni, uniongoze njiani.
   Mwokozi mwenye nguvu, Mwokozi mwenye nguvu,
   Uwe ngao yangu na ulinzi wangu.

3. Nitakapofika Yordani, niondolee hofu,
   Unitupishe salama, nifikie Kaanani.
   Sifa na utukufu, sifa na utukufu,
   Nitakupa Wewe milele na milele.''',
      key: 'F',
      tempo: 'Majestic',
    ),
    TenziSong(
      number: 157,
      title: 'Kijito Cha Utakaso',
      lyrics: '''1. Kijito cha utakaso, ni damu ya Yesu,
   Inasafisha kabisa, mnyonge kama mimi.
   Naingia sasa hapa, naoshwa na Bwana,
   Nami sasa ni mweupe, kuliko barafu.

   Kionjo:
   Kijito cha utakaso, kishapita ndani yangu,
   Sifa kwa Bwana Yesu, nimeoshwa na damu.

2. Sikuogopa kuingia, katika kijito hiki,
   Nilijua kitaniponya, na dhambi zangu zote.
   Sasa nina amani kuu, na furaha tele,
   Namtukuza Mwokozi, aliyenikomboa.''',
      key: 'E',
      tempo: 'Spiritual',
    ),
    TenziSong(
      number: 33,
      title: 'Dhambi Ikikulemea',
      lyrics: '''1. Dhambi ikikulemea, mpe Yesu mzigo wako,
   Anakualika sasa, "Njooni kwangu nyote mchokao."
   Yeye ni msaidizi, katika kila taabu,
   Mpe Yesu mzigo wako, upate pumziko.

   Kionjo:
   Mpe Yesu mzigo wako, mpe Yesu mzigo wako,
   Upate pumziko, upate pumziko.

2. Amani ya ulimwengu, ni ya muda na inapita,
   Lakini amani ya Yesu, inakaa milele yote.
   Usihangaike bure, kwa mambo yasiyofaa,
   Mpe Yesu mzigo wako, upate pumziko.

3. Atakupa nguvu mpya, ya kuishi kwa utakatifu,
   Atakufuta machozi, na kukupa wimbo mpya.
   Mtumaini Yeye sasa, usisite njiani,
   Mpe Yesu mzigo wako, upate pumziko.''',
      key: 'D',
      tempo: 'Gentle',
    ),
  ];
}
