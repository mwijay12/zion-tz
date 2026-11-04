import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sermon_note.dart';

class NotesService {
  static const String _storageKey = 'zion_sermon_notes';

  static final List<SermonNote> _initialNotes = [
    SermonNote(
      id: 'note-upendo',
      title: 'Upendo wa Kristo: Msingi na Amri Kuu',
      preacher: 'Mchungaji na Askofu Mercy James',
      scripture: 'Yoh 13:34-35 • 1 Kor 13:1-6 • 1 Yoh 4:7',
      content:
          '1. Amri Mpya: Yesu alituamuru kupendana kama Yeye alivyotupenda (Yohana 13:34-35, 15:12).\n'
          '2. Ujumbe wa Mwanzo: Huu ndio msingi wa wokovu wetu (1 Yohana 3:11, Marko 12:31).\n'
          '3. Sifa za Upendo: Huvumilia, hufadhili, hauhusudu na husitiri wingi wa dhambi (1 Petro 4:8, 1 Wakorintho 13:1-6).\n'
          '4. Asili ya Upendo: Mungu ni pendo, na yeyote anayependa amezaliwa na Mungu na anamjua Mungu (1 Yohana 4:7).',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    SermonNote(
      id: 'note-uchumi',
      title: 'Uchumi na Maendeleo ya Mkristo',
      preacher: 'Mchungaji Alex',
      scripture: 'Mathayo 19:27-29 • Mhubiri 10:10 • Malaki 3:7-12',
      content:
          '1. Swali la Petro: "Tumeacha vyote tutapata nini?" Yesu alithibitisha kwamba tutapata mara mia zaidi sasa hapa duniani na uzima wa milele mbinguni.\n'
          '2. Somo la Ayubu: Uvumilivu, kumcha Mungu na kurejeshewa mara mbili ya vyote vilivyopotea.\n'
          '3. Kibali cha Mungu: Uwepo wa Bwana huleta pumziko na ufanisi (Kutoka 33:14-19, 1 Samweli 2:7, Malaki 3:7-12, Mwanzo 30:25-32).\n'
          '4. Kipaji na Uzoefu: Chuma kikiwa butu imempasa kutumia nguvu zaidi bali hekima yafaa kuelekeza (Mhubiri 10:10).\n'
          '5. Maarifa: Kupenda kujifunza, kujiendeleza kitaluma na nidhamu ya uwekezaji na kazi za mikono.',
      date: DateTime.now().subtract(const Duration(days: 4)),
    ),
    SermonNote(
      id: 'note-bidii',
      title: 'Bidii Kazini: Mkristo Kusimama Mbele ya Wafalme',
      preacher: 'Mchungaji na Askofu Mercy James',
      scripture: 'Mithali 22:26, 29',
      content:
          '1. Kusimama Mbele ya Wafalme: Mtu mwenye bidii katika kazi yake atasimama mbele ya wafalme na viongozi wakuu (Mithali 22:29).\n'
          '2. Kuepuka Mitego ya Madeni: Usiwe mmoja wa wawekao rehani mikono yao ovyo (Mithali 22:26).\n'
          '3. Uadilifu na Nidhamu: Fanya kazi kwa bidii kama unamfanyia Bwana, si kwa macho ya wanadamu.',
      date: DateTime.now().subtract(const Duration(days: 7)),
    ),
    SermonNote(
      id: 'note-utasitasita',
      title: 'Utasitasita Mpaka Lini? Msimamo Imara wa Mkristo',
      preacher: 'Mwl. Emmanuel Majaliwa (Sunday School)',
      scripture: '1 Wafalme 18:21 • Yoshua 24:15 • Matendo 7:58',
      content:
          '1. Swali la Eliya Mlimani Karmeli: "Mtasita-sita katikati ya mawazo mawili hata lini? Bwana akiwa ndiye Mungu mfuateni" (1 Wafalme 18:21).\n'
          '2. Uamuzi wa Yoshua: "Chagueni hivi leo mtakayemtumikia... lakini mimi na nyumba yangu tutamtumikia Bwana" (Yoshua 24:15).\n'
          '3. Ushuhuda wa Stefano: Kusimama imara katika imani bila kujali vitisho vya wanadamu (Matendo 7:58).',
      date: DateTime.now().subtract(const Duration(days: 9)),
    ),
    SermonNote(
      id: 'note-mwombaji-wakili',
      title: 'Nafasi ya Mwombaji Kama Wakili wa Siri za Mungu',
      preacher: 'Mchungaji na Askofu Mercy James',
      scripture: 'Ezekieli 22:30 • 1 Wakorintho 4:1-2',
      content:
          '1. Maana ya Wakili: Msimamizi aliyepewa dhamana na mamlaka ya kulinda na kusimamia siri na mali ya Bwana wake (1 Wakorintho 4:1-2).\n'
          '2. Kusimama kwenye Pengo: Mungu anatafuta mtu wa kusimama mahali palipobomoka kwa ajili ya nchi na kanisa (Ezekieli 22:30).\n'
          '3. Mamlaka ya Mwombaji: Mwombaji si mtu duni bali ni balozi wa kiroho anayeombea kanisa, viongozi, na taifa kwa uaminifu.',
      date: DateTime.now().subtract(const Duration(days: 12)),
    ),
    SermonNote(
      id: 'note-ukombozi',
      title: 'Ukombozi Wetu Upo kwa Mungu Pekee',
      preacher: 'Mchungaji na Askofu Mercy James',
      scripture: 'Zaburi 3:8 • Kutoka 14:13-14 • Warumi 8:31',
      content:
          '1. Chanzo cha Ukombozi: Wokovu na ukombozi unatoka kwa Bwana pekee (Zaburi 3:8).\n'
          '2. Mungu Atatupigania: "Bwana atawapigania ninyi, nanyi mtanyamaza kimya" (Kutoka 14:13-14).\n'
          '3. Ushindi wa Kudumu: Ikiwa Mungu yupo upande wetu, hakuna silaha itakayofanikiwa dhidi yetu (Warumi 8:31-39).',
      date: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  Future<List<SermonNote>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) {
      await saveNotes(_initialNotes);
      return _initialNotes;
    }
    final List<dynamic> list = json.decode(jsonString);
    final userNotes = list
        .map((item) => SermonNote.fromJson(item as Map<String, dynamic>))
        .toList();

    // Merge foundational diary teachings if not present
    bool changed = false;
    for (final initial in _initialNotes) {
      if (!userNotes.any((n) => n.id == initial.id)) {
        userNotes.add(initial);
        changed = true;
      }
    }
    if (changed) {
      await saveNotes(userNotes);
    }
    return userNotes;
  }

  Future<void> saveNotes(List<SermonNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(notes.map((n) => n.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<void> addNote(SermonNote note) async {
    final notes = await getNotes();
    notes.insert(0, note);
    await saveNotes(notes);
  }

  Future<void> updateNote(SermonNote note) async {
    final notes = await getNotes();
    final idx = notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      notes[idx] = note;
    } else {
      notes.insert(0, note);
    }
    await saveNotes(notes);
  }

  Future<void> deleteNote(String id) async {
    final notes = await getNotes();
    notes.removeWhere((n) => n.id == id);
    await saveNotes(notes);
  }
}
