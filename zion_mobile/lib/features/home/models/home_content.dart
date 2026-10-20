class DevotionalContent {
  final String title;
  final String reference;
  final String scriptureText;
  final String reflection;
  final String prayer;
  final String category;
  final DateTime date;
  final int? recommendedHymnNumber;
  final String? recommendedHymnTitle;
  final bool isOfflineReady;

  const DevotionalContent({
    required this.title,
    required this.reference,
    required this.scriptureText,
    required this.reflection,
    required this.prayer,
    required this.category,
    required this.date,
    this.recommendedHymnNumber,
    this.recommendedHymnTitle,
    this.isOfflineReady = true,
  });
}

class ChurchAnnouncementItem {
  final String id;
  final String title;
  final String category; // 'Ibada', 'Ujenzi', 'Vikundi', 'Dharura'
  final String details;
  final String dateText;
  final bool isUrgent;

  const ChurchAnnouncementItem({
    required this.id,
    required this.title,
    required this.category,
    required this.details,
    required this.dateText,
    this.isUrgent = false,
  });
}

class SermonAudioItem {
  final String id;
  final String title;
  final String preacher;
  final String duration;
  final String date;
  final String scripture;

  const SermonAudioItem({
    required this.id,
    required this.title,
    required this.preacher,
    required this.duration,
    required this.date,
    required this.scripture,
  });
}
