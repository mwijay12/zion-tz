import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

import 'package:sayuni/firebase_options.dart';
import 'church_role_policy.dart';

/// Result of a call to the role functions. Never a silent "success".
class RoleGrantResult {
  const RoleGrantResult._({
    required this.success,
    required this.message,
    this.appliedRole,
    this.previousRole,
    this.viaCloud = false,
  });

  const RoleGrantResult.ok({
    String? message,
    String? appliedRole,
    String? previousRole,
    bool viaCloud = true,
  }) : this._(
          success: true,
          message: message ?? 'Imefanyika.',
          appliedRole: appliedRole,
          previousRole: previousRole,
          viaCloud: viaCloud,
        );

  const RoleGrantResult.fail(String message, {bool viaCloud = false})
      : this._(success: false, message: message, viaCloud: viaCloud);

  final bool success;
  final String message;
  final String? appliedRole;
  final String? previousRole;

  /// `true` = Firebase Auth now really holds this role. `false` = only this
  /// device's demo allowlist changed, which is explicitly *not* authority.
  final bool viaCloud;
}

/// Client for the Cloud Functions that own church roles.
///
/// Firebase *callable* endpoints are plain HTTPS endpoints that speak
/// `{"data": …}` / `{"result": …}`. Calling them with `package:http` and the
/// user's own ID token keeps `cloud_functions` out of the web bundle; the token
/// is what the server trusts, so nothing about this file grants privilege —
/// only `functions/index.js` does.
///
/// Authority chain, end to end:
///   app → ID token (signed by Firebase Auth) → `request.auth.token.role`
///       checked in `functions/index.js` → `setCustomUserClaims` → the same
///       token field read by `firestore.rules`.
class ChurchRoleGrantService {
  const ChurchRoleGrantService._();

  /// Must match `REGION` in functions/index.js. Override at build time without
  /// touching code: `flutter build web --dart-define=FUNCTIONS_REGION=us-central1`.
  static const String region =
      String.fromEnvironment('FUNCTIONS_REGION', defaultValue: 'africa-south1');

  /// Project the callable belongs to — the same options the app boots Firebase
  /// with, so a project swap can never leave the app calling another project.
  static String get projectId =>
      DefaultFirebaseOptions.currentPlatform.projectId;

  static String endpoint(String functionName) =>
      'https://$region-$projectId.cloudfunctions.net/$functionName';

  static const Duration _timeout = Duration(seconds: 20);

  static Future<String?> _idToken({bool forceRefresh = true}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final result =
          await user.getIdTokenResult(forceRefresh).timeout(_timeout);
      return result.token;
    } catch (e) {
      debugPrint('ChurchRoleGrantService: no ID token ($e)');
      return null;
    }
  }

  /// `setUserRole` — gives a real Firebase custom claim. Admin/super_admin only.
  static Future<RoleGrantResult> setUserRole({
    String? targetEmail,
    String? targetUid,
    required ChurchRole role,
    String? branch,
    String? memberId,
    String? reason,
  }) async {
    return _call('setUserRole', {
      if (targetEmail != null) 'targetEmail': targetEmail.trim().toLowerCase(),
      if (targetUid != null) 'targetUid': targetUid,
      'role': role.wireName,
      if (branch != null && branch.trim().isNotEmpty) 'branch': branch.trim(),
      if (memberId != null && memberId.trim().isNotEmpty)
        'memberId': memberId.trim(),
      'reason': (reason == null || reason.trim().isEmpty)
          ? 'Kupewa mamlaka kupitia programu ya Sayuni'
          : reason.trim(),
    });
  }

  /// `revokeUserRole` — drops the account back to `member`.
  static Future<RoleGrantResult> revokeUserRole({
    String? targetEmail,
    String? targetUid,
    String? reason,
  }) async {
    return _call('revokeUserRole', {
      if (targetEmail != null) 'targetEmail': targetEmail.trim().toLowerCase(),
      if (targetUid != null) 'targetUid': targetUid,
      'reason': (reason == null || reason.trim().isEmpty)
          ? 'Kuondolewa mamlaka kupitia programu ya Sayuni'
          : reason.trim(),
    });
  }

  /// What the server believes about the signed-in account. Read-only, no
  /// privilege, and the fastest way to confirm that claims are live.
  static Future<Map<String, dynamic>?> myClaims() async {
    final token = await _idToken();
    if (token == null) return null;
    try {
      final res = await http
          .post(
            Uri.parse(endpoint('myClaims')),
            headers: _headers(token),
            body: jsonEncode({'data': {}}),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['result'] as Map?)?.cast<String, dynamic>();
    } catch (e) {
      debugPrint('ChurchRoleGrantService.myClaims failed: $e');
      return null;
    }
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Firebase-Client-Request-Id':
            'zion-${DateTime.now().microsecondsSinceEpoch}',
      };

  static Future<RoleGrantResult> _call(
      String fn, Map<String, dynamic> data) async {
    final token = await _idToken();
    if (token == null) {
      return const RoleGrantResult.fail(
        'Hakuna akaunti ya Firebase iliyowasha kwenye kifaa hiki, kwa hivyo '
        'server haiwezi kuthibitisha role yako. Ingia kwa barua pepe kwanza.',
      );
    }

    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse(endpoint(fn)),
            headers: _headers(token),
            body: jsonEncode({'data': data}),
          )
          .timeout(_timeout);
    } on TimeoutException {
      return RoleGrantResult.fail(
        'Server haijajibu ndani ya sekunde ${_timeout.inSeconds}. Angalia mtandao '
        'kisha ujaribu tena — mabadiliko hayajafanyika.',
      );
    } catch (e) {
      return RoleGrantResult.fail(
        'Imeshindikana kufikia functions/$fn: $e',
      );
    }

    Map<String, dynamic>? body;
    try {
      body = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    } catch (_) {
      body = null;
    }

    if (res.statusCode == 200 && body != null && body['result'] is Map) {
      final r = (body['result'] as Map).cast<String, dynamic>();
      return RoleGrantResult.ok(
        message: 'Imehifadhiwa kwenye Firebase Auth (si kifaa hiki peke yake): '
            '"${r['previousRole'] ?? 'hakuna'}" → "${r['role']}" kwa '
            '${r['email'] ?? data['targetEmail'] ?? 'mtumiaji huyo'}. '
            'Anahitaji kufunga na kufungua programu ili claim mpya ifike.',
        appliedRole: r['role']?.toString(),
        previousRole: r['previousRole']?.toString(),
      );
    }

    // Callable error envelope: {"error":{"message":…,"status":…,"details":…}}
    String message = '';
    if (body?['error'] is Map) {
      final err = (body!['error'] as Map).cast<String, dynamic>();
      message = (err['message'] ?? err['status'] ?? '').toString();
    }
    if (message.isEmpty) {
      message =
          'HTTP ${res.statusCode}: ${res.body.length > 180 ? '${res.body.substring(0, 180)}…' : res.body}';
    }
    if (kDebugMode) debugPrint('ChurchRoleGrantService.$fn → $message');
    return RoleGrantResult.fail(message);
  }
}
