import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SpiritualGuidanceResult {
  final String emotionOrTopic;
  final String scriptureReference;
  final String scriptureText;
  final String pastoralWord;
  final String prayer;
  final int recommendedHymnNumber;
  final String recommendedHymnTitle;
  final bool isFromOnlineService;

  const SpiritualGuidanceResult({
    required this.emotionOrTopic,
    required this.scriptureReference,
    required this.scriptureText,
    required this.pastoralWord,
    required this.prayer,
    required this.recommendedHymnNumber,
    required this.recommendedHymnTitle,
    this.isFromOnlineService = false,
  });
}

class SpiritualWisdomService {
  static final SpiritualWisdomService _instance = SpiritualWisdomService._internal();
  factory SpiritualWisdomService() => _instance;
  SpiritualWisdomService._internal();

  String get _apiKey {
    const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
    return fromEnv;
  }

  // Pre-curated, theologically grounded offline spiritual guidance for instant fallback & 100% offline access
  static const Map<String, SpiritualGuidanceResult> _curatedGuidance = {
    'huzuni': SpiritualGuidanceResult(
      emotionOrTopic: 'Huzuni & Kuumia Moyoni',
      scriptureReference: 'Zaburi 34:18',
      scriptureText: 'Bwana yu karibu nao waliovunjika moyo, Na huwaokoa waliopondeka roho.',
      pastoralWord: 'Mpendwa katika Bwana, huzuni unayopitia haitakuwa ya kudumu. Mungu wa Sayuni amesikia machozi yako ya sirini na yu tayari kugeuza kilio chako kuwa kicheko na ushuhuda wa utukufu wake.',
      prayer: 'Ee Bwana Mungu wangu, ninakuja miguuni pako nikiwa na maumivu haya. Ponya majeraha ya moyo wangu na unijaze na furaha ya Roho wako Mtakatifu inayopita akili zote. Katika jina la Yesu, Amina.',
      recommendedHymnNumber: 88,
      recommendedHymnTitle: 'Usinipite Mwokozi',
    ),
    'wasiwasi': SpiritualGuidanceResult(
      emotionOrTopic: 'Wasiwasi wa Maisha, Ada & Kodi',
      scriptureReference: 'Wafilipi 4:6-7',
      scriptureText: 'Msijisumbue kwa neno lo lote; bali katika kila neno kwa kusali na kuomba, pamoja na kushukuru, haja zenu na zijulikane na Mungu. Na amani ya Mungu, ipitayo akili zote, itawahifadhi mioyo yenu na nia zenu katika Kristo Yesu.',
      pastoralWord: 'Hata pale ambapo milango ya kifedha inaonekana kufungika, Mungu anabaki kuwa Yehova Jireh (Mungu Anayejaza). Weka akili na mipango yako mikononi mwake leo; hawezi kumwaibisha yeyote anayemwamini.',
      prayer: 'Baba wa Mbinguni, ninatua mizigo yote ya ada, kodi na gharama za familia miguuni pako. Ninaamini kwamba utajiri wako katika utukufu ndani ya Kristo unatosha kwa mahitaji yangu yote ya leo. Amina.',
      recommendedHymnNumber: 47,
      recommendedHymnTitle: 'Cha Kutumaini Sina',
    ),
    'uponyaji': SpiritualGuidanceResult(
      emotionOrTopic: 'Haja ya Uponyaji wa Magonjwa',
      scriptureReference: 'Isaya 53:5',
      scriptureText: 'Bali alijeruhiwa kwa makosa yetu, Alichubuliwa kwa maovu yetu; Adhabu ya amani yetu ilikuwa juu yake, Na kwa kupigwa kwake sisi tumepona.',
      pastoralWord: 'Yesu Kristo ndiye Mganga Mkuu wa miili na roho zetu. Damu yake iliyomwagika pale Kalvari ilibeba ugonjwa wowote na udhaifu wako. Simama kwa ujasiri ukiamini kazi iliyomalizika msalabani.',
      prayer: 'Bwana Yesu Mponyaji, nyoosha mkono wako mtakatifu juu ya mwili wangu na afya yangu sasa. Kila ugonjwa, maumivu au hofu viondoke kwa mamlaka ya jina lako. Ninapokea uzima tele, Amina!',
      recommendedHymnNumber: 130,
      recommendedHymnTitle: 'Salama Rohoni Mwangu',
    ),
    'kazi': SpiritualGuidanceResult(
      emotionOrTopic: 'Kutafuta Kazi, Mtaji au Uamuzi wa Kibiashara',
      scriptureReference: 'Mithali 3:5-6',
      scriptureText: 'Mtumaini Bwana kwa moyo wako wote, wala usizitegemee akili zako mwenyewe; Katika njia zako zote mkiri yeye, naye atayanyosha mapito yako.',
      pastoralWord: 'Kazi na biashara zako ziko chini ya agano la Sayuni. Bwana anapoanza kunyosha mapito yako, milango ya wateja, waajiri na wasaidizi wa hatima inafunguka bila nguvu za kibinadamu.',
      prayer: 'Ee Mungu Mwenye Hekima, ninakabidhi kazi yangu, biashara yangu na mipango yangu ya fedha kwako. Nipe kibali mbele ya watu na uongozi sahihi wa Roho Mtakatifu katika kila hatua. Amina.',
      recommendedHymnNumber: 24,
      recommendedHymnTitle: 'Mwamba Wenye Imara',
    ),
    'vita': SpiritualGuidanceResult(
      emotionOrTopic: 'Vita vya Kiroho & Ulinzi Dhidi ya Adui',
      scriptureReference: 'Isaya 54:17',
      scriptureText: 'Bila shaka silaha yoyote itakayofanyika juu yako haitafanikiwa; na kila ulimi utakaoinuka juu yako katika hukumu utauhukumu kuwa mkosa. Huu ndio urithi wa watumishi wa Bwana.',
      pastoralWord: 'Wewe ni mshindi ndani ya Kristo. Hakuna mtego wa giza, husuda, au hila za ibilisi zinazoweza kutikisa misingi ya mtoto wa Sayuni aliye chini ya mbawa za Aliye Juu.',
      prayer: 'Mungu wa Majeshi, wewe ndiwe ngao yangu na ngome yangu thabiti. Ninavunja kila nguvu ya adui dhidi ya familia yangu na maisha yangu kwa jina la Yesu Kristo. Bwana ndiye ngao yangu milele. Amina!',
      recommendedHymnNumber: 114,
      recommendedHymnTitle: 'Niongoze Yehova Mkubwa',
    ),
    'amani': SpiritualGuidanceResult(
      emotionOrTopic: 'Amani & Utulivu wa Nafsi',
      scriptureReference: 'Yohana 14:27',
      scriptureText: 'Amani nawaachieni; amani yangu nawapa; niwapavyo mimi sivyo kama ulimwengu utoavyo. Msifadhaike mioyoni mwenu, wala msiwe na woga.',
      pastoralWord: 'Amani ya Kristo si kutokuwepo kwa dhoruba, bali ni kuwa na Yesu ndani ya mashua yako wakati dhoruba inavuma. Tulia, mtazame Kristo, na uruhusu pumziko la Sayuni litawale mawazo yako.',
      prayer: 'Yesu Mwema, asante kwa amani yako isiyotikisika. Ninakataa hofu na mashaka leo. Tawala mawazo yangu na ulinde moyo wangu katika Kristo Yesu. Amina.',
      recommendedHymnNumber: 62,
      recommendedHymnTitle: 'Karibu na Wewe Mungu Wangu',
    ),
    'shukrani': SpiritualGuidanceResult(
      emotionOrTopic: 'Shukrani & Sifa kwa Matendo Makuu',
      scriptureReference: 'Zaburi 103:1-2',
      scriptureText: 'Ee nafsi yangu, umhimidi Bwana. Na vyote vilivyo ndani yangu vilihimidie jina lake takatifu. Ee nafsi yangu, umhimidi Bwana, Wala usizisahau fadhili zake zote.',
      pastoralWord: 'Moyo wa shukrani ni ufunguo unaofungua milango mikubwa zaidi ya baraka. Unapomtukuza Mungu kwa yale aliyoyafanya jana, unamwalika kutenda mambo makuu zaidi leo na kesho.',
      prayer: 'Baba Mtakatifu, nakushukuru kwa pumzi ya uhai, ulinzi wako kwangu na kanisa lako la Zion Jerusalem. Pokea sifa zote, heshima na adhama leo na hata milele. Amina!',
      recommendedHymnNumber: 1,
      recommendedHymnTitle: 'Yesu Kwetu ni Rafiki',
    ),
  };

