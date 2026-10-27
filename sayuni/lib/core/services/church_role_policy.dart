/// Canonical church roles, their wire names and the permission matrix.
///
/// This is the **single source of truth** for "who may do what". The same
/// `wireName` strings are what `firestore.rules` reads from
/// `request.auth.token.role`, so a permission granted in the UI has a 1:1
/// counterpart in the cloud rules. Keeping them in one place is what stops the
/// old failure mode where a device-only flag (`auth_user_role` in
/// SharedPreferences) decided admin rights.
library;

enum ChurchRole {
  guest('guest', 0, 'Mgeni wa Heshima', 'Honorary Guest'),
  member('member', 10, 'Muumini wa Sayuni', 'Registered Member'),
  jumuiyaLeader('jumuiya_leader', 20, 'Kiongozi wa Jumuiya', 'Cell Leader'),
  choirLeader('choir_leader', 20, 'Kiongozi wa Kwaya', 'Choir Leader'),
  childrenTeacher(
      'children_teacher', 20, 'Mwalimu wa Watoto', 'Children Teacher'),
  treasurer('treasurer', 30, 'Mehani wa Kanisa', 'Treasurer'),
  deacon('deacon', 40, 'Mzee wa Kanisa', 'Deacon'),
  secretary('secretary', 50, 'Katibu wa Kanisa', 'Church Secretary'),
  pastor('pastor', 60, 'Mchungaji', 'Pastor'),
  admin('admin', 70, 'Msimamizi Mkuu', 'Administrator'),
  superAdmin('super_admin', 80, 'Msimamizi wa Mfumo', 'Super Administrator');

  const ChurchRole(
    this.wireName,
    this.rank,
    this.titleSw,
    this.titleEn,
  );

  /// Value stored in the Firebase custom claim `role` and compared in
  /// `firestore.rules`. Never rename without updating the rules.
  final String wireName;

  /// Ordering only. Sensitive abilities use [ChurchRolePolicy.can], never rank.
  final int rank;
  final String titleSw;
  final String titleEn;

  @override
  String toString() => wireName;
}

/// Where the currently applied role came from.
///
/// * [cloud]  — verified from the signed-in Firebase ID token claims. Only this
///   source can be trusted by Firestore rules.
/// * [device] — cached on this device (member/guest onboarding, or a role
///   granted before cloud auth existed). UI convenience only.
/// * [demo]   — debug/demo build shortcut (`kDebugMode` or
///   `--dart-define=DEMO_MODE=true`). Never reachable from a normal release.
enum RoleSource { cloud, device, demo, none }

enum ChurchPermission {
  useMemberFeatures,
  submitPrayerRequest,
  registerVisitor,
  viewOwnGiving,
  uploadSermonMedia,
  uploadChoirMedia,
  manageAnnouncements,
  viewVisitorRegistry,
  viewPastoralPrayers,
  manageJumuiyaReports,
  manageMembers,
  recordFinance,
  approveExpense,
  viewFinancialReports,
  manageAssets,
  manageMinutes,
  manageChurchSettings,
  grantRoles,
}

/// Maps [ChurchPermission] to the roles allowed to exercise it.
///
/// Deliberately explicit sets rather than "rank >= n": a Katibu outranks a
/// Mehani in hierarchy but must not be able to approve payments, and a Mehani
/// may touch money but not the pastoral prayer desk.
class ChurchRolePolicy {
  const ChurchRolePolicy._();

  /// Custom claim keys written by `functions/setUserRole`.
  static const String roleKey = 'role';
  static const String branchKey = 'branch';
  static const String memberIdKey = 'memberId';

