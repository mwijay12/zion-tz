import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sermon_note.dart';

class NotesService {
  static const String _storageKey = 'zion_sermon_notes';

  static final List<SermonNote> _initialNotes = [
    SermonNote(
      id: 'note-1',
      title: 'Kusimama Imara Katika Maombi na Tabia ya Uadilifu',
      preacher: 'Mchungaji Askofu Messi Mgala',
      scripture: 'Waefeso 6:10-18',
      content: 'Askofu alisisitiza umuhimu wa kujiandaa kiroho kila asubuhi kabla ya kuanza shughuli za siku. Silaha za Mungu zinalinda moyo na mawazo yetu dhidi ya mashaka.',
      date: DateTime.now().subtract(const Duration(days: 6)),
    ),
    SermonNote(
      id: 'note-2',
      title: 'Nguvu ya Neno la Mungu Ndani ya Familia na Ndoa',
      preacher: 'Ndg. James Robert',
      scripture: 'Kumbukumbu la Torati 6:4-9',
      content: 'Misingi ya hekima ya Mungu lazima ifundishwe kwa watoto nyumbani. Madhabahu ya familia (Family Altar) ndio ngome ya amani.',
      date: DateTime.now().subtract(const Duration(days: 13)),
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
    return list.map((item) => SermonNote.fromJson(item as Map<String, dynamic>)).toList();
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
