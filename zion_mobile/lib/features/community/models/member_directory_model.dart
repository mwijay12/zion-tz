class MemberSkillProfile {
  final String id;
  final String fullName;
  final String profession; // e.g., 'Mkulima wa Mboga & Matunda', 'Mhandisi wa Software & Apps'
  final String category; // 'Kilimo', 'Tehama & Apps', 'Ufundi & Ujenzi', 'Biashara', 'Afya', 'Elimu', 'Mavazi'
  final String description; // Detailed description of what they do & services they offer
  final String phone;
  final String location; // e.g., 'Mbagala Charambe'
  final String jumuiya; // e.g., 'Jumuiya ya Bethlehemu'
  final String experienceYears;
  final bool isVerifiedMember;
  final String avatarEmoji;

  const MemberSkillProfile({
    required this.id,
    required this.fullName,
    required this.profession,
    required this.category,
    required this.description,
    required this.phone,
    required this.location,
    required this.jumuiya,
    required this.experienceYears,
    this.isVerifiedMember = true,
    this.avatarEmoji = '👤',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'profession': profession,
    'category': category,
    'description': description,
    'phone': phone,
    'location': location,
    'jumuiya': jumuiya,
    'experienceYears': experienceYears,
    'isVerifiedMember': isVerifiedMember,
    'avatarEmoji': avatarEmoji,
  };

  factory MemberSkillProfile.fromJson(Map<String, dynamic> json) => MemberSkillProfile(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    profession: json['profession'] as String,
    category: json['category'] as String,
    description: json['description'] as String,
    phone: json['phone'] as String,
    location: json['location'] as String,
    jumuiya: json['jumuiya'] as String,
    experienceYears: json['experienceYears'] as String,
    isVerifiedMember: json['isVerifiedMember'] as bool? ?? true,
    avatarEmoji: json['avatarEmoji'] as String? ?? '👤',
  );
}
