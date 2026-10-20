import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChurchUserRole {
  member, // Muumini wa Sayuni aliyesajiliwa
  guest,  // Mgeni / Mshirika Mpya
  admin,  // Msimamizi Mkuu / Administrator (Scene Editing, Content Uploads, RBAC Root)
}

class ChurchAuthService extends ChangeNotifier {
  static final ChurchAuthService _instance = ChurchAuthService._internal();
  factory ChurchAuthService() => _instance;
  ChurchAuthService._internal();

  bool _isInitialized = false;
  bool _isOnboarded = false;
  ChurchUserRole _role = ChurchUserRole.member;

  String _name = 'Muumini wa Sayuni';
  String _phone = '+255 754 000 123';
  String _email = 'muumini@zionjerusalem.org';
  String _jumuiya = 'Mbagala Kijichi (Mt. Petro)';
  String _department = 'Kwaya ya Galilaya';
  String _memberId = 'ZJC-2026-8894';
  bool _isBaptized = true;

  bool get isInitialized => _isInitialized;
  bool get isOnboarded => _isOnboarded;
  ChurchUserRole get role => _role;
  bool get isMember => _role == ChurchUserRole.member;
  bool get isGuest => _role == ChurchUserRole.guest;
  bool get isAdmin => _role == ChurchUserRole.admin;
  bool get isLeader => _role == ChurchUserRole.admin || _department.contains('Uongozi') || _department.contains('Wazee') || _department.contains('Mchungaji') || _department.contains('Katibu');

  String get name => _name;
  String get phone => _phone;
  String get email => _email;
  String get jumuiya => _jumuiya;
  String get department => _department;
  String get memberId => _memberId;
  bool get isBaptized => _isBaptized;

  String get roleTitle {
    switch (_role) {
      case ChurchUserRole.admin:
        return 'Msimamizi Mkuu (Admin)';
      case ChurchUserRole.member:
        return 'Muumini wa Sayuni';
      case ChurchUserRole.guest:
        return 'Mgeni wa Heshima';
    }
  }

  String get roleBadge {
    switch (_role) {
      case ChurchUserRole.admin:
        return 'Msimamizi wa Mfumo ⚡';
      case ChurchUserRole.member:
        return 'Muumini Aliyesajiliwa 🛡️';
      case ChurchUserRole.guest:
        return 'Mgeni Karibu Sayuni 🕊️';
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboarded = prefs.getBool('auth_is_onboarded') ?? false;
      final roleStr = prefs.getString('auth_user_role') ?? 'member';
      if (roleStr == 'admin') {
        _role = ChurchUserRole.admin;
      } else if (roleStr == 'guest') {
        _role = ChurchUserRole.guest;
      } else {
        _role = ChurchUserRole.member;
      }

      _name = prefs.getString('user_name') ?? (_role == ChurchUserRole.admin
          ? 'Msimamizi Mkuu (Admin)'
          : (_role == ChurchUserRole.guest ? 'Mgeni Karibu' : 'Muumini wa Sayuni'));
      _phone = prefs.getString('user_phone') ?? '+255 754 000 123';
      _email = prefs.getString('user_email') ?? 'muumini@zionjerusalem.org';
      _jumuiya = prefs.getString('user_jumuiya') ?? 'Mbagala Kijichi (Mt. Petro)';
      _department = prefs.getString('user_dept') ?? 'Kwaya ya Galilaya';
      _memberId = prefs.getString('user_member_id') ?? 'ZJC-2026-8894';
      _isBaptized = prefs.getBool('user_baptized') ?? true;

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ChurchAuthService: $e');
    }
  }

  /// Login / Register as Verified Church Member
  Future<void> loginAsMember({
    required String name,
    required String phone,
    String? email,
    String? jumuiya,
    String? department,
    String? memberId,
    bool isBaptized = true,
  }) async {
    _role = ChurchUserRole.member;
    _isOnboarded = true;
    _name = name.trim();
    _phone = phone.trim();
    if (email != null && email.trim().isNotEmpty) _email = email.trim();
    if (jumuiya != null && jumuiya.trim().isNotEmpty) _jumuiya = jumuiya.trim();
    if (department != null && department.trim().isNotEmpty) _department = department.trim();
    _memberId = (memberId != null && memberId.trim().isNotEmpty)
        ? memberId.trim()
        : 'ZJC-${DateTime.now().year}-${1000 + (name.hashCode.abs() % 9000)}';
    _isBaptized = isBaptized;

    await _persist();
    notifyListeners();
  }

