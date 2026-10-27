import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One lawful-processing purpose under PDPA 2022 (Tanzania).
class PdpaPurpose {
  const PdpaPurpose({
    required this.key,
    required this.labelSw,
    required this.labelEn,
    required this.required,
    required this.basis,
  });

  final String key;
  final String labelSw;
  final String labelEn;

  /// `true` = the feature cannot legally run without it, so it is always
  /// recorded as accepted when the member registers (contract basis).
  final bool required;

  /// Short Swahili explanation of *why* the data is needed.
  final String basis;
}

/// A single consent decision. Records are never overwritten: withdrawal adds a
/// timestamp, so the church can still prove what was agreed and when.
class PdpaConsentRecord {
  const PdpaConsentRecord({
    required this.version,
    required this.purposes,
    required this.at,
    required this.method,
    this.withdrawnAt,
  });

  final String version;
  final List<String> purposes;
  final DateTime at;
  final String method;
  final DateTime? withdrawnAt;

  bool get isActive => withdrawnAt == null;

  Map<String, dynamic> toJson() => {
        'version': version,
        'purposes': purposes,
        'acceptedAt': at.toUtc().toIso8601String(),
        'method': method,
        if (withdrawnAt != null) 'withdrawnAt': withdrawnAt!.toUtc().toIso8601String(),
      };

  factory PdpaConsentRecord.fromJson(Map<String, dynamic> j) =>
      PdpaConsentRecord(
        version: j['version']?.toString() ?? '',
        purposes: (j['purposes'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[],
        at: DateTime.tryParse(j['acceptedAt']?.toString() ?? '') ??
            DateTime.fromMicrosecondsSinceEpoch(0),
        method: j['method']?.toString() ?? 'unknown',
        withdrawnAt: DateTime.tryParse(j['withdrawnAt']?.toString() ?? ''),
      );
}

/// Consent register + data subject rights helper for the local device.
///
/// PDPA 2022 requires the church to (a) state a lawful basis, (b) be able to
/// prove what a member agreed to, (c) let a member access their data, and
/// (d) let them withdraw consent. All four live here; the cloud half of (c)
/// and (d) is `functions/exportMyData` / `functions/deleteMyData`.
///
/// Deliberately **non-blocking**: consent state is read from local storage, so
/// opening the app never waits on the network (principle K1).
class PdpaService extends ChangeNotifier {
  PdpaService._internal();
  static final PdpaService _instance = PdpaService._internal();
  factory PdpaService() => _instance;

  /// Bump this whenever the privacy text changes — every member is then asked
  /// to re-consent once, which is what the law expects for a new purpose.
  static const String consentVersion = '2026.2';

  static const String _prefsKey = 'pdpa_consent_v1';

  static const List<PdpaPurpose> purposes = [
    PdpaPurpose(
      key: 'membership',
      labelSw: 'Usajili na mdau wa uanachama',
      labelEn: 'Membership registration and roll',
      required: true,
      basis:
          'Kanisa linahitaji jina, simu na jumuiya yako ili kukuhifadhi kwenye '
          'orodha ya waumini na kukupa Member ID.',
    ),
    PdpaPurpose(
      key: 'contact',
      labelSw: 'Mawasiliano ya kiimani (simu / SMS / email)',
      labelEn: 'Church contact calls, SMS and email',
      required: false,
      basis:
          'Kukukumbusha ibada, maandalizi na miradi. Unaweza kuondoka wakati '
          'wowote bila kuathiri uanachama wako.',
    ),
    PdpaPurpose(
      key: 'prayer',
      labelSw: 'Kushikilia maombi uliyoweka na matokeo yake',
      labelEn: 'Storing your prayer requests and follow-up',
      required: false,
      basis:
          'Ili desk ya wachangaji iweze kuomba na kukufuatilia. Maombi yanabaki '
          'ya siri na hayaonyeshwa kwa umma.',
    ),
    PdpaPurpose(
      key: 'giving',
      labelSw: 'Rekodi za mapato na utoaji (Katibu / Mhodini)',
      labelEn: 'Giving and income records (Secretary / Treasurer)',
      required: true,
      basis:
          'Rekodi za fedha lazima zihifadhiwe kwa miaka kulingana na sheria za '
          'nchi na ukaguzi wa kanisa. Hazifutwi kwa ombi la mtu binafsi.',
    ),
    PdpaPurpose(
      key: 'media',
      labelSw: 'Picha, sauti na video za ibada',
      labelEn: 'Worship photos, audio and video',
      required: false,
      basis:
          'Ibada huguliwa na kuwekwa kwenye Cloudinary kwa ajili ya mahubiri. '
          'Kama hupati ruhusa, tafadhali mfotografiani mwengine.',
    ),
  ];

  final List<PdpaConsentRecord> _history = <PdpaConsentRecord>[];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<PdpaConsentRecord> get history => List.unmodifiable(_history);

  /// The newest record that is still active, or null.
  PdpaConsentRecord? get active {
    for (final r in _history.reversed) {
      if (r.isActive) return r;
    }
    return null;
  }

  /// True only when the *current* policy version has been accepted.
  bool get hasCurrentConsent =>
      active != null && active!.version == consentVersion;

  List<String> get activePurposes => active?.purposes ?? const <String>[];

  bool isAccepted(String purposeKey) {
    final p = purposes.firstWhere((e) => e.key == purposeKey,
        orElse: () => purposes.first);
    return p.required || activePurposes.contains(purposeKey);
  }

  Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        _history.addAll(list
            .map((e) => PdpaConsentRecord.fromJson(
                (e as Map).cast<String, dynamic>())));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('PdpaService.init failed (starting empty): $e');
    }
  }

