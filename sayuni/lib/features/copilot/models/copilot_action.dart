enum CopilotActionType {
  none,
  changeTheme,
  orderProduct,
  searchProduct,
  openHymn,
  openScripture,
  submitPrayer,
  openRadio,
  openAppointments,
  openGiving,
}

class CopilotProductItem {
  final String id;
  final String title;
  final String priceFormatted;
  final int priceTzs;
  final String description;
  final String category;
  final String? coverAsset;
  final bool isAvailable;

  const CopilotProductItem({
    required this.id,
    required this.title,
    required this.priceFormatted,
    required this.priceTzs,
    required this.description,
    required this.category,
    this.coverAsset,
    this.isAvailable = true,
  });

  static const List<CopilotProductItem> churchCatalog = [
    CopilotProductItem(
      id: 'tenzi_hardcover',
      title: 'Tenzi za Rohoni (Toleo Rasmi la Sayuni)',
      priceFormatted: 'TZS 10,000',
      priceTzs: 10000,
      description: 'Kitabu kamili cha Tenzi zenye nyimbo zote 161 za kumsifu Mungu, maneno yote na maelekezo ya sauti.',
      category: 'Vitabu vya Nyimbo',
      coverAsset: 'assets/images/church_front.jpg',
    ),
    CopilotProductItem(
      id: 'biblia_suv',
      title: 'Biblia Takatifu (SUV - Kiswahili)',
      priceFormatted: 'TZS 25,000',
      priceTzs: 25000,
      description: 'Agano la Kale na Jipya toleo la Kiswahili cha Umoja (Swahili Union Version), maandishi ya wastani yenye fahirisi.',
      category: 'Biblia',
      coverAsset: 'assets/images/church_front.jpg',
    ),
    CopilotProductItem(
      id: 'ushindi_askofu',
      title: 'Ushindi Kupitia Neno & Maombi',
      priceFormatted: 'TZS 15,000',
      priceTzs: 15000,
      description: 'Kitabu cha kiroho na miongozo ya vita vya kiroho kilichoandikwa na Askofu Mercy James.',
      category: 'Mafundisho ya Kiroho',
      coverAsset: 'assets/images/church_front.jpg',
    ),
    CopilotProductItem(
      id: 'mwongozo_sunday_school',
      title: 'Mwongozo wa Masomo ya Sunday School na Watoto',
      priceFormatted: 'TZS 8,000',
      priceTzs: 8000,
      description: 'Mtaala na hadithi za watoto wa miaka 3-12 kwa ajili ya walimu wa Sunday School na wazazi.',
      category: 'Sunday School',
      coverAsset: 'assets/images/church_front.jpg',
    ),
    CopilotProductItem(
      id: 'kwaya_sayuni_album',
      title: 'Kitabu cha Nyimbo na Masifu ya Kwaya ya Sayuni',
      priceFormatted: 'TZS 12,000',
      priceTzs: 12000,
      description: 'Mashairi na noti za nyimbo za uamsho za Kwaya Kuu ya Sayuni Jerusalem.',
      category: 'Kwaya',
      coverAsset: 'assets/images/church_front.jpg',
    ),
  ];
}

class CopilotMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final CopilotActionType actionType;
  final Map<String, dynamic> actionData;
  final bool isOffline;
  bool isActionExecuted;

  CopilotMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionType = CopilotActionType.none,
    this.actionData = const {},
    this.isOffline = false,
    this.isActionExecuted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'actionType': actionType.name,
        'actionData': actionData,
        'isOffline': isOffline,
        'isActionExecuted': isActionExecuted,
      };

  factory CopilotMessage.fromJson(Map<String, dynamic> json) {
    CopilotActionType type = CopilotActionType.none;
    try {
      type = CopilotActionType.values.byName(json['actionType'] ?? 'none');
    } catch (_) {}

    return CopilotMessage(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      actionType: type,
      actionData: Map<String, dynamic>.from(json['actionData'] ?? {}),
      isOffline: json['isOffline'] ?? false,
      isActionExecuted: json['isActionExecuted'] ?? false,
    );
  }
}
