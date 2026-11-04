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

  SermonMediaItem copyWith({
    String? id,
    String? title,
    String? preacher,
    String? scripture,
    String? date,
    String? duration,
    String? type,
    String? category,
    String? description,
    String? imageUrl,
    String? audioUrl,
    String? videoUrl,
    bool? isAdminUpload,
    String? readTime,
    String? keyVerse,
    List<String>? scriptureList,
    String? fullArticle,
    List<String>? takeaways,
    String? pastoralPrayer,
  }) {
    return SermonMediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      preacher: preacher ?? this.preacher,
      scripture: scripture ?? this.scripture,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      isAdminUpload: isAdminUpload ?? this.isAdminUpload,
      readTime: readTime ?? this.readTime,
      keyVerse: keyVerse ?? this.keyVerse,
      scriptureList: scriptureList ?? this.scriptureList,
      fullArticle: fullArticle ?? this.fullArticle,
      takeaways: takeaways ?? this.takeaways,
      pastoralPrayer: pastoralPrayer ?? this.pastoralPrayer,
    );
  }
}