  /// Records a consent decision. Required purposes are always included, so a
  /// member cannot accidentally "consent to nothing" and then be enrolled.
  Future<void> record(Iterable<String> chosen,
      {String method = 'onboarding_form'}) async {
    final set = <String>{
      ...purposes.where((p) => p.required).map((p) => p.key),
      ...chosen,
    };
    _history.add(PdpaConsentRecord(
      version: consentVersion,
      purposes: set.toList()..sort(),
      at: DateTime.now(),
      method: method,
    ));
    await _save();
  }

  /// Replaces the active decision (withdrawal is appended, never edited).
  Future<void> updatePurposes(Iterable<String> chosen) =>
      record(chosen, method: 'settings_toggle');

  /// Withdraws every optional purpose. Membership and financial records stay,
  /// because their basis is the church-membership contract and the statutory
  /// accounting duty — saying otherwise would be a false promise.
  Future<void> withdrawAll() async {
    final stillValid = active;
    if (stillValid == null) return;
    _history[_history.lastIndexOf(stillValid)] = PdpaConsentRecord(
      version: stillValid.version,
      purposes: stillValid.purposes,
      at: stillValid.at,
      method: stillValid.method,
      withdrawnAt: DateTime.now(),
    );
    _history.add(PdpaConsentRecord(
      version: consentVersion,
      purposes: purposes.where((p) => p.required).map((p) => p.key).toList()
        ..sort(),
      at: DateTime.now(),
      method: 'withdrawal_baseline',
    ));
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_history.map((e) => e.toJson()).toList()),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('PdpaService.save failed: $e');
    }
  }

  /// Appends the newest consent decision to the church register in Firestore.
  ///
  /// The device register is the primary copy (the app must never block on the
  /// network), but proof that survives a lost phone has to live on the server,
  /// and `firestore.rules` accepts only append-only writes made by the signed-in
  /// owner. Best effort with a hard timeout: anything wrong returns false and
  /// the caller says out loud that only the device copy was written.
  Future<bool> mirrorActiveToCloud(String uid) async {
    final r = active;
    if (r == null || uid.isEmpty) return false;
    try {
      await FirebaseFirestore.instance
          .collection('consent_records')
          .add(<String, Object?>{
        'uid': uid,
        'version': r.version,
        'purposes': r.purposes,
        'method': r.method,
        'acceptedAt': Timestamp.fromDate(r.at),
        'deviceRecordedAt': r.at.toUtc().toIso8601String(),
        'withdrawnAt':
            r.withdrawnAt == null ? null : Timestamp.fromDate(r.withdrawnAt!),
      }).timeout(const Duration(seconds: 12));
      return true;
    } catch (e) {
      debugPrint('PdpaService cloud mirror skipped: $e');
      return false;
    }
  }

  /// Truthful processor register. Anything listed here really is contacted by
  /// this app; nothing is claimed that the code does not do.
  static const List<Map<String, String>> dataInventory = [
    {
      'who': 'Kanisa la Zion Jerusalem (dhibiti)',
      'whoEn': 'Zion Jerusalem Church (data controller)',
      'where': 'Firestore / Firebase',
      'whereEn': 'Cloud Firestore / Firebase',
      'what': 'Jina, simu, email, jumuiya, Member ID, maombi, rekodi za mapato',
      'whatEn': 'Name, phone, email, cell group, Member ID, prayer requests, income records',
      'why': 'Usimamizi wa wanachama, mali na mapato ya kanisa',
      'whyEn': 'Member, church-property and church-income administration',
    },
    {
      'who': 'Google (Firebase Auth + Firestore)',
      'whoEn': 'Google (Firebase Auth + Firestore)',
      'where': 'Nje ya nchi (data centre ya Google)',
      'whereEn': 'Outside Tanzania (Google data centre)',
      'what': 'Token ya kuingia, UID, role claim, nyaraka za database',
      'whatEn': 'Sign-in token, UID, role claim, database documents',
      'why': 'Kuthibitisha mtu na kuhifadhi data kwa usalama',
      'whyEn': 'Verifying who you are and storing records securely',
    },
    {
      'who': 'Cloudinary',
      'whoEn': 'Cloudinary',
      'where': 'Nje ya nchi (media CDN)',
      'whereEn': 'Outside Tanzania (media CDN)',
      'what': 'Sauti za mahubiri, video, picha za idara',
      'whatEn': 'Sermon audio, video and department photos',
      'why': 'Kushikilia na kusambaza nyenzo za ibada',
      'whyEn': 'Hosting and delivering worship media',
    },
    {
      'who': 'radio-browser.info',
      'whoEn': 'radio-browser.info',
      'where': 'Wavuti',
      'whereEn': 'Web',
      'what': 'Hakuna data yako — orodha ya vituo vya redio pekee',
      'whatEn': 'None of your data — station lists only',
      'why': 'Kupa waumini vituo vya kiimani',
      'whyEn': 'Providing believers with faith stations',
    },
    {
      'who': 'Google Gemini (portal ya wasimamizi tu)',
      'whoEn': 'Google Gemini (admin portal only)',
      'where': 'Wavuti',
      'whereEn': 'Web',
      'what': 'Maandishi ya muhtasari wa mahubiri yanayotumwa kuulizwa',
      'whatEn': 'Sermon summary text that is submitted for processing',
      'why': 'Kutoa muhtasari na tafsiri ya mahubiri',
      'whyEn': 'Producing sermon summaries and translations',
    },
    {
      'who': 'Wahudumiaji wa Lipa Namba (Vodacom/MiGAi/CRDB)',
      'whoEn': 'Lipa Namba providers (Vodacom / MiGAi / CRDB)',
      'where': 'Nje ya programu',
      'whereEn': 'Outside the app',
      'what': 'Jina/lipa namba na kiasi — PIN HAIPO kabisa',
      'whatEn': 'Name / lipa namba and amount — never a PIN',
      'why': 'Kupokea aseli na michango',
      'whyEn': 'Receiving tithes and offerings',
    },
  ];

  /// Every value this device holds about this user. Long blobs are replaced by a
  /// size note so the file stays readable; nothing is silently skipped.
  Future<Map<String, Object?>> rawDeviceData() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, Object?>{};
    for (final k in prefs.getKeys()) {
      final v = prefs.get(k);
      out[k] = (v is String && v.length > 20000)
          ? '<<maudhui marefu: ${v.length} chars — iko kwenye kifaa hiki>>'
          : v;
    }
    return out;
  }

  /// The DSAR answer for this device. [identity] is passed in by the caller so
  /// this service stays independent of the auth singleton; [cloud] is whatever
  /// `functions/exportMyData` returned (empty until the owner deploys it).
  Future<String> exportJson({
    Map<String, dynamic> identity = const <String, dynamic>{},
    Map<String, dynamic> cloud = const <String, dynamic>{},
  }) async {
    final body = <String, dynamic>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'dataController': 'Kanisa la Njia Nyembamba (Zion Jerusalem)',
      'law': 'Tanzania Personal Data Protection Act, 2022',
      'policyVersion': consentVersion,
      'identity': identity,
      'consentRecords': _history.map((e) => e.toJson()).toList(),
      'deviceData': await rawDeviceData(),
      'cloudData': cloud,
      'processors': dataInventory,
      'notes': cloud.isEmpty
          ? 'cloudData haina kitu kwa sababu functions/exportMyData bado haijawekwa '
              'kwenye Firebase. Data yote yaliyo hapa yanatoka kwenye kifaa hiki.'
          : 'cloudData imetoka kwenye Firebase wakati wa ombi hili.',
    };
    return const JsonEncoder.withIndent('  ').convert(body);
  }
}
