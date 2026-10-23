class HomeCell {
  final String id;
  final String name;
  final String area;
  final String leader;
  final String phone;
  final String meetingDay;
  final String meetingTime;
  final int membersCount;
  final String imagePath;

  const HomeCell({
    required this.id,
    required this.name,
    required this.area,
    required this.leader,
    required this.phone,
    required this.meetingDay,
    required this.meetingTime,
    required this.membersCount,
    this.imagePath = 'assets/images/jumuiya_fellowship_1788577443594.jpg',
  });
}

class ChurchMinistryGroup {
  final String id;
  final String name;
  final String category;
  final String leader;
  final String leaderTitle;
  final String phone;
  final String meetingSchedule;
  final String description;
  final String imagePath;
  final int membersCount;
  final List<String> activities;

  const ChurchMinistryGroup({
    required this.id,
    required this.name,
    required this.category,
    required this.leader,
    required this.leaderTitle,
    required this.phone,
    required this.meetingSchedule,
    required this.description,
    required this.imagePath,
    required this.membersCount,
    required this.activities,
  });
}

class PrayerRequestItem {
  final String id;
  final String senderName;
  final String phone;
  final String category;
  final String details;
  final bool isConfidential;
  final DateTime date;

  PrayerRequestItem({
    required this.id,
    required this.senderName,
    required this.phone,
    required this.category,
    required this.details,
    required this.isConfidential,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderName': senderName,
        'phone': phone,
        'category': category,
        'details': details,
        'isConfidential': isConfidential,
        'date': date.toIso8601String(),
      };

  factory PrayerRequestItem.fromJson(Map<String, dynamic> json) =>
      PrayerRequestItem(
        id: json['id'] as String,
        senderName: json['senderName'] as String,
        phone: json['phone'] as String,
        category: json['category'] as String,
        details: json['details'] as String,
        isConfidential: json['isConfidential'] as bool? ?? false,
        date: DateTime.parse(json['date'] as String),
      );
}
