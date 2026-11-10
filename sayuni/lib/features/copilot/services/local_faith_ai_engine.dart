import '../models/copilot_action.dart';

class LocalFaithAiResult {
  final String reply;
  final CopilotActionType actionType;
  final Map<String, dynamic> actionData;

  const LocalFaithAiResult({
    required this.reply,
    this.actionType = CopilotActionType.none,
    this.actionData = const {},
  });
}

class LocalFaithAiEngine {
  static LocalFaithAiResult processQuery(String rawInput) {
    final query = rawInput.trim().toLowerCase();

    // 1. HEARTBREAK & GRIEF SCRIPTURE INTENTS
    final isHeartbreak = query.contains('heart break') ||
        query.contains('heartbreak') ||
        query.contains('broken heart') ||
        query.contains('kuvunjika moyo') ||
        query.contains('kuumia moyo') ||
        query.contains('maumivu ya moyo') ||
        query.contains('huzuni') ||
        query.contains('grief') ||
        query.contains('sadness') ||
        query.contains('depression');

    if (isHeartbreak) {
      return const LocalFaithAiResult(
        reply:
            'Pole sana kwa maumivu unayopitia. Mungu anaona machozi yako na hapendezwi kukuona unateseka. Neno lake linatuhakikishia katika Zaburi 34:18:\n\n'
            '"Bwana yu karibu nao waliovunjika moyo, na huwaokoa waliopondeka roho."\n\n'
            'Pia Zaburi 147:3 inasema: "Huwaponya waliovunjika moyo, na kuyaganga maumivu yao." Uwe na amani, Bwana yupo pamoja nawe atakuvusha katika jaribu hili.',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': 'Zaburi 34:18',
          'book': 'Zaburi',
          'chapter': 34,
          'verse': 18,
        },
      );
    }

    // 2. JOYFUL MOMENT & THANKSGIVING SCRIPTURE INTENTS
    final isJoyful = query.contains('joyful') ||
        query.contains('joy') ||
        query.contains('furaha') ||
        query.contains('shukrani') ||
        query.contains('thanksgiving') ||
        query.contains('grateful') ||
        query.contains('celebrat') ||
        query.contains('ushindi');

