class SermonMediaItem {
  final String id;
  final String title;
  final String preacher;
  final String scripture;
  final String date;
  final String duration;
  final String type; // 'text' | 'audio' | 'video'
  final String category; // 'Mafundisho' | 'Mahubiri' | 'Sunday School' | 'Kwaya' | 'Podcasts' | 'Maombi' | 'Maendeleo'
  final String description;
  final String imageUrl;
  final String audioUrl;
  final String videoUrl;
  final bool isAdminUpload;

  // Rich blog post properties:
  final String readTime; // e.g. 'Dakika 4 kusoma'
  final String keyVerse; // Memory verse citation and text
  final List<String> scriptureList; // All cited scriptures for badges
  final String fullArticle; // Rich blog post content in sections
  final List<String> takeaways; // Bulleted practical application points
  final String pastoralPrayer; // Prayer of blessing

  const SermonMediaItem({
    required this.id,
    required this.title,
    required this.preacher,
    required this.scripture,
    required this.date,
    required this.duration,
    required this.type,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.audioUrl = '',
    this.videoUrl = '',
    this.isAdminUpload = false,
    this.readTime = 'Dakika 4 kusoma',
    this.keyVerse = '',
    this.scriptureList = const [],
    this.fullArticle = '',
    this.takeaways = const [],
    this.pastoralPrayer = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'preacher': preacher,
        'scripture': scripture,
        'date': date,
        'duration': duration,
        'type': type,
        'category': category,
        'description': description,
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'videoUrl': videoUrl,
        'isAdminUpload': isAdminUpload,
        'readTime': readTime,
        'keyVerse': keyVerse,
        'scriptureList': scriptureList,
        'fullArticle': fullArticle,
        'takeaways': takeaways,
        'pastoralPrayer': pastoralPrayer,
      };

  factory SermonMediaItem.fromJson(Map<String, dynamic> json) =>
      SermonMediaItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        preacher: json['preacher']?.toString() ?? '',
        scripture: json['scripture']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        duration: json['duration']?.toString() ?? '45 min',
        type: json['type']?.toString() ?? 'text',
        category: json['category']?.toString() ?? 'Mafundisho',
        description: json['description']?.toString() ?? '',
        imageUrl:
            json['imageUrl']?.toString() ?? 'assets/images/church_front.jpg',
        audioUrl: json['audioUrl']?.toString() ?? '',
        videoUrl: json['videoUrl']?.toString() ?? '',
        isAdminUpload: json['isAdminUpload'] == true,
        readTime: json['readTime']?.toString() ?? 'Dakika 4 kusoma',
        keyVerse: json['keyVerse']?.toString() ?? '',
        scriptureList: json['scriptureList'] != null
            ? List<String>.from(json['scriptureList'])
            : const [],
        fullArticle: json['fullArticle']?.toString() ?? '',
        takeaways: json['takeaways'] != null
            ? List<String>.from(json['takeaways'])
            : const [],
        pastoralPrayer: json['pastoralPrayer']?.toString() ?? '',
      );
}
