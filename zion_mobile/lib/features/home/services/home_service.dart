import '../models/home_content.dart';
import '../../../core/services/offline_spiritual_service.dart';

class HomeService {
  static DevotionalContent get todayDevotional {
    final manna = OfflineSpiritualService().getTodaySpiritualWord();
    return DevotionalContent(
      title: manna.title,
      reference: manna.scriptureReference,
      scriptureText: manna.scriptureText,
      reflection: manna.reflection,
      prayer: manna.prayer,
      category: manna.themeCategory,
      date: DateTime.now(),
      recommendedHymnNumber: manna.recommendedHymnNumber,
      recommendedHymnTitle: manna.recommendedHymnTitle,
      isOfflineReady: true,
    );
  }

  static const List<ChurchAnnouncementItem> announcements = [];

  static const List<SermonAudioItem> recentSermons = [
    SermonAudioItem(
      id: 'sermon-1',
      title: 'Kusimama Imara Katika Maombi na Tabia ya Uadilifu',
      preacher: 'Mchungaji Askofu Messi Mgala',
      duration: '48:12',
      date: '30 Ago 2026',
      scripture: 'Waefeso 6:10-18',
    ),
    SermonAudioItem(
      id: 'sermon-2',
      title: 'Nguvu ya Neno la Mungu Ndani ya Familia na Ndoa',
      preacher: 'Ndg. James Robert',
      duration: '42:35',
      date: '23 Ago 2026',
      scripture: 'Kumbukumbu la Torati 6:4-9',
    ),
    SermonAudioItem(
      id: 'sermon-3',
      title: 'Kuvunja Vikwazo vya Kiroho Kupitia Sadaka na Maombi',
      preacher: 'Mchungaji Askofu Messi Mgala',
      duration: '54:20',
      date: '16 Ago 2026',
      scripture: 'Wafilipi 4:6-7',
    ),
  ];
}