  /// Main method to request spiritual guidance.
  /// Works completely behind the scenes ("chini kwa chini") with zero mention of AI,
  /// strictly biblical responses, and instantaneous deterministic offline fallback.
  Future<SpiritualGuidanceResult> getGuidanceForNeed(String needOrEmotion) async {
    final cleanInput = needOrEmotion.trim();
    if (cleanInput.isEmpty) {
      return _curatedGuidance['amani']!;
    }

    // Try online intelligent generation via Gemini 2.5 Flash
    if (_apiKey.isNotEmpty) {
      try {
        final onlineResult = await _fetchFromGemini(cleanInput);
        if (onlineResult != null) {
          return onlineResult;
        }
      } catch (e) {
        if (kDebugMode) {
          print('SpiritualWisdomService online error (handled gracefully): $e');
        }
      }
    }

    // Deterministic fallback matching based on keywords
    return _matchCuratedFallback(cleanInput);
  }

  Future<SpiritualGuidanceResult?> _fetchFromGemini(String input) async {
    final endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey',
    );

    final prompt = '''
Wewe ni Mshauri wa Kiroho na Mtumishi wa Kanisa la Sayuni Jerusalem Church (Mbagala Kwa Matope, Dar es Salaam; linaloongozwa na Askofu Messi Mgala).
Muumini ameleta haja/hali ifuatayo ya kiroho: "$input".

Toa mwongozo wa kichungaji wenye hekima ya kibiblia, faraja na nguvu ya ushindi.
MASHARTI MAKUBWA YA KIKANISA:
1. Usitumie kamwe maneno ya kiteknolojia kama "AI", "akili mnemba", "robot", "mfumo", "modeli", "chatbot" au lugha ya kisayansi.
2. Tumia lugha safi ya Kiswahili cha kikanisa na Maandiko Matakatifu ya Biblia (SUV).
3. Toa jibu katika umbizo safi la JSON pekee, bila markdown wala maelezo ya nje:
{
  "scriptureReference": "Kitabu Mlango:Aya (mf. Wafilipi 4:6-7 au Isaya 41:10)",
  "scriptureText": "Maneno kamili ya aya hiyo ya Biblia",
  "pastoralWord": "Ujumbe mfupi wa kichungaji wa aya 2 wenye upendo na faraja",
  "prayer": "Sala fupi ya imani ya kuomba sasa (kuishia na Amina!)",
  "hymnNumber": 130,
  "hymnTitle": "Jina la Wimbo wa Tenzi za Rohoni unaoendana na somo hilo"
}
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.4,
      }
    });

    final res = await http.post(
      endpoint,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final candidates = json['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text'] as String;
          final parsed = jsonDecode(text.trim());

          return SpiritualGuidanceResult(
            emotionOrTopic: input,
            scriptureReference: parsed['scriptureReference'] ?? 'Zaburi 132:13-14',
            scriptureText: parsed['scriptureText'] ?? 'Kwa kuwa Bwana ameichagua Sayuni; Ameitamani akae ndani yake.',
            pastoralWord: parsed['pastoralWord'] ?? 'Mungu wa Sayuni yu pamoja nawe daima.',
            prayer: parsed['prayer'] ?? 'Bwana Yesu nisaidie na unibariki leo. Amina!',
            recommendedHymnNumber: parsed['hymnNumber'] is int ? parsed['hymnNumber'] : 130,
            recommendedHymnTitle: parsed['hymnTitle'] ?? 'Salama Rohoni Mwangu',
            isFromOnlineService: true,
          );
        }
      }
    }
    return null;
  }

  SpiritualGuidanceResult _matchCuratedFallback(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('huzun') || lower.contains('kulia') || lower.contains('maumiv') || lower.contains('fiwa') || lower.contains('kuumiz')) {
      return _curatedGuidance['huzuni']!;
    }
    if (lower.contains('fedha') || lower.contains('kodi') || lower.contains('ada') || lower.contains('deni') || lower.contains('wasiwas') || lower.contains('ugumu')) {
      return _curatedGuidance['wasiwasi']!;
    }
    if (lower.contains('ugonjw') || lower.contains('homa') || lower.contains('dawa') || lower.contains('hospital') || lower.contains('ponya') || lower.contains('afya')) {
      return _curatedGuidance['uponyaji']!;
    }
    if (lower.contains('kazi') || lower.contains('ajira') || lower.contains('biashara') || lower.contains('mtaji') || lower.contains('ofisi') || lower.contains('mradi')) {
      return _curatedGuidance['kazi']!;
    }
    if (lower.contains('vita') || lower.contains('adui') || lower.contains('uchawi') || lower.contains('mashambuliz') || lower.contains('mapepo') || lower.contains('ndoto')) {
      return _curatedGuidance['vita']!;
    }
    if (lower.contains('shukran') || lower.contains('asante') || lower.contains('furaha') || lower.contains('ushuhuda') || lower.contains('sifa') || lower.contains('pongez')) {
      return _curatedGuidance['shukrani']!;
    }

    // Default peace
    return _curatedGuidance['amani']!;
  }
}