  static const Set<ChurchRole> _everyone = {ChurchRole.guest};
  static const Set<ChurchRole> _registered = {
    ChurchRole.member,
    ChurchRole.jumuiyaLeader,
    ChurchRole.choirLeader,
    ChurchRole.childrenTeacher,
    ChurchRole.treasurer,
    ChurchRole.deacon,
    ChurchRole.secretary,
    ChurchRole.pastor,
    ChurchRole.admin,
    ChurchRole.superAdmin,
  };
  static const Set<ChurchRole> _leadership = {
    ChurchRole.jumuiyaLeader,
    ChurchRole.choirLeader,
    ChurchRole.childrenTeacher,
    ChurchRole.treasurer,
    ChurchRole.deacon,
    ChurchRole.secretary,
    ChurchRole.pastor,
    ChurchRole.admin,
    ChurchRole.superAdmin,
  };
  static const Set<ChurchRole> _administration = {
    ChurchRole.treasurer,
    ChurchRole.deacon,
    ChurchRole.secretary,
    ChurchRole.pastor,
    ChurchRole.admin,
    ChurchRole.superAdmin,
  };
  static const Set<ChurchRole> _secretariat = {
    ChurchRole.secretary,
    ChurchRole.pastor,
    ChurchRole.admin,
    ChurchRole.superAdmin,
  };
  static const Set<ChurchRole> _pastoral = {
    ChurchRole.pastor,
    ChurchRole.admin,
    ChurchRole.superAdmin,
  };
  static const Set<ChurchRole> _root = {
    ChurchRole.admin,
    ChurchRole.superAdmin,
  };
  static const Set<ChurchRole> _moneyIn = {
    ChurchRole.treasurer,
    ChurchRole.secretary,
    ChurchRole.pastor,
    ChurchRole.admin,
    ChurchRole.superAdmin,
  };
  static const Set<ChurchRole> _moneyRead = {
    ChurchRole.treasurer,
    ChurchRole.secretary,
    ChurchRole.pastor,
    ChurchRole.admin,
    ChurchRole.superAdmin,
  };

  static const Map<ChurchPermission, Set<ChurchRole>> _matrix = {
    ChurchPermission.useMemberFeatures: _everyone,
    ChurchPermission.submitPrayerRequest: _everyone,
    ChurchPermission.registerVisitor: _leadership,
    ChurchPermission.viewOwnGiving: _registered,
    ChurchPermission.uploadSermonMedia: _pastoral,
    ChurchPermission.uploadChoirMedia: _pastoral,
    ChurchPermission.manageAnnouncements: _secretariat,
    ChurchPermission.viewVisitorRegistry: _administration,
    ChurchPermission.viewPastoralPrayers: _pastoral,
    ChurchPermission.manageJumuiyaReports: _administration,
    ChurchPermission.manageMembers: _secretariat,
    ChurchPermission.recordFinance: _moneyIn,
    ChurchPermission.approveExpense: _pastoral,
    ChurchPermission.viewFinancialReports: _moneyRead,
    ChurchPermission.manageAssets: _secretariat,
    ChurchPermission.manageMinutes: _secretariat,
    ChurchPermission.manageChurchSettings: _root,
    ChurchPermission.grantRoles: _root,
  };

  static bool can(ChurchRole role, ChurchPermission permission) {
    final allowed = _matrix[permission];
    if (allowed == null) return false;
    if (allowed.contains(role)) return true;
    // Ranks above an allowed role inherit it (super_admin ⊃ admin ⊃ pastor …).
    for (final candidate in allowed) {
      if (role.rank > candidate.rank) return true;
    }
    return false;
  }

  static bool isPrivileged(ChurchRole role) =>
      role.rank >= ChurchRole.jumuiyaLeader.rank;

  /// Accepts claim values (`secretary`), legacy values (`admin`) and Swahili
  /// job titles used in older local profiles. Returns null when the value is
  /// unknown so callers can fall back instead of guessing.
  static ChurchRole? parse(Object? raw) {
    if (raw == null) return null;
    final key = raw.toString().trim().toLowerCase().replaceAll(' ', '_');
    if (key.isEmpty) return null;
    for (final role in ChurchRole.values) {
      if (role.wireName == key) return role;
    }
    switch (key) {
      case 'superadmin':
      case 'super-admin':
      case 'administrator':
      case 'msimamizi':
        return ChurchRole.admin;
      case 'katibu':
      case 'secretary_mkuu':
        return ChurchRole.secretary;
      case 'mchungaji':
      case 'pastor_mkuu':
      case 'askofu':
      case 'bishop':
        return ChurchRole.pastor;
      case 'hazina':
      case 'mehani':
      case 'cashier':
        return ChurchRole.treasurer;
      case 'mzee':
      case 'mushindi':
      case 'elder':
        return ChurchRole.deacon;
      case 'kwaya':
      case 'choir':
        return ChurchRole.choirLeader;
      case 'jumuiya':
      case 'cell_leader':
        return ChurchRole.jumuiyaLeader;
      case 'watoto':
      case 'teacher':
        return ChurchRole.childrenTeacher;
      case 'muumini':
      case 'believer':
        return ChurchRole.member;
      case 'mgeni':
      case 'visitor':
        return ChurchRole.guest;
      default:
        return null;
    }
  }
}
