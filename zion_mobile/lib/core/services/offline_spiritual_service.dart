class DailySpiritualManna {
  final int dayIndex;
  final String title;
  final String scriptureReference;
  final String scriptureText;
  final String reflection;
  final String prayer;
  final String themeCategory;
  final int recommendedHymnNumber;
  final String recommendedHymnTitle;

  const DailySpiritualManna({
    required this.dayIndex,
    required this.title,
    required this.scriptureReference,
    required this.scriptureText,
    required this.reflection,
    required this.prayer,
    required this.themeCategory,
    required this.recommendedHymnNumber,
    required this.recommendedHymnTitle,
  });
}

class OfflineSpiritualService {
  static final OfflineSpiritualService _instance = OfflineSpiritualService._internal();
  factory OfflineSpiritualService() => _instance;
  OfflineSpiritualService._internal();

  static const List<DailySpiritualManna> _devotionalsBank = [
    DailySpiritualManna(
      dayIndex: 0,
      title: 'Sayuni — Pumziko la Milele na Maskani ya Amani',
      scriptureReference: 'Zaburi 132:13-14',
      scriptureText: 'Kwa kuwa Bwana ameichagua Sayuni; Ameitamani akae ndani yake. Hapa ndipo patakapokuwa pumziko langu milele; Hapa nitakaa kwa maana nimeitamani.',
      reflection: 'Mungu anapochagua moyo wako kuwa makao yake, hofu zote zinakimbia. Katika nyakati ngumu au changamoto za kimaisha, kumbuka kwamba wewe ni Sayuni ya Bwana ambapo uwepo wake hautapunguka kamwe.',
      prayer: 'Ee Bwana Mungu wa Sayuni, jenga moyo wangu uwe hekalu lililo safi leo. Amani yako ipite ufahamu wangu wote na itawale familia yangu na kazi zangu. Amina!',
      themeCategory: 'Amani & Uwepo',
      recommendedHymnNumber: 130,
      recommendedHymnTitle: 'Salama Rohoni Mwangu',
    ),
    DailySpiritualManna(
      dayIndex: 1,
      title: 'Ondoka Uangaze — Nuru Yako Imekuja',
      scriptureReference: 'Isaya 60:1-2',
      scriptureText: 'Ondoka, uangaze; kwa kuwa nuru yako imekuja, Na utukufu wa Bwana umekuzukia. Maana giza litaifunika dunia, bali Bwana atakuzukia wewe.',
      reflection: 'Hata pale ambapo dunia inalalamika juu ya ugumu wa maisha au giza la kiuchumi, watoto wa Mungu wana agano la kung\'aa. Simama kwa ujasiri leo ukiwa na hakika ya kibali cha Mungu juu ya mikono yako.',
      prayer: 'Baba Mtakatifu, naomba nuru yako iangaze juu ya akili yangu, biashara yangu, na hatua zangu za leo. Sitabaki gizani maana utukufu wako uko juu yangu. Katika jina la Yesu, Amina!',
      themeCategory: 'Ushindi & Nuru',
      recommendedHymnNumber: 88,
      recommendedHymnTitle: 'Usinipite Mwokozi',
    ),
    DailySpiritualManna(
      dayIndex: 2,
      title: 'Amani Katika Dhoruba — Bwana Ndiye Mchungaji Wangu',
      scriptureReference: 'Zaburi 23:1-3',
      scriptureText: 'Bwana ndiye mchungaji wangu, sitapungukiwa na kitu. Katika malisho ya majani mabichi hunilaza, kando ya maji ya utulivu huniongoza.',
      reflection: 'Mchungaji mwema hajali tu kondoo wanapokuwa salama zizini, bali huwatafuta na kuwalinda wanapopita bondeni. Hata kama huna bando au umbali wa mawasiliano, Mungu yuko karibu nawe kuliko pumzi yako.',
      prayer: 'Yesu Mwema, asante kwa kuwa Mchungaji wa maisha yangu. Ninalaza mizigo yangu yote miguuni pako asubuhi ya leo. Uniongoze katika njia za haki kwa ajili ya jina lako. Amina!',
      themeCategory: 'Ulinzi & Faraja',
      recommendedHymnNumber: 1,
      recommendedHymnTitle: 'Yesu Kwetu ni Rafiki',
    ),
    DailySpiritualManna(
      dayIndex: 3,
      title: 'Mwamini Bwana kwa Moyo Wako Wote',
      scriptureReference: 'Mithali 3:5-6',
      scriptureText: 'Mtumaini Bwana kwa moyo wako wote, wala usizitegemee akili zako mwenyewe; Katika njia zako zote mkiri yeye, naye atayanyosha mapito yako.',
      reflection: 'Akili zetu za kibinadamu zina ukomo, lakini hekima ya Mungu haina mwisho. Kabla ya kufanya maamuzi ya kibiashara, ya kifamilia au ya kazini leo, mshirikishe Roho Mtakatifu katika maombi mafupi.',
      prayer: 'Ee Mungu Mwenye Hekima, ninakukabidhi mipango yangu yote ya leo. Nyosha mapito yangu na uniepushe na mitego ya adui. Katika jina la Yesu Kristo, Amina!',
      themeCategory: 'Hekima & Mwongozo',
      recommendedHymnNumber: 45,
      recommendedHymnTitle: 'Cha Kutumaini Sina',
    ),
    DailySpiritualManna(
      dayIndex: 4,
      title: 'Wamngojao Bwana Watapata Nguvu Mpya',
      scriptureReference: 'Isaya 40:31',
      scriptureText: 'Bali wao wamngojeao Bwana watapata nguvu mpya; watapanda juu kwa mbawa kama tai; watapiga mbio wala hawatachoka; watakwenda kwa miguu wala hawatazimia.',
      reflection: 'Je, unajisikia umechoka kimwili au kiroho? Sayuni ni mahali pa kubadilishiwa nguvu. Kama tai anavyobadilisha manyoya ili kupaa juu ya mawingu, Mungu anakupa uwezo mpya wa kushinda leo.',
      prayer: 'Bwana Mungu wa Majeshi, ninakuja kwako nikiwa sina nguvu kwa nguvu zangu mwenyewe. Nirudishie nguvu ya maombi, furaha ya wokovu, na uvumilivu wa kishujaa. Amina!',
      themeCategory: 'Nguvu & Uamsho',
      recommendedHymnNumber: 24,
      recommendedHymnTitle: 'Mwamba Wenye Imara',
    ),
    DailySpiritualManna(
      dayIndex: 5,
      title: 'Msijisumbue kwa Neno Lo Lote',
      scriptureReference: 'Wafilipi 4:6-7',
      scriptureText: 'Msijisumbue kwa neno lo lote; bali katika kila neno kwa kusali na kuomba, pamoja na kushukuru, haja zenu na zijulikane na Mungu.',
      reflection: 'Wasiwasi haubadilishi kesho, bali hupunguza nguvu ya leo. Badilisha kila wasiwasi kuwa ombi. Mungu anajua unachohitaji kabla hata hujaomba, naye ni Baba mwaminifu anayejali.',
      prayer: 'Baba wa Mbinguni, ninatupa wasiwasi wote wa chakula, kodi, afya na ada za watoto mikononi mwako. Nipe amani ya moyo na shukrani isiyotikisika. Amina!',
      themeCategory: 'Imani & Amani',
      recommendedHymnNumber: 62,
      recommendedHymnTitle: 'Karibu na Wewe Mungu Wangu',
    ),
    DailySpiritualManna(
      dayIndex: 6,
      title: 'Mto wa Uzima Unaofurahisha Mji wa Mungu',
      scriptureReference: 'Zaburi 46:4-5',
      scriptureText: 'Kuna mto ambao vijito vyake huufurahisha mji wa Mungu, Patakatifu pa maskani zake Aliye juu. Mungu yu katikati yake hautatikisika.',
      reflection: 'Mji wa Mungu hautatikisika kwa sababu Yeye mwenyewe yuko katikati yake. Kanisa la Zion Jerusalem na kila muumini aliyemo ndani yake ana ulinzi wa kimalaika dhidi ya dhoruba za adui.',
      prayer: 'Mungu Uliye Juu, asante kwa kuwa ngome yangu na kimbilio langu wakati wa mateso. Simamisha miguu yangu juu ya mwamba usiotikisika. Katika jina la Yesu Kristo, Amina!',
      themeCategory: 'Ushindi wa Sayuni',
      recommendedHymnNumber: 114,
      recommendedHymnTitle: 'Niongoze Yehova Mkubwa',
    ),
  ];

  DailySpiritualManna getTodaySpiritualWord() {
    final now = DateTime.now();
    // Compute deterministic day of year (0 - 364)
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays;
    final index = dayOfYear % _devotionalsBank.length;
    return _devotionalsBank[index];
  }

  DailySpiritualManna getDevotionalForDate(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays;
    final index = dayOfYear.abs() % _devotionalsBank.length;
    return _devotionalsBank[index];
  }

  List<DailySpiritualManna> getAllOfflineDevotionals() => _devotionalsBank;
}
