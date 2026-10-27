import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'church_role_grant_service.dart';
import 'church_role_policy.dart';

// Screens gate actions with [ChurchPermission] and label roles with
// [ChurchRole]; re-exporting keeps every consumer to a single import and makes
// it impossible to check a permission against a role type from two files.
export 'church_role_policy.dart' show ChurchRole, ChurchPermission, RoleSource;

/// Legacy 3-value role view, kept only so existing screens keep compiling.
/// New code uses [ChurchAuthService.churchRole] and [ChurchAuthService.can].
enum ChurchUserRole {
  member, // Muumini wa Sayuni aliyesajiliwa
  guest, // Mgeni / Mshirika Mpya
  admin, // Msimamizi Mkuu / Administrator (Scene Editing, Content Uploads, RBAC Root)
}

class ChurchAuthService extends ChangeNotifier {
  static final ChurchAuthService _instance = ChurchAuthService._internal();
  factory ChurchAuthService() => _instance;
  ChurchAuthService._internal();

  /// Demo fast-entry stays reachable in debug builds and in explicit demo
  /// builds (`--dart-define=DEMO_MODE=true`). A normal release build cannot
  /// self-grant any privileged role.
  static const bool _demoDefineFlag =
      bool.fromEnvironment('DEMO_MODE', defaultValue: false);
  bool get demoAccessAllowed => kDebugMode || _demoDefineFlag;

  /// Transitional bootstrap allowance — **not** a security boundary.
  ///
  /// Until `functions/setUserRole` has written a real `role` claim for the
  /// owner's account (see `docs/FIREBASE_SETUP_OWNER.md`), this single seed
  /// address keeps its cached admin role on its own device so the owner is not
  /// locked out of the app he is still configuring. As soon as a claim exists
  /// the claim wins and this list is irrelevant; it is deleted in Phase 10.
  static const Set<String> _bootstrapOwnerEmails = {
    'admin@zionjerusalem.org',
  };

  bool get isBootstrapOwnerAccount =>
      _bootstrapOwnerEmails.contains(_email.trim().toLowerCase());

  /// May a non-cloud privileged role be honoured on this device at all?
  bool get _bootstrapTrustAllowed =>
      demoAccessAllowed || isBootstrapOwnerAccount;

  FirebaseAuth? _cachedAuth;
  bool _authLookupFailed = false;

  /// `FirebaseAuth.instance` throws when `Firebase.initializeApp` never
  /// succeeded (offline boot, wrong project id). The app must still open, so the
  /// failure is captured once and callers degrade to device-scoped roles.
  FirebaseAuth? get _auth {
    if (_authLookupFailed) return null;
    if (_cachedAuth != null) return _cachedAuth;
    try {
      _cachedAuth = FirebaseAuth.instance;
    } catch (e) {
      _authLookupFailed = true;
      debugPrint('Firebase Auth unavailable, local-only mode: $e');
    }
    return _cachedAuth;
  }

  bool _isInitialized = false;
  bool _isOnboarded = false;
  ChurchRole _role = ChurchRole.member;
  RoleSource _source = RoleSource.none;
  String? _uid;
  bool _claimsChecked = false;
  StreamSubscription<User?>? _authStateSubscription;

  /// Canonical role, verified from ID-token claims when [roleSource] is
  /// [RoleSource.cloud].
  ChurchRole get churchRole => _role;
  RoleSource get roleSource => _source;
  String? get uid => _uid;
  bool get claimsVerified => _claimsChecked;
  bool get hasCloudSession => _uid != null;
  bool get isCloudVerified => _source == RoleSource.cloud;

  String _name = 'Muumini wa Sayuni';
  String _phone = '+255 754 000 123';
  String _email = 'muumini@zionjerusalem.org';
  String _jumuiya = 'Mbagala Kijichi (Mt. Petro)';
  String _department = 'Kwaya ya Galilaya';
  String _memberId = 'ZJC-2026-8894';
  bool _isBaptized = true;

