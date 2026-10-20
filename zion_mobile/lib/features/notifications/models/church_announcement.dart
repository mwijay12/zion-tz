class ChurchAnnouncement {
  final String id;
  final String title;
  final String category; // 'Ibada' | 'Ujenzi' | 'Semina' | 'Mkesha' | 'Jumuiya' | 'Sadaka' | 'Taarifa Kuu'
  final String type; // 'normal' | 'urgent' | 'bereavement'
  final String branch; // 'Zote' | 'Mbagala Kwa Matope' | 'Morogoro' | 'Bukoba' | ...
  final String date;
  final String time;
  final String location;
  final String summary;
  final String fullDetails;
  final String preacherOrLeader;
  final bool isHighPriority;
  final String targetAudience; // 'all' | 'leaders' | 'elders' | 'choir'
  bool isRead;

  ChurchAnnouncement({
    required this.id,
    required this.title,
    required this.category,
    this.type = 'normal',
    this.branch = 'Zote',
    required this.date,
    required this.time,
    required this.location,
    required this.summary,
    required this.fullDetails,
    required this.preacherOrLeader,
    this.isHighPriority = false,
    this.targetAudience = 'all',
    this.isRead = false,
  });

  bool get isForLeaders => targetAudience == 'leaders' || targetAudience == 'elders';
  bool get isPublic => targetAudience == 'all';
  bool get isBereavement => type == 'bereavement';
  bool get isUrgent => type == 'urgent' || isHighPriority;
  bool get isNormal => type == 'normal' && !isHighPriority;

  String get audienceLabel {
    switch (targetAudience) {
      case 'leaders':
        return '🔒 Viongozi Pekee';
      case 'elders':
        return '🔒 Wazee wa Kanisa';
      case 'choir':
        return '🎵 Wanakwaya';
      case 'all':
      default:
        return '📢 Waumini Wote';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'type': type,
    'branch': branch,
    'date': date,
    'time': time,
    'location': location,
    'summary': summary,
    'fullDetails': fullDetails,
    'preacherOrLeader': preacherOrLeader,
    'isHighPriority': isHighPriority,
    'targetAudience': targetAudience,
    'isRead': isRead,
  };

  factory ChurchAnnouncement.fromJson(Map<String, dynamic> json) => ChurchAnnouncement(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    category: json['category']?.toString() ?? 'Taarifa Kuu',
    type: json['type']?.toString() ?? ((json['isUrgent'] == true || json['isHighPriority'] == true) ? 'urgent' : 'normal'),
    branch: json['branch']?.toString() ?? 'Zote',
    date: json['date']?.toString() ?? 'Leo',
    time: json['time']?.toString() ?? 'Saa za Ibada',
    location: json['location']?.toString() ?? 'Hekalu Kuu la Sayuni',
    summary: json['summary']?.toString() ?? (json['body']?.toString() ?? (json['content']?.toString() ?? '')),
    fullDetails: json['fullDetails']?.toString() ?? (json['body']?.toString() ?? (json['content']?.toString() ?? '')),
    preacherOrLeader: json['preacherOrLeader']?.toString() ?? (json['authorRole']?.toString() ?? 'Ofisi ya Katibu Mkuu wa Kanisa'),
    isHighPriority: json['isUrgent'] == true || json['isHighPriority'] == true || json['type'] == 'urgent',
    targetAudience: json['targetAudience']?.toString() ?? (json['audience']?.toString() ?? 'all'),
    isRead: json['isRead'] == true,
  );
}
