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

    // 1. THEME SWITCHING INTENTS
    if (query.contains('dark') ||
        query.contains('giza') ||
        query.contains('usiku') ||
        query.contains('nyeusi')) {
      return const LocalFaithAiResult(
        reply:
            'Amina! Nimekuwekea mandhari ya giza (Dark Mode) ili kukulinda macho na kukuwezesha kusoma Neno la Mungu kwa utulivu usiku. "Neno lako ni taa ya miguu yangu, na mwanga wa njia yangu." (Zaburi 119:105)',
        actionType: CopilotActionType.changeTheme,
        actionData: {'mode': 'dark'},
      );
    }

    if (query.contains('light') ||
        query.contains('mchana') ||
        query.contains('nyeupe') ||
        query.contains('mwanga')) {
      return const LocalFaithAiResult(
        reply:
            'Amina! Nimekuwekea mandhari angavu ya mchana (Light Mode). "Nuru yako na iangaze mbele ya watu, wapate kuyaona matendo yenu mema." (Mathayo 5:16)',
        actionType: CopilotActionType.changeTheme,
        actionData: {'mode': 'light'},
      );
    }

    if (query.contains('gold') ||
        query.contains('dhahabu') ||
        query.contains('liturujia') ||
        query.contains('kifalme')) {
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
            'Kitabu chetu cha Tenzi kina nyimbo 161 zenye maneno na sauti zinazofanya kazi 100% bila mtandao. Bonyeza hapa chini kuingia kwenye orodha kamili.',
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
        query.contains('uponyaji')) {
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
