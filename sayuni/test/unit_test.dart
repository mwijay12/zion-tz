import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sayuni/features/giving/models/giving_channel.dart';
import 'package:sayuni/features/giving/services/giving_service.dart';
import 'package:sayuni/features/notes/models/sermon_note.dart';
import 'package:sayuni/features/notes/services/notes_service.dart';
import 'package:sayuni/features/jumuiya/services/jumuiya_service.dart';
import 'package:sayuni/core/utils/formatters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Church Formatters & Calculations', () {
    test('Format TSh currency correctly', () {
      expect(AppFormatters.formatTsh(50000), 'TSh 50,000');
      expect(AppFormatters.formatTsh(120000000), 'TSh 120,000,000');
    });

    test('Building project percentage calculation', () {
      const target = GivingService.buildingTarget;
      const raised = GivingService.buildingRaised;
      final percent = (raised / target * 100).toInt();
      expect(percent, 57);
    });
  });

  group('Giving Channels & Records', () {
    test('All 4 Tanzania giving channels configured', () {
      final channels = GivingService.channels;
      expect(channels.length, 4);

      final mpesa = channels.firstWhere((c) => c.id == 'mpesa');
      expect(mpesa.payNumber, '5524101');

      final tigo = channels.firstWhere((c) => c.id == 'tigopesa');
      expect(tigo.payNumber, '8919293');

      final crdb = channels.firstWhere((c) => c.id == 'crdb');
      expect(crdb.payNumber, '0150829103900');
    });

    test('Giving record serialization', () {
      final record = GivingRecord(
        id: 'rec-1',
        category: 'Zaka (Fungu la Kumi)',
        amount: 150000,
        paymentChannel: 'M-Pesa (5524101)',
        referenceNumber: '8Q29X1',
        date: DateTime(2026, 9, 6),
      );

      final json = record.toJson();
      final fromJson = GivingRecord.fromJson(json);

      expect(fromJson.id, 'rec-1');
      expect(fromJson.amount, 150000);
      expect(fromJson.category, 'Zaka (Fungu la Kumi)');
    });
  });

  group('Sermon Notes Persistence', () {
    test('Add and retrieve sermon notes from local storage', () async {
      SharedPreferences.setMockInitialValues({});
      final service = NotesService();

      final initial = await service.getNotes();
      expect(initial.isNotEmpty, true);

      final newNote = SermonNote(
        id: 'note-test',
        title: 'Somo la Uvumilivu',
        preacher: 'Askofu Messi Mgala',
        scripture: 'Yakobo 1:2-4',
        content: 'Kuhesabu majaribu kuwa furaha.',
        date: DateTime.now(),
      );

      await service.addNote(newNote);
      final updated = await service.getNotes();

      expect(updated.first.title, 'Somo la Uvumilivu');
      expect(updated.first.preacher, 'Askofu Messi Mgala');
    });
  });

  group('Home Cells (Jumuiya)', () {
    test('All 5 Mbagala home cells loaded', () {
      final cells = JumuiyaService.homeCells;
      expect(cells.length, 5);
      expect(cells.any((c) => c.name.contains('Bethlehemu')), true);
      expect(cells.any((c) => c.name.contains('Galilaya')), true);
    });
  });
}