    if (isJoyful) {
      return const LocalFaithAiResult(
        reply:
            'Haleluya! Ni jambo jema kumshukuru Bwana na kufurahi katika uwepo wake. Neno la Mungu katika Wafilipi 4:4 linatukumbusha:\n\n'
            '"Furahini katika Bwana sikuzote; tena nasema, Furahini!"\n\n'
            'Na 1 Wathesalonike 5:16-18: "Furahini sikuzote; ombeni bila kukoma; shukuruni kwa kila jambo; maana hayo ni mapenzi ya Mungu kwenu katika Kristo Yesu." Mungu aendelee kukujaza furaha na amani tele!',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': 'Wafilipi 4:4',
          'book': 'Wafilipi',
          'chapter': 4,
          'verse': 4,
        },
      );
    }

    // 3. ANXIETY, FEAR & WORRY SCRIPTURE INTENTS
    final isAnxiety = query.contains('anxi') ||
        query.contains('wasiwasi') ||
        query.contains('worry') ||
        query.contains('hofu') ||
        query.contains('fear') ||
        query.contains('stress') ||
        query.contains('mashaka') ||
        query.contains('afraid');

    if (isAnxiety) {
      return const LocalFaithAiResult(
        reply:
            'Usiwe na hofu wala mashaka, mkono wa Mungu u thabiti juu ya maisha yako. Neno la Bwana linatuasa katika Wafilipi 4:6-7:\n\n'
            '"Msijisumbue kwa neno lo lote; bali katika kila neno kwa kusali na kuomba, pamoja na kushukuru, haja zenu na zijulikane na Mungu. Na amani ya Mungu, ipitayo akili zote, italinda mioyo yenu na nia zenu katika Kristo Yesu."\n\n'
            'Tupa mahangaiko yako yote kwa Yesu maana yeye anajali sana maisha yako (1 Petro 5:7).',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': 'Wafilipi 4:6',
          'book': 'Wafilipi',
          'chapter': 4,
          'verse': 6,
        },
      );
    }

    // 4. SICKNESS & HEALING INTENTS
    final isHealing = query.contains('ugonjwa') ||
        query.contains('sick') ||
        query.contains('illness') ||
        query.contains('uponyaji') ||
        query.contains('healing') ||
        query.contains('naumwa') ||
        query.contains('maradhi');

    if (isHealing) {
      return const LocalFaithAiResult(
        reply:
            'Bwana Yesu ndiye daktari mkuu na mponyaji wetu. Neno la Bwana linasema katika Isaya 53:5:\n\n'
            '"Bali alijeruhiwa kwa makosa yetu, alichubuliwa kwa maovu yetu; adhabu ya amani yetu ilikuwa juu yake, na kwa kupigwa kwake sisi tumepona."\n\n'
            'Tunaamini na kutangaza uponyaji juu ya mwili na roho yako kwa jina la Yesu!',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': 'Isaya 53:5',
          'book': 'Isaya',
          'chapter': 53,
          'verse': 5,
        },
      );
    }

    // 5. NIGHT PRAYER & BEDTIME SCRIPTURE INTENTS (Bilingual: Swahili & English)
    final isNightPrayer = (query.contains('night') ||
            query.contains('usiku') ||
            query.contains('lala') ||
            query.contains('sleep') ||
            query.contains('bedtime') ||
            query.contains('usingizi') ||
            query.contains('jioni') ||
            query.contains('evening')) &&
        (query.contains('prayer') ||
            query.contains('verse') ||
            query.contains('omba') ||
            query.contains('dua') ||
            query.contains('sala') ||
            query.contains('mstari') ||
            query.contains('biblia') ||
            query.contains('scripture') ||
            query.contains('neno') ||
            query.contains('suggest'));

    if (isNightPrayer) {
      return const LocalFaithAiResult(
        reply:
            'Amani ya Kristo iwe nawe unapoenda kupumzika. Neno la Mungu kwa ajili ya maombi yako ya usiku linatoka katika Zaburi 91:4:\n\n'
            '"Kwa manyoya yake atakufunika, na chini ya mbawa zake utapata kimbilio; uaminifu wake ni ngao na kigao."\n\n'
            'Pia Zaburi 4:8 inatuhakikishia: "Katika amani nitajilaza na kupata usingizi mara, maana wewe, Bwana, peke yako, ndiye unifanyaye nikae salama." Pumzika kwa utulivu ukijua Mungu anakulinda.',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': 'Zaburi 91:4',
          'book': 'Zaburi',
          'chapter': 91,
          'verse': 4,
        },
      );
    }

    // 2. MORNING PRAYER & DAYLIGHT SCRIPTURE INTENTS
    final isMorningPrayer = (query.contains('morning') ||
            query.contains('asubuhi') ||
            query.contains('alfajiri') ||
            query.contains('amka') ||
            query.contains('day')) &&
        (query.contains('prayer') ||
            query.contains('verse') ||
            query.contains('omba') ||
            query.contains('dua') ||
            query.contains('sala') ||
            query.contains('mstari') ||
            query.contains('biblia') ||
            query.contains('scripture') ||
            query.contains('neno') ||
            query.contains('suggest'));

    if (isMorningPrayer) {
      return const LocalFaithAiResult(
        reply:
            'Habari ya asubuhi! Neno la kuanza siku yako kwa ushindi linatoka katika Zaburi 143:8:\n\n'
            '"Unifanye kusikia fadhili zako asubuhi, kwa maana nimekutumaini wewe; unijulishe njia nitakayoiendea, maana nakuinulia nafsi yangu."\n\n'
            'Baraka za Bwana zikufuate katika kazi, safari na shughuli zako zote za leo!',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': 'Zaburi 143:8',
          'book': 'Zaburi',
          'chapter': 143,
          'verse': 8,
        },
      );
    }

    // 3. GENERAL SCRIPTURE SUGGESTIONS (e.g. "suggest bible verse", "nipe mstari wa biblia")
    if ((query.contains('verse') || query.contains('mstari') || query.contains('scripture')) &&
        (query.contains('suggest') || query.contains('pendekeza') || query.contains('nipe') || query.contains('soma') || query.contains('give')) &&
        !query.contains('kitabu') &&
        !query.contains('agiz')) {
      return const LocalFaithAiResult(
        reply:
            'Neno thabiti la Bwana kwa ajili yako leo linatoka katika Zaburi 23:1-3:\n\n'
            '"Bwana ndiye mchungaji wangu, sitapungukiwa na kitu. Hunilaza katika malisho ya majani mabichi; huniongoza kando ya maji ya utulivu. Hunihuisha nafsi yangu."\n\n'
            'Tafakari wema na uaminifu wa Mungu anayekuongoza hatua kwa hatua.',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': 'Zaburi 23:1',
          'book': 'Zaburi',
          'chapter': 23,
          'verse': 1,
        },
      );
    }

    // 4. BIBLICAL FIGURES & HEROES OF FAITH (Offline Knowledge)
    // NOAH / NUHU
    if (query.contains('noah') || query.contains('nuhu')) {
      return const LocalFaithAiResult(
        reply:
            'Nuhu (Noah) alikuwa mtu wa haki na mkamilifu katika kizazi chake, naye alitembea pamoja na Mungu (Mwanzo 6:9).\n\n'
            'Wakati dunia ilipojaa maovu, Mungu alimwokoa Nuhu na familia yake kupitia Safina wakati wa gharika kuu kutokana na utii na imani yake thabiti.\n\n'
            'Katika Waebrania 11:7 imeandikwa: "Kwa imani Nuhu akiisha kuonywa na Mungu katika habari za mambo yasiyoonekana bado, kwa jinsi alivyomcha Mungu, aliunda safina..."\n\n'
            'Mfano wa Nuhu unatufundisha kusimama imara katika imani na kumtii Mungu hata wakati ulimwengu unapoenda kinyume na mapenzi yake.',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': 'Mwanzo 6:9',
          'book': 'Mwanzo',
          'chapter': 6,
          'verse': 9,
        },
      );
    }

    // ABRAHAM / IBRAHIMU
    if (query.contains('abraham') || query.contains('ibrahimu')) {
      return const LocalFaithAiResult(
        reply:
            'Ibrahimu (Abraham) anajulikana kama "baba wa imani". Mungu alimwita atoke katika nchi yake aende nchi atakayomwonyesha (Mwanzo 12:1-3).\n\n'
            'Kwa imani alitii bila kujua aendako, na Mungu alifanya naye agano la kuwa baraka kwa mataifa yote duniani. Warumi 4:3 inasema: "Ibrahimu alimwamini Mungu, ikahesabiwa kwake kuwa haki."',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': 'Mwanzo 12:1',
          'book': 'Mwanzo',
          'chapter': 12,
          'verse': 1,
        },
      );
    }

    // MOSES / MUSA
    if (query.contains('moses') || query.contains('musa')) {
      return const LocalFaithAiResult(
        reply:
            'Musa alikuwa mtumishi mkuu wa Mungu aliyeitwa kupitia kichaka kilichokuwa kikiwaka moto (Kutoka 3).\n\n'
            'Aliongoza wana wa Israeli kutoka utumwani Misri, akavusha watu Bahari ya Shamu, na kupokea Amri Kumi za Mungu kule Mlima Sinai. Alikuwa mtumishi mnyenyekevu sana kuliko watu wote duniani (Hesabu 12:3).',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': 'Kutoka 3:14',
          'book': 'Kutoka',
          'chapter': 3,
          'verse': 14,
        },
      );
    }

    // DAVID / DAUDI
    if (query.contains('david') || query.contains('daudi')) {
      return const LocalFaithAiResult(
        reply:
            'Mfalme Daudi alikuwa "mtu anayeupendeza moyo wa Mungu" (1 Samweli 13:14). Kutoka kuwa mchungaji wa kondoo hadi kumpiga Goliathi kwa jiwe na kombeo (1 Samweli 17).\n\n'
            'Daudi pia alikuwa mwimbaji na mwandishi wa Zaburi nyingi zinazotupa faraja, zikiwemo Zaburi 23 na Zaburi 51.',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': 'Zaburi 23:1',
          'book': 'Zaburi',
          'chapter': 23,
          'verse': 1,
        },
      );
    }

    // JESUS / YESU KRISTO
    if (query.contains('jesus') || query.contains('yesu') || query.contains('kristo') || query.contains('christ')) {
      return const LocalFaithAiResult(
        reply:
            'Yesu Kristo ni Mwana wa Mungu, Bwana na Mwokozi wetu aliyetupenda hata akatoa uhai wake msalabani ili tupate msamaha wa dhambi na uzima wa milele.\n\n'
            '"Kwa maana jinsi hii Mungu aliupenda ulimwengu, hata akamtoa Mwanawe pekee, ili kila mtu amwaminiye asipotee, bali awe na uzima wa milele." (Yohana 3:16)',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': 'Yohana 3:16',
          'book': 'Yohana',
          'chapter': 3,
          'verse': 16,
        },
      );
    }

    // 5. THEME SWITCHING INTENTS (Strict: Requires theme keywords, avoids false triggers on usiku/night)
    final hasThemeKeyword = query.contains('theme') ||
        query.contains('mandhari') ||
        query.contains('mode') ||
        query.contains('muonekano') ||
        query.contains('badili') ||
        query.contains('switch');

    if ((hasThemeKeyword && (query.contains('dark') || query.contains('giza') || query.contains('nyeusi'))) ||
        query == 'dark mode' ||
        query == 'giza' ||
        query == 'weka giza') {
      return const LocalFaithAiResult(
        reply:
            'Amina! Nimekuwekea mandhari ya giza (Dark Mode) ili kukulinda macho na kukuwezesha kusoma Neno la Mungu kwa utulivu. "Neno lako ni taa ya miguu yangu, na mwanga wa njia yangu." (Zaburi 119:105)',
        actionType: CopilotActionType.changeTheme,
        actionData: {'mode': 'dark'},
      );
    }

    if ((hasThemeKeyword && (query.contains('light') || query.contains('mchana') || query.contains('nyeupe'))) ||
        query == 'light mode' ||
        query == 'mchana' ||
        query == 'weka mchana') {
      return const LocalFaithAiResult(
        reply:
            'Amina! Nimekuwekea mandhari angavu ya mchana (Light Mode). "Nuru yako na iangaze mbele ya watu, wapate kuyaona matendo yenu mema." (Mathayo 5:16)',
        actionType: CopilotActionType.changeTheme,
        actionData: {'mode': 'light'},
      );
    }

    if ((hasThemeKeyword && (query.contains('gold') || query.contains('dhahabu') || query.contains('liturujia'))) ||
        query == 'gold mode' ||
        query == 'dhahabu') {
      return const LocalFaithAiResult(
        reply:
            'Amina! Nimekuwekea mandhari ya heshima ya Kiliturujia ya Dhahabu (Liturgical Gold Mode) ya Sayuni. "Bwana atatukuzwa katika Sayuni, naye ametukuka juu ya watu wote." (Zaburi 99:2)',
        actionType: CopilotActionType.changeTheme,
        actionData: {'mode': 'gold'},
      );
    }

    // 2. BOOKSTORE & PRODUCT INTENTS
    if (query.contains('agiz') ||
        query.contains('nunua') ||
        query.contains('order') ||
        query.contains('kitabu') ||
        query.contains('bei') ||
        query.contains('duka') ||
        query.contains('bidhaa')) {
      CopilotProductItem matched = CopilotProductItem.churchCatalog[0];

      if (query.contains('biblia')) {
        matched = CopilotProductItem.churchCatalog[1];
      } else if (query.contains('askofu') || query.contains('ushindi') || query.contains('mafundisho')) {
        matched = CopilotProductItem.churchCatalog[2];
      } else if (query.contains('sunday') || query.contains('watoto')) {
        matched = CopilotProductItem.churchCatalog[3];
      } else if (query.contains('kwaya')) {
        matched = CopilotProductItem.churchCatalog[4];
      }

      return LocalFaithAiResult(
        reply:
            'Tumepokea ombi lako la kitabu cha "${matched.title}". Bei yake ni ${matched.priceFormatted}. Unaweza kukamilisha oda yako sasa hivi hapa chini na kitatunzwa ofisi ya kanisa au kukuletea kupitia tawi lako.',
        actionType: CopilotActionType.orderProduct,
        actionData: {
          'productId': matched.id,
          'productTitle': matched.title,
          'priceFormatted': matched.priceFormatted,
          'priceTzs': matched.priceTzs,
          'description': matched.description,
        },
      );
    }

    // 3. HYMN / TENZI INTENTS
    final tenziMatch = RegExp(r'(?:tenzi|wimbo)\s*(?:namba|no|#)?\s*(\d+)', caseSensitive: false).firstMatch(query);
    if (tenziMatch != null) {
      final hymnNum = int.tryParse(tenziMatch.group(1) ?? '1') ?? 1;
      return LocalFaithAiResult(
        reply:
            'Wimbo wa Tenzi za Rohoni #$hymnNum uko tayari. Imba kwa moyo wa kumsifu Mungu wa Sayuni. Bonyeza kitufe hapa chini kufungua wimbo huu moja kwa moja.',
        actionType: CopilotActionType.openHymn,
        actionData: {'hymnNumber': hymnNum},
      );
    }

    if (query.contains('tenzi') || query.contains('nyimbo za roho') || query.contains('mwamba wenye imara')) {
      return const LocalFaithAiResult(
        reply:
            'Tenzi 46 + Nyimbo 78, maneno kamili bila mtandao. Bonyeza hapa chini kuingia kwenye orodha.',
        actionType: CopilotActionType.openHymn,
        actionData: {'hymnNumber': 1},
      );
    }

    // 4. SCRIPTURE / BIBLIA INTENTS
    final bibliaMatch = RegExp(r'([1-3]?\s*[a-zA-Z]+)\s*(\d+)[:\s]+(\d+)', caseSensitive: false).firstMatch(query);
    if (bibliaMatch != null) {
      final book = bibliaMatch.group(1)?.trim() ?? 'Yohana';
      final chapter = int.tryParse(bibliaMatch.group(2) ?? '1') ?? 1;
      final verse = int.tryParse(bibliaMatch.group(3) ?? '1') ?? 1;
      final ref = '$book $chapter:$verse';

      return LocalFaithAiResult(
        reply:
            'Amina! Fungua Maandiko Matakatifu ya $ref. Neno la Mungu lina nguvu na uzima kwa maisha yako leo.',
        actionType: CopilotActionType.openScripture,
        actionData: {
          'reference': ref,
          'book': book,
          'chapter': chapter,
          'verse': verse,
        },
      );
    }

    // 5. SERVICE SCHEDULES & CHURCH INFO
    if (query.contains('ratiba') ||
        query.contains('ibada') ||
        query.contains('saa') ||
        query.contains('jumapili') ||
        query.contains('wapi') ||
        query.contains('mahali')) {
      return const LocalFaithAiResult(
        reply:
            'RATIBA YA IBADA — ZION JERUSALEM (Mbagala Kwa Matope HQ):\n'
            '• Jumapili Saa 3:00 - 4:00 Asubuhi: Sunday School & Darasa la Imani.\n'
            '• Jumapili Saa 4:00 Asubuhi - 7:00 Mchana: Ibada Kuu ya Neno na Sifa.\n'
            '• Jumatano Saa 10:00 Jioni: Maombi Maalum na Ushauri wa Kichungaji.\n'
            '• Ijumaa Saa 10:00 Jioni: Maombi ya Ukombozi na Uponyaji.\n'
            '• Vituo vya Matawi: Kibondemaji, Morogoro, Bukoba, Njombe, Makambako, Kisemvule, Vikindu.',
        actionType: CopilotActionType.none,
      );
    }

    // 6. RADIO STREAMING INTENT
    if (query.contains('redio') || query.contains('radio') || query.contains('sauti') || query.contains('live')) {
      return const LocalFaithAiResult(
        reply:
            'Redio ya Sayuni inakuletea nyimbo za injili na mafundisho ya Neno masaa 24/7 bila kikomo. Bonyeza hapa chini kuanzisha usikilizaji.',
        actionType: CopilotActionType.openRadio,
        actionData: {},
      );
    }

    // 7. PRAYER REQUEST INTENT
    if (query.contains('omba') ||
        query.contains('ombi') ||
        query.contains('dua') ||
        query.contains('shida') ||
        query.contains('ugonjwa') ||
        query.contains('huzuni') ||
        query.contains('uponyaji') ||
        query.contains('prayer') ||
        query.contains('pray') ||
        query.contains('healing') ||
        query.contains('sick') ||
        query.contains('help me') ||
        query.contains('trouble')) {
      return LocalFaithAiResult(
        reply:
            'Mungu wa Sayuni amesikia haja ya moyo wako. "Usiogope, kwa maana mimi ni pamoja nawe; usifadhaike, kwa maana mimi ni Mungu wako; nitakutia nguvu, naam, nitakusaidia." (Isaya 41:10)\n\nJe, ungependa kuwasilisha hitaji hili kwa Askofu Mercy James na jopo la wachungaji kwa njia salama na ya siri?',
        actionType: CopilotActionType.submitPrayer,
        actionData: {'requestSnippet': rawInput},
      );
    }

    // 8. PASTOR APPOINTMENT OR CONTACTS
    if (query.contains('mchungaji') ||
        query.contains('askofu') ||
        query.contains('kuonana') ||
        query.contains('ushauri') ||
        query.contains('namba') ||
        query.contains('simu')) {
      return const LocalFaithAiResult(
        reply:
            'MAWASILIANO YA VIONGOZI WA SAYUNI:\n'
            '• Askofu & Mchungaji Kiongozi Mercy James: 0744 126 927\n'
            '• Mchungaji Msaidizi Alex: 0787 190 026\n'
            '• Kiongozi wa Praise & Worship Jonathan: 0746 296 707\n'
            '• Mwalimu wa Kwaya Emmanuel Majaliwa: 0745 896 311\n\n'
            'Unaweza kuweka miadi ya kichungaji kwa kubonyeza kitufe hapa chini.',
        actionType: CopilotActionType.openAppointments,
        actionData: {},
      );
    }

    // 9. GIVING / SADAKA
    if (query.contains('sadaka') || query.contains('fungu') || query.contains('michango') || query.contains('ujenzi')) {
      return const LocalFaithAiResult(
        reply:
            'Ubarikiwe sana kwa moyo wako wa utoaji kwa kazi ya Mungu Sayuni. "Toeni, nanyi mtapewa; kipimo cha kujaa na kushindiliwa, na kusukwa-sukwa hata kumwagika." (Luka 6:38)',
        actionType: CopilotActionType.openGiving,
        actionData: {},
      );
    }

    // Default Spiritual Encouragement
    return const LocalFaithAiResult(
      reply:
          'Bwana Yesu asifiwe! Mimi ni Sayuni Copilot. Ninaweza kukusaidia:\n'
          '1. Kubadili theme (Giza au Mchana)\n'
          '2. Kutafuta na kuagiza vitabu vya Tenzi na Biblia\n'
          '3. Kufungua nyimbo za Tenzi na mistari ya Biblia\n'
          '4. Kuwasha Redio ya Kanisa\n'
          '5. Kuwasilisha maombi ya siri kwa Askofu na Wachungaji\n\n'
          'Ubarikiwe sana katika Sayuni!',
      actionType: CopilotActionType.none,
    );
  }
}