  /// Login as Visitor / Guest
  Future<void> loginAsGuest({
    required String name,
    String? phone,
  }) async {
    _role = ChurchUserRole.guest;
    _isOnboarded = true;
    _name = name.trim().isNotEmpty ? name.trim() : 'Mgeni Karibu';
    if (phone != null && phone.trim().isNotEmpty) _phone = phone.trim();
    _memberId = 'ZJC-GUEST';
    _department = 'Mgeni wa Ibada';
    _jumuiya = 'Ushirika wa Jumla';

    await _persist();
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? jumuiya,
    String? department,
    bool? isBaptized,
  }) async {
    if (name != null && name.trim().isNotEmpty) _name = name.trim();
    if (phone != null && phone.trim().isNotEmpty) _phone = phone.trim();
    if (email != null && email.trim().isNotEmpty) _email = email.trim();
    if (jumuiya != null && jumuiya.trim().isNotEmpty) _jumuiya = jumuiya.trim();
    if (department != null && department.trim().isNotEmpty) _department = department.trim();
    if (isBaptized != null) _isBaptized = isBaptized;

    await _persist();
    notifyListeners();
  }

  /// Local demo allowlist. Production admin access must use Firebase Auth claims.
  final Set<String> _grantedAdminEmails = {
    'admin@zionjerusalem.org',
  };

  Set<String> get grantedAdminEmails => _grantedAdminEmails;

  /// Grant admin status to an email address
  Future<void> grantAdminEmail(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean.isNotEmpty) {
      _grantedAdminEmails.add(clean);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('granted_admin_emails', _grantedAdminEmails.toList());
      notifyListeners();
    }
  }

  /// Revoke admin status from an email address
  Future<void> revokeAdminEmail(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean != 'admin@zionjerusalem.org') {
      _grantedAdminEmails.remove(clean);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('granted_admin_emails', _grantedAdminEmails.toList());
      notifyListeners();
    }
  }

  /// Sign In with Google (one-tap spiritual membership or admin if email matches granted admins)
  Future<bool> signInWithGoogle({
    required String googleEmail,
    required String displayName,
    String? photoUrl,
  }) async {
    final cleanEmail = googleEmail.trim().toLowerCase();
    final bool isAdminEmail = _grantedAdminEmails.contains(cleanEmail);

    _role = isAdminEmail ? ChurchUserRole.admin : ChurchUserRole.member;
    _isOnboarded = true;
    _name = displayName.trim().isNotEmpty ? displayName.trim() : 'Muumini wa Sayuni';
    _email = cleanEmail;
    _phone = _phone.isNotEmpty ? _phone : '+255 700 000 000';
    _memberId = isAdminEmail
        ? 'ZJC-ADMIN-${10 + (cleanEmail.hashCode.abs() % 90)}'
        : 'ZJC-${DateTime.now().year}-${1000 + (cleanEmail.hashCode.abs() % 9000)}';
    _department = isAdminEmail ? 'Utawala wa Kanisa & Tehama' : 'Ushirika wa Jumla';

    await _persist();
    notifyListeners();
    return true;
  }

  /// Login as Administrator with full scene and content editing permissions
  Future<bool> loginAsAdmin({
    required String emailOrUser,
    required String password,
  }) async {
    final cleanUser = emailOrUser.trim().toLowerCase();
    final cleanPass = password.trim();

    const demoPassword = String.fromEnvironment('ADMIN_DEMO_PASSWORD');
    final isGranted = _grantedAdminEmails.contains(cleanUser) || cleanUser == 'admin';
    if (isGranted && demoPassword.isNotEmpty && cleanPass == demoPassword) {
      _role = ChurchUserRole.admin;
      _isOnboarded = true;
      _name = cleanUser == 'admin' ? 'Msimamizi Mkuu' : cleanUser.split('@').first;
      _email = cleanUser.contains('@') ? cleanUser : 'admin@zionjerusalem.org';
      _phone = '+255 754 000 001';
      _department = 'Utawala wa Kanisa & Tehama';
      _jumuiya = 'Hekalu Kuu Sayuni';
      _memberId = 'ZJC-ADMIN-01';
      _isBaptized = true;

      await _persist();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isOnboarded = false;
    _role = ChurchUserRole.guest;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_is_onboarded', false);
    notifyListeners();
  }

  /// Permanently delete account and erase all associated personal records
  /// Compliant with Google Play & Apple App Store Guidelines and Tanzania PDPA 2022.
  Future<void> deleteAccount() async {
    _isOnboarded = false;
    _role = ChurchUserRole.guest;
    _name = 'Mgeni Karibu';
    _phone = '';
    _email = '';
    _jumuiya = 'Ushirika wa Jumla';
    _department = 'Mgeni wa Ibada';
    _memberId = '';
    _isBaptized = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_is_onboarded');
      await prefs.remove('auth_user_role');
      await prefs.remove('user_name');
      await prefs.remove('user_phone');
      await prefs.remove('user_email');
      await prefs.remove('user_jumuiya');
      await prefs.remove('user_dept');
      await prefs.remove('user_member_id');
      await prefs.remove('user_baptized');
      await prefs.setBool('auth_is_onboarded', false);
      await prefs.setString('auth_user_role', 'guest');
    } catch (e) {
      debugPrint('Error erasing account data: $e');
    }

    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_is_onboarded', _isOnboarded);
      String roleString = 'member';
      if (_role == ChurchUserRole.admin) {
        roleString = 'admin';
      } else if (_role == ChurchUserRole.guest) {
        roleString = 'guest';
      }
      await prefs.setString('auth_user_role', roleString);
      await prefs.setString('user_name', _name);
      await prefs.setString('user_phone', _phone);
      await prefs.setString('user_email', _email);
      await prefs.setString('user_jumuiya', _jumuiya);
      await prefs.setString('user_dept', _department);
      await prefs.setString('user_member_id', _memberId);
      await prefs.setBool('user_baptized', _isBaptized);
    } catch (e) {
      debugPrint('Error persisting auth: $e');
    }
  }
}