  bool get isInitialized => _isInitialized;
  bool get isOnboarded => _isOnboarded;

  /// Legacy 3-value projection of [churchRole], kept for existing widgets.
  ChurchUserRole get role {
    if (_role == ChurchRole.guest) return ChurchUserRole.guest;
    if (_role.rank >= ChurchRole.admin.rank) return ChurchUserRole.admin;
    return ChurchUserRole.member;
  }

  /// Everyone with an actual church membership (leaders included).
  bool get isMember => _role.rank >= ChurchRole.member.rank;
  bool get isGuest => _role == ChurchRole.guest;

  /// A role only counts once it has a source; before init nothing is admin.
  bool get isAdmin =>
      _role.rank >= ChurchRole.admin.rank && _source != RoleSource.none;

  bool get isLeader =>
      ChurchRolePolicy.isPrivileged(_role) ||
      _department.contains('Uongozi') ||
      _department.contains('Wazee') ||
      _department.contains('Mchungaji') ||
      _department.contains('Katibu');

  /// Pure role/permission check used by the UI (see [ChurchRolePolicy]).
  bool can(ChurchPermission permission) =>
      ChurchRolePolicy.can(_role, permission);

  /// Cloud-verified variant for anything that also gates a network write.
  bool canUi(ChurchPermission permission) =>
      can(permission) && _source != RoleSource.none;

  String get name => _name;
  String get phone => _phone;
  String get email => _email;
  String get jumuiya => _jumuiya;
  String get department => _department;
  String get memberId => _memberId;
  bool get isBaptized => _isBaptized;

  String get roleTitle => _role.titleSw;

  /// Role title plus a mark showing *where* the authority came from, so a
  /// device-cached or demo role is never mistaken for a cloud-granted one.
  String get roleBadge {
    final mark = switch (_source) {
      RoleSource.cloud => ' ✅',
      RoleSource.demo => ' (Onyesho)',
      RoleSource.device => ' 🛡️',
      RoleSource.none => '',
    };
    if (_source == RoleSource.none) return 'Hakuna mamlaka iliyowekwa';
    return '${_role.titleSw}$mark';
  }

  /// One-line explanation of the trust level of the current role. Shown in the
  /// admin dashboard so nobody believes a local flag is real access.
  String get roleSourceLabel {
    switch (_source) {
      case RoleSource.cloud:
        return 'Mamlaka imethibitishwa na Firebase';
      case RoleSource.demo:
        return 'Mamlaka ya onyesho — si ya uzalishaji';
      case RoleSource.device:
        return 'Mamlaka ya kifaa hiki — haijathibitishwa';
      case RoleSource.none:
        return 'Hakuna mamlaka iliyowekwa';
    }
  }

  /// Boot order matters for perceived speed: the cached device role is applied
  /// immediately, cloud claims are verified in the background and notify again.
  /// A cold start must never wait on a network round trip.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      await _restoreFromDevice();
      notifyListeners();

      unawaited(_resolveFromFirebase());

