/// Single source of truth for every external address the app opens.
///
/// WHY THIS EXISTS
/// ---------------
/// The leadership portal URL used to be typed inline in two unrelated screens
/// (`profile_screen.dart` and the copilot service). Nothing tied those strings
/// together, so a domain change meant hunting through the app, and a typo in
/// one place silently produced a dead button on the leader's phone.
///
/// It can now also be overridden at build time without touching code:
///
///   flutter build apk --dart-define=PORTAL_BASE_URL=https://portal.example.org
///
/// That is the intended way to point a staging APK at a preview deployment.
class CoreLinks {
  CoreLinks._();

  /// Canonical production deployment of the leadership portal.
  ///
  /// This is the same host the APK already used, kept as the default so an
  /// existing build keeps working unchanged.
  static const String _defaultPortalBase = 'https://sayuni-portal.vercel.app';

  /// Build-time override; empty when not supplied.
  static const String _portalBaseOverride =
      String.fromEnvironment('PORTAL_BASE_URL');

  /// Base URL of the admin / leadership portal (no trailing slash).
  static String get portalBase {
    final raw = _portalBaseOverride.trim();
    final value = raw.isEmpty ? _defaultPortalBase : raw;
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  /// Where "Fungua Tovuti" / "Open Portal" sends a leader.
  static String get portalHome => '$portalBase/';

  /// The Copilot API lives in the same Vercel project as the portal.
  ///
  /// It is derived rather than hardcoded so that a build pointed at a preview
  /// deployment calls *that* deployment's API instead of production — the two
  /// used to drift apart and preview builds quietly burned production quota.
  static String get copilotEndpoint => '$portalBase/api/copilot';

  /// Human-readable host, for showing the leader where they are being sent.
  static String get portalHost {
    final uri = Uri.tryParse(portalBase);
    return uri?.host.isNotEmpty == true ? uri!.host : portalBase;
  }
}
