class ChurchBranch {
  final String id;
  final String name;
  final String city;
  final String location;
  final String pastor;
  final String phone;
  final String whatsapp;
  final String email;
  final String serviceTimes;
  final bool isHeadquarters;
  final String description;

  const ChurchBranch({
    required this.id,
    required this.name,
    required this.city,
    required this.location,
    required this.pastor,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.serviceTimes,
    required this.isHeadquarters,
    required this.description,
  });

  static const List<ChurchBranch> defaultBranches = [
    ChurchBranch(
      id: 'dar-hq',
      name: 'Sayuni Yerusalemu — Makao Makuu (HQ)',
      city: 'Dar es Salaam',
      location: 'Mbagala Kwa Matope, Wilaya ya Temeke',
      pastor: 'Mchungaji Askofu Messi Mgala',
      phone: '+255754000111',
      whatsapp: '255754000111',
      email: 'info@zionjerusalem.org',
      serviceTimes: 'Jumapili: 08:30 - 13:30 | Jumatano: 16:30 - 18:30 | Ijumaa: 21:00 (Mkesha)',
      isHeadquarters: true,
      description: 'Hekalu Kuu la Sayuni — Makao Makuu ya Huduma, Ukombozi na Mafundisho ya Neno la Uzima.',
    ),
    ChurchBranch(
      id: 'mbagala-kibondemaji',
      name: 'Sayuni Yerusalemu — Tawi la Kibondemaji',
      city: 'Dar es Salaam',
      location: 'Mbagala Kibondemaji, Wilaya ya Temeke',
      pastor: 'Mchungaji Msaidizi Alex',
      phone: '+255755889900',
      whatsapp: '255755889900',
      email: 'kibondemaji@zionjerusalem.org',
      serviceTimes: 'Jumapili: 09:00 - 12:30 | Alhamisi: 16:30 - 18:30',
      isHeadquarters: false,
      description: 'Tawi la Kibondemaji — Kituo cha Ibada, Maombi na Ushirika wa Nyumba kwa Nyumba.',
    ),
    ChurchBranch(
      id: 'vikindu-branch',
      name: 'Sayuni Yerusalemu — Tawi la Vikindu',
      city: 'Pwani',
      location: 'Vikindu, Barabara Kuu ya Kilwa, Pwani',
      pastor: 'Mchungaji Kiongozi wa Vikindu',
      phone: '+255768222333',
      whatsapp: '255768222333',
      email: 'vikindu@zionjerusalem.org',
      serviceTimes: 'Jumapili: 09:00 - 13:00 | Jumatano: 17:00 - 18:30',
      isHeadquarters: false,
      description: 'Sayuni Mkoa wa Pwani — Nguvu ya Neno na Uponyaji.',
    ),
    ChurchBranch(
      id: 'kisemvule-branch',
      name: 'Sayuni Yerusalemu — Tawi la Kisemvule',
      city: 'Pwani',
      location: 'Kisemvule Mjini, Mkoa wa Pwani',
      pastor: 'Mchungaji wa Kisemvule',
      phone: '+255713444555',
      whatsapp: '255713444555',
      email: 'kisemvule@zionjerusalem.org',
      serviceTimes: 'Jumapili: 08:30 - 12:30 | Jumanne: 16:30 - 18:30',
      isHeadquarters: false,
      description: 'Sayuni Kisemvule — Ushirika wa Upendo na Maombi ya Ukombozi.',
    ),
    ChurchBranch(
      id: 'morogoro-branch',
      name: 'Sayuni Yerusalemu — Tawi la Morogoro',
      city: 'Morogoro',
      location: 'Morogoro Mjini, Karibu na Msamvu',
      pastor: 'Mchungaji wa Morogoro',
      phone: '+255754889911',
      whatsapp: '255754889911',
      email: 'morogoro@zionjerusalem.org',
      serviceTimes: 'Jumapili: 09:00 - 13:00 | Alhamisi: 17:00 - 18:30',
      isHeadquarters: false,
      description: 'Sauti ya Sayuni Mkoani Morogoro — Ibada za Kufunguliwa na Nuru.',
    ),
    ChurchBranch(
      id: 'bukoba-branch',
      name: 'Sayuni Yerusalemu — Tawi la Bukoba',
      city: 'Bukoba (Kagera)',
      location: 'Bukoba Mjini, Mkoa wa Kagera',
      pastor: 'Mchungaji wa Bukoba',
      phone: '+255784332211',
      whatsapp: '255784332211',
      email: 'bukoba@zionjerusalem.org',
      serviceTimes: 'Jumapili: 09:00 - 13:00 | Jumatano: 16:30 - 18:30',
      isHeadquarters: false,
      description: 'Sayuni Kanda ya Ziwa Magharibi — Kituo cha Uinjilisti na Maombi.',
    ),
    ChurchBranch(
      id: 'njombe-branch',
      name: 'Sayuni Yerusalemu — Tawi la Njombe',
      city: 'Njombe',
      location: 'Njombe Mjini, Nyanda za Juu Kusini',
      pastor: 'Mchungaji wa Njombe',
      phone: '+255768554433',
      whatsapp: '255768554433',
      email: 'njombe@zionjerusalem.org',
      serviceTimes: 'Jumapili: 09:00 - 12:30 | Ijumaa: 17:00 - 18:30',
      isHeadquarters: false,
      description: 'Kituo cha Sayuni Nyanda za Juu Kusini — Moto wa Maombi na Neema.',
    ),
    ChurchBranch(
      id: 'makambako-branch',
      name: 'Sayuni Yerusalemu — Tawi la Makambako',
      city: 'Makambako',
      location: 'Makambako Mjini, Njia Panda',
      pastor: 'Mchungaji wa Makambako',
      phone: '+255755112299',
      whatsapp: '255755112299',
      email: 'makambako@zionjerusalem.org',
      serviceTimes: 'Jumapili: 09:00 - 13:00 | Jumatano: 16:30 - 18:00',
      isHeadquarters: false,
      description: 'Sayuni Makambako — Nguvu ya Neno la Msalaba na Ushindi.',
    ),
  ];
}