      _authStateSubscription?.cancel();
      _authStateSubscription = _auth?.authStateChanges().listen((_) {
        unawaited(_resolveFromFirebase());
      });
    } catch (e) {
      debugPrint('Error initializing ChurchAuthService: $e');
    }
  }

  /// Loads the locally cached identity. Everything read here is treated as a
  /// convenience cache, never as proof of authority.
  Future<void> _restoreFromDevice() async {
    final prefs = await SharedPreferences.getInstance();
    _isOnboarded = prefs.getBool('auth_is_onboarded') ?? false;

    // The `??` also covers builds from before the role policy, which stored
    // only admin | member | guest under the legacy key.
    final parsed = ChurchRolePolicy.parse(prefs.getString('auth_role_v2')) ??
        ChurchRolePolicy.parse(prefs.getString('auth_user_role'));
    _role = parsed ?? ChurchRole.member;

    final storedSource = prefs.getString('auth_role_source') ?? '';
    if (!_isOnboarded) {
      _source = RoleSource.none;
    } else if (storedSource == RoleSource.demo.name) {
      _source = RoleSource.demo;
    } else {
      _source = RoleSource.device;
    }

    // A demo role cached by a debug session must not survive into a normal
    // release installed over the same browser/app profile.
    if (_source == RoleSource.demo && !demoAccessAllowed) {
      if (ChurchRolePolicy.isPrivileged(_role)) _role = ChurchRole.member;
      _source = RoleSource.device;
    }

    _uid = prefs.getString('auth_uid');
    _name = prefs.getString('user_name') ?? defaultNameForRole();
    _phone = prefs.getString('user_phone') ?? '+255 754 000 123';
    _email = prefs.getString('user_email') ?? 'muumini@zionjerusalem.org';
    _jumuiya = prefs.getString('user_jumuiya') ?? 'Mbagala Kijichi (Mt. Petro)';
    _department = prefs.getString('user_dept') ?? 'Kwaya ya Galilaya';
    _memberId = prefs.getString('user_member_id') ?? 'ZJC-2026-8894';
    _isBaptized = prefs.getBool('user_baptized') ?? true;

    // A privileged role is only carried over the cache when it is the seed
    // owner account (transitional bootstrap, see [_bootstrapOwnerEmails]) or a
    // demo build. Everything else goes back to member until a real claim
    // exists — a local flag alone can no longer be authority.
    if (ChurchRolePolicy.isPrivileged(_role) &&
        (!_isOnboarded || !_bootstrapTrustAllowed)) {
      _role = ChurchRole.member;
      if (!_isOnboarded) _source = RoleSource.none;
    }

    // Read-only: shown in the admin dashboard so the owner can see the list.
    // It grants nothing by itself (see [signInWithGoogle]).
    final emails = prefs.getStringList('granted_admin_emails');
    if (emails != null) _grantedAdminEmails.addAll(emails);
  }

  /// Default display name for the current role.
  String defaultNameForRole() {
    if (_role == ChurchRole.guest) return 'Mgeni Karibu';
    if (_role.rank >= ChurchRole.admin.rank) return 'Msimamizi Mkuu';
    return 'Muumini wa Sayuni';
  }

  bool _claimsResolveInFlight = false;

  /// The only path that may raise a role to [RoleSource.cloud]: the signed-in
  /// user's own Firebase ID token claims, written server-side by
  /// `functions/setUserRole`. Firestore rules trust exactly the same claims, so
  /// the UI can never show an affordance the backend would reject.
  Future<void> _resolveFromFirebase() async {
    if (_claimsResolveInFlight) return;
    final auth = _auth;
    if (auth == null) return;

    User? user;
    try {
      user = auth.currentUser;
    } catch (e) {
      debugPrint('Firebase user lookup failed: $e');
      return;
    }

    if (user == null) {
      // Signed out: drop any cloud-granted authority, keep the local profile.
      if (_source == RoleSource.cloud) {
        _role = ChurchRole.member;
        _source = _isOnboarded ? RoleSource.device : RoleSource.none;
        await _persist();
        notifyListeners();
      }
      _uid = null;
      _claimsChecked = false;
      return;
    }

    _uid = user.uid;
    _claimsResolveInFlight = true;
    try {
      final token =
          await user.getIdTokenResult(true).timeout(const Duration(seconds: 8));
      final claims = token.claims ?? const <String, dynamic>{};
      final claimed = ChurchRolePolicy.parse(claims[ChurchRolePolicy.roleKey]);

      if (claimed != null) {
        _role = claimed;
        _source = RoleSource.cloud;
      } else {
        // No claim = the owner has not assigned this account yet
        // (`functions/setUserRole`). Only demo builds and the single seed owner
        // address may keep a privileged role without a claim.
        if (ChurchRolePolicy.isPrivileged(_role) && !_bootstrapTrustAllowed) {
          _role = ChurchRole.member;
        }
        _source = _isOnboarded ? RoleSource.device : RoleSource.none;
      }

      final branch = claims[ChurchRolePolicy.branchKey]?.toString().trim();
      if (branch != null && branch.isNotEmpty) _jumuiya = branch;
      final member = claims[ChurchRolePolicy.memberIdKey]?.toString().trim();
      if (member != null && member.isNotEmpty) _memberId = member;

      _claimsChecked = true;
      await _persist();
      notifyListeners();
    } on TimeoutException {
      debugPrint('Claim resolution timed out — keeping ${_role.wireName}');
    } catch (e) {
      debugPrint('Claim resolution failed — keeping device role: $e');
    } finally {
      _claimsResolveInFlight = false;
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
    _role = ChurchRole.member;
    _source = RoleSource.device;
    _isOnboarded = true;
    _name = name.trim();
    _phone = phone.trim();
    if (email != null && email.trim().isNotEmpty) _email = email.trim();
    if (jumuiya != null && jumuiya.trim().isNotEmpty) _jumuiya = jumuiya.trim();
    if (department != null && department.trim().isNotEmpty)
      _department = department.trim();
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
    _role = ChurchRole.guest;
    _source = RoleSource.device;
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
    if (department != null && department.trim().isNotEmpty)
      _department = department.trim();
    if (isBaptized != null) _isBaptized = isBaptized;

    await _persist();
    notifyListeners();
  }

  /// Device-side bootstrap allowlist. **This grants nothing in the cloud.**
  /// Real role assignment is `functions/setUserRole` → ID-token claims, which
  /// is the only thing `firestore.rules` will honour.
  final Set<String> _grantedAdminEmails = {
    'admin@zionjerusalem.org',
  };

  Set<String> get grantedAdminEmails => Set.unmodifiable(_grantedAdminEmails);

  /// Records a bootstrap admin email on this device.
  /// Returns `false` and changes nothing in a normal release build — a real
  /// grant has to go through Firebase (see `docs/FIREBASE_SETUP_OWNER.md`).
  Future<bool> grantAdminEmail(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return false;
    if (!demoAccessAllowed) return false;
    if (_grantedAdminEmails.contains(clean)) return true;
    _grantedAdminEmails.add(clean);
    await _saveGrantedAdminEmails();
    notifyListeners();
    return true;
  }

  /// Removes a bootstrap admin email from this device. The seed owner address
  /// cannot be removed so the owner can never lock himself out completely.
  Future<bool> revokeAdminEmail(String email) async {
    final clean = email.trim().toLowerCase();
    if (_bootstrapOwnerEmails.contains(clean)) return false;
    if (!_grantedAdminEmails.contains(clean)) return true;
    _grantedAdminEmails.remove(clean);
    await _saveGrantedAdminEmails();
    notifyListeners();
    return true;
  }

  Future<void> _saveGrantedAdminEmails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'granted_admin_emails', _grantedAdminEmails.toList());
  }

  /// Grants a church role the honest way: ask the server first.
  ///
  ///  1. With a live Firebase session, `functions/setUserRole` writes real
  ///     custom claims. That is the only outcome that changes what Firestore
  ///     will allow — and it is reported as `viaCloud: true`.
  ///  2. If the server refuses and this is a demo/dev build, the device
  ///     allowlist is updated as well and the message says so.
  ///  3. If the server refuses in a release build, the failure is returned
  ///     unchanged. A failed grant is never converted into a local "success".
  Future<RoleGrantResult> grantRole(
    String email, {
    ChurchRole role = ChurchRole.admin,
  }) async {
    final clean = email.trim().toLowerCase();
    if (!clean.contains('@') || clean.startsWith('@') || clean.endsWith('@')) {
      return const RoleGrantResult.fail(
          'Weka barua pepe halali (mfano: mchungaji@gmail.com).');
    }
    if (!canUi(ChurchPermission.grantRoles)) {
      return const RoleGrantResult.fail(
        '✕ Role yako haina mamlaka ya kugawa mamlaka. Mamlaka ya kweli hutolewa '
        'na admin/super_admin ambaye role yake iko kwenye Firebase Auth claims — '
        'ona docs/FIREBASE_SETUP_OWNER.md.',
      );
    }
    if (!hasCloudSession) {
      final local = await grantAdminEmail(clean);
      if (!local) {
        return const RoleGrantResult.fail(
          '✕ Mamlaka haijapewa: hakuna session ya Firebase kwenye kifaa hiki na '
          'build hii si ya majaribio. Weka role kwa Firebase — ona '
          'docs/FIREBASE_SETUP_OWNER.md.',
        );
      }
      return RoleGrantResult.ok(
        viaCloud: false,
        message: '⚠ $clean imeongezwa kwenye orodha ya kifaa hiki (majaribio). '
            'Hakuna session ya Firebase, kwa hivyo mamlaka ya cloud haijabadilika.',
      );
    }

    final res = await ChurchRoleGrantService.setUserRole(
      targetEmail: clean,
      role: role,
      reason: 'Kugawwa mamlaka na $_email kupitia Sayuni Admin',
    );
    if (res.success) {
      await grantAdminEmail(clean);
      return res;
    }
    if (!demoAccessAllowed) return res;
    await grantAdminEmail(clean);
    return RoleGrantResult.ok(
      viaCloud: false,
      message: '${res.message}\n\n⚠ Imehifadhiwa kwenye orodha ya kifaa hiki '
          'pekee (majaribio). Mamlaka ya kweli bado haijawekwa kwenye Firebase.',
    );
  }

  /// Revokes a role: server-side claim back to `member`, plus the local list.
  Future<RoleGrantResult> revokeRole(String email) async {
    final clean = email.trim().toLowerCase();
    if (!canUi(ChurchPermission.grantRoles)) {
      return const RoleGrantResult.fail(
        '✕ Huna mamlaka ya kuondolea mtu role.',
      );
    }
    if (hasCloudSession) {
      final res = await ChurchRoleGrantService.revokeUserRole(
        targetEmail: clean,
        reason: 'Kuondolewa na $_email kupitia Sayuni Admin',
      );
      if (res.success) {
        final local = await revokeAdminEmail(clean);
        return RoleGrantResult.ok(
          message: local
              ? '✔ Role imeondolewa kwenye Firebase Auth na kwenye orodha ya kifaa hiki.'
              : '✔ Role imeondolewa kwenye Firebase Auth. Orodha ya kifaa hiki '
                  'haina barua pepe hiyo (au ni akaunti kuu).',
        );
      }
      if (!demoAccessAllowed) return res;
    }
    final local = await revokeAdminEmail(clean);
    return local
        ? RoleGrantResult.ok(
            viaCloud: false,
            message: '⚠ $clean imeondolewa kwenye orodha ya kifaa hiki pekee. '
                'Kama alipewa role kwenye Firebase, ondolewa pia hapo — ona '
                'docs/FIREBASE_SETUP_OWNER.md.',
          )
        : RoleGrantResult.fail(
            '✕ $clean ni akaunti kuu ya mfumo - haiwezi kuondolewa hapa.',
          );
  }

  /// Attaches a profile to a Google-style email. It does **not** authenticate
  /// anybody — no OAuth token is verified here — so it must never mint admin on
  /// its own. Real Google sign-in lands in Phase 3; until then the effective
  /// role always comes from [ChurchRolePolicy] plus the cloud claims of
  /// whatever Firebase session actually exists.
  Future<bool> signInWithGoogle({
    required String googleEmail,
    required String displayName,
    String? photoUrl,
  }) async {
    final cleanEmail = googleEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) return false;

    // Demo/debug builds may shortcut the owner's own address to admin so the
    // flow stays testable. A normal release build cannot.
    final bool demoAdmin =
        demoAccessAllowed && _grantedAdminEmails.contains(cleanEmail);

    _role = demoAdmin ? ChurchRole.admin : ChurchRole.member;
    _source = demoAdmin ? RoleSource.demo : RoleSource.device;
    _isOnboarded = true;
    _name = displayName.trim().isNotEmpty
        ? displayName.trim()
        : 'Muumini wa Sayuni';
    _email = cleanEmail;
    _phone = _phone.isNotEmpty ? _phone : '+255 700 000 000';
    _memberId = demoAdmin
        ? 'ZJC-ADMIN-${10 + (cleanEmail.hashCode.abs() % 90)}'
        : 'ZJC-${DateTime.now().year}-${1000 + (cleanEmail.hashCode.abs() % 9000)}';
    _department =
        demoAdmin ? 'Utawala wa Kanisa & Tehama' : 'Ushirika wa Jumla';

    await _persist();
    notifyListeners();

    // A real Firebase session outranks any locally inferred role.
    await _resolveFromFirebase();
    return true;
  }

  /// Administrator sign-in.
  ///
  /// Firebase Auth verifies the password; the **role** is whatever the
  /// ID-token claims say. A correct password without a `role` claim only yields
  /// a transitional device-scoped admin (clearly labelled by [roleSourceLabel])
  /// for a bootstrap-allowlisted account — never a cloud-verified one.
  Future<bool> loginAsAdmin({
    required String emailOrUser,
    required String password,
  }) async {
    final cleanUser = emailOrUser.trim().toLowerCase();
    final cleanPass = password.trim();
    final String email =
        cleanUser.contains('@') ? cleanUser : 'admin@zionjerusalem.org';
    final bool allowlisted =
        _grantedAdminEmails.contains(cleanUser) || cleanUser == 'admin';

    final auth = _auth;
    if (auth != null) {
      try {
        final userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: cleanPass,
        );
        if (userCredential.user != null) {
          _isOnboarded = true;
          _name = cleanUser == 'admin'
              ? 'Msimamizi Mkuu'
              : cleanUser.split('@').first;
          _email = email;
          _phone = '+255 754 000 001';
          _department = 'Utawala wa Kanisa & Tehama';
          _jumuiya = 'Hekalu Kuu Sayuni';
          _isBaptized = true;
          await _persist();

          // The claim decides the role. `setUserRole` has to have run for this
          // account — see docs/FIREBASE_SETUP_OWNER.md.
          await _resolveFromFirebase();

          if (_source != RoleSource.cloud &&
              !ChurchRolePolicy.isPrivileged(_role) &&
              (allowlisted || demoAccessAllowed)) {
            _role = ChurchRole.admin;
            _source = RoleSource.device;
            await _persist();
          }
          notifyListeners();
          return _role.rank >= ChurchRole.admin.rank &&
              _source != RoleSource.none;
        }
      } catch (e) {
        debugPrint('Firebase Admin Login Error: $e');
      }
    }

    // Offline escape hatch: debug builds, or an explicit
    // `--dart-define=DEMO_MODE=true` build that supplies ADMIN_DEMO_PASSWORD.
    // A plain release build has no path to this branch.
    if (!demoAccessAllowed) return false;
    const demoPassword = String.fromEnvironment('ADMIN_DEMO_PASSWORD');
    if (!allowlisted || demoPassword.isEmpty || cleanPass != demoPassword) {
      return false;
    }

    _role = ChurchRole.admin;
    _source = RoleSource.demo;
    _isOnboarded = true;
    _name =
        cleanUser == 'admin' ? 'Msimamizi Mkuu' : cleanUser.split('@').first;
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

  Future<void> logout() async {
    _isOnboarded = false;
    _role = ChurchRole.guest;
    _source = RoleSource.none;
    _uid = null;
    _claimsChecked = false;
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Firebase signOut failed: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_is_onboarded', false);
    await _persist();
    notifyListeners();
  }

  /// Erases this device's copy of the member's personal data (PDPA 2022 right
  /// to erasure, device side). Server-side deletion of the Firebase user and of
  /// every Firestore document keyed to it is a Cloud Function and arrives in
  /// Phase 2 — until then this method must not be described to users as a full
  /// cloud erasure.
  Future<void> deleteAccount() async {
    _isOnboarded = false;
    _role = ChurchRole.guest;
    _source = RoleSource.none;
    _uid = null;
    _claimsChecked = false;
    _name = 'Mgeni Karibu';
    _phone = '';
    _email = '';
    _jumuiya = 'Ushirika wa Jumla';
    _department = 'Mgeni wa Ibada';
    _memberId = '';
    _isBaptized = false;

    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Firebase signOut during delete failed: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_is_onboarded');
      await prefs.remove('auth_user_role');
      await prefs.remove('auth_role_v2');
      await prefs.remove('auth_role_source');
      await prefs.remove('auth_uid');
      await prefs.remove('user_name');
      await prefs.remove('user_phone');
      await prefs.remove('user_email');
      await prefs.remove('user_jumuiya');
      await prefs.remove('user_dept');
      await prefs.remove('user_member_id');
      await prefs.remove('user_baptized');
      await prefs.setBool('auth_is_onboarded', false);
      await prefs.setString('auth_user_role', 'guest');
      await prefs.setString('auth_role_v2', ChurchRole.guest.wireName);
      await prefs.setString('auth_role_source', RoleSource.none.name);
    } catch (e) {
      debugPrint('Error erasing account data: $e');
    }

    notifyListeners();
  }

  /// PDPA 2022 erasure, done honestly: **cloud first**, then this device.
  ///
  /// The returned result describes only what really happened server-side; the
  /// device wipe always runs because the member asked for it and holding their
  /// data back would be its own breach. A server refusal (root account,
  /// phone-verified account, function not deployed) is surfaced verbatim.
  Future<RoleGrantResult> eraseAccount() async {
    RoleGrantResult cloud;
    if (hasCloudSession) {
      cloud = await ChurchRoleGrantService.deleteMyData();
    } else {
      cloud = const RoleGrantResult.fail(
        'Hakuna akaunti ya Firebase iliyowashwa kwenye kifaa hiki, kwa hivyo '
        'hakuna data ya kwenye wingu ya kufuta — zimefutwa ni za kifaa hiki pekee.',
      );
    }
    await deleteAccount();
    return cloud;
  }

  /// Leadership fast-entry for demos and local development.
  ///
  /// This is a **UI preview only**, unavailable in a normal release build. It
  /// used to hand out full admin rights from a single button tap with no
  /// authentication at all. It returns `false` when it refuses, so the caller
  /// can say so honestly instead of pretending the sign-in worked.
  Future<bool> loginAsLeader(String role) async {
    if (!demoAccessAllowed) return false;
    final mapped = ChurchRolePolicy.parse(role);
    if (mapped == null) return false;

    _isOnboarded = true;
    _role = mapped;
    _source = RoleSource.demo;
    _claimsChecked = false;
    _isBaptized = true;
    _phone = '+255 754 111 222';
    _jumuiya = 'Hekalu Kuu Sayuni';

    switch (role) {
      case 'pastor':
        _name = 'Askofu Messi Mgala';
        _email = 'pastor@zionjerusalem.org';
        _department = 'Uongozi Mkuu (Askofu)';
        _memberId = 'ZJC-LEAD-01';
      case 'secretary':
        _name = 'Katibu Mkuu Sayuni';
        _email = 'katibu@zionjerusalem.org';
        _department = 'Ofisi ya Katibu (Utawala)';
        _memberId = 'ZJC-LEAD-02';
      case 'treasurer':
        _name = 'Hazina Mkuu';
        _email = 'hazina@zionjerusalem.org';
        _department = 'Ofisi ya Hazina (Fedha)';
        _memberId = 'ZJC-LEAD-03';
      default:
        _department = mapped.titleSw;
    }

    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_is_onboarded', _isOnboarded);
      await prefs.setString('auth_role_v2', _role.wireName);
      await prefs.setString('auth_role_source', _source.name);
      // Legacy mirror of the old 3-value key, for anything still reading it.
      await prefs.setString('auth_user_role', role.name);
      final uid = _uid;
      if (uid != null) {
        await prefs.setString('auth_uid', uid);
      } else {
        await prefs.remove('auth_uid');
      }
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
