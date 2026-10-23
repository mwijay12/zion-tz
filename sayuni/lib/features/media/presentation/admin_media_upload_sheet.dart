import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/church_profile.dart';
import '../../../core/media/media_models.dart';
import '../../../core/media/media_upload_service.dart';
import '../../../core/services/cloudinary_media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';

/// A media record that reached Cloudinary and must now be published to the
/// church library (mobile catalogue + web portal bridge).
class PublishedMedia {
  const PublishedMedia({
    required this.id,
    required this.title,
    required this.preacher,
    required this.scripture,
    required this.duration,
    required this.type,
    required this.category,
    required this.description,
    required this.url,
  });

  final String id;
  final String title;
  final String preacher;
  final String scripture;
  final String duration;

  /// `'audio'` or `'video'` — matches `SermonMediaItem.type`.
  final String type;
  final String category;
  final String description;

  /// Verified `https://res.cloudinary.com/...` (or an admin-entered link).
  final String url;
}

/// Admin upload sheet for sermons, kwaya, tenzi and Bible audio.
///
/// Replaces the old sheet that "succeeded" by storing a device path. Flow is now
/// explicit: pick a real file → upload the bytes to Cloudinary → publish the
/// metadata only when a playable URL exists. Failures stay on screen with the
/// reason and a **Jaribu Tena** button.
class AdminMediaUploadSheet extends StatefulWidget {
  const AdminMediaUploadSheet({
    required this.onPublish,
    this.initialCategory = 'Mahubiri',
    super.key,
  });

  /// Persists the record (mobile catalogue + portal sync). Throwing here is
  /// surfaced to the admin; the sheet then stays open so nothing is lost.
  final Future<void> Function(PublishedMedia media) onPublish;
  final String initialCategory;

  static Future<PublishedMedia?> show(
    BuildContext context, {
    required Future<void> Function(PublishedMedia media) onPublish,
    String initialCategory = 'Mahubiri',
  }) {
    return showModalBottomSheet<PublishedMedia>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdminMediaUploadSheet(
        onPublish: onPublish,
        initialCategory: initialCategory,
      ),
    );
  }

  @override
  State<AdminMediaUploadSheet> createState() => _AdminMediaUploadSheetState();
}

enum _Phase { idle, picking, uploading, publishing }

class _AdminMediaUploadSheetState extends State<AdminMediaUploadSheet> {
  final _title = TextEditingController();
  final _preacher = TextEditingController();
  final _scripture = TextEditingController();
  final _duration = TextEditingController(text: '45 min');
  final _url = TextEditingController();
  final _description = TextEditingController();

  String _mediaType = 'audio';
  String _sourceMode = 'device';
  String _category = 'Mahubiri';

  String? _fileName;
  Uint8List? _bytes;
  String? _error;
  String? _errorHint;
  String _cloudinaryLabel = 'Cloudinary ya kanisa';
  bool _cloudinaryReady = true;

  _Phase _phase = _Phase.idle;
  Timer? _ticker;
  int _elapsedSeconds = 0;

  bool get _busy => _phase == _Phase.uploading || _phase == _Phase.publishing;

  int get _fileBytes => _bytes?.length ?? 0;

  String get _sizeLabel {
    final bytes = _fileBytes;
    if (bytes == 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get _elapsedLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _preacher.text = ChurchProfile.headBishop;
    _loadConfig();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _title.dispose();
    _preacher.dispose();
    _scripture.dispose();
    _duration.dispose();
    _url.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await CloudinaryConfig.load();
    if (!mounted) return;
    setState(() {
      _cloudinaryReady = config.isUsable;
      _cloudinaryLabel = config.label;
    });
  }

  void _startTicker() {
    _ticker?.cancel();
    _elapsedSeconds = 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _elapsedSeconds += 1);
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _clearError() {
    if (_error == null && _errorHint == null) return;
    setState(() {
      _error = null;
      _errorHint = null;
    });
  }

  void _fail(String message, {String? hint}) {
    _stopTicker();
    setState(() {
      _phase = _Phase.idle;
      _error = message;
      _errorHint = hint;
    });
  }

  // ---------------------------------------------------------------- pickers

  Future<void> _pickAudio() async {
    AppHaptics.lightImpact();
    setState(() {
      _phase = _Phase.picking;
      _error = null;
      _errorHint = null;
    });
    try {
      final picked = await FilePicker.platform.pickFiles(
        dialogTitle: 'Chagua rekodi ya sauti (mp3, m4a, aac, wav)',
        type: FileType.custom,
        allowedExtensions: const <String>['mp3', 'm4a', 'aac', 'wav', 'ogg'],
        withData: true,
        allowMultiple: false,
      );
      final file = picked?.files.firstOrNull;
      if (file == null) {
        if (mounted) setState(() => _phase = _Phase.idle);
        return;
      }
      final data = file.bytes ??
          (file.path == null ? null : await XFile(file.path!).readAsBytes());
      if (data == null || data.isEmpty) {
        _fail(
          'Hakwezi kusoma faili hili. Jaribu faili jingine au tumia kiungo.',
          hint: file.name,
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _phase = _Phase.idle;
        _mediaType = 'audio';
        _bytes = data;
        _fileName = file.name;
        if (_title.text.trim().isEmpty) {
          _title.text = _titleFromFileName(file.name);
        }
      });
    } catch (e) {
      _fail(
        'Haiwezekani kufungua kichagua faili cha kifaa hiki.',
        hint: '$e',
      );
    }
  }

  Future<void> _pickVideo() async {
    AppHaptics.lightImpact();
    setState(() {
      _phase = _Phase.picking;
      _error = null;
      _errorHint = null;
    });
    try {
      final XFile? file = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
      );
      if (file == null) {
        if (mounted) setState(() => _phase = _Phase.idle);
        return;
      }
      final data = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _phase = _Phase.idle;
        _mediaType = 'video';
        _bytes = data;
        _fileName = file.name;
        if (_title.text.trim().isEmpty) {
          _title.text = _titleFromFileName(file.name);
        }
      });
    } catch (e) {
      _fail('Haiwezekani kufungua maktaba ya video.', hint: '$e');
    }
  }

  String _titleFromFileName(String name) {
    final base = name.split(RegExp(r'[\\/]')).last.split('.').first;
    final cleaned = base.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (cleaned.isEmpty) return 'Rekodi mpya ya Sayuni';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  MediaCategory get _mediaCategory {
    final lower = _category.toLowerCase();
    if (lower.contains('kwaya')) return MediaCategory.choir;
    if (lower.contains('tenzi')) return MediaCategory.tenzi;
    if (lower.contains('biblia') || lower.contains('neno')) {
      return MediaCategory.bibleAudio;
    }
    return MediaCategory.sermons;
  }

  // ---------------------------------------------------------------- submit

  /// `'45 min'` -> `Duration(minutes: 45)`; unknown text simply means "unknown".
  Duration? get _parsedDuration {
    final match = RegExp(r'(\d+)').firstMatch(_duration.text);
    final minutes = match == null ? null : int.tryParse(match.group(1)!);
    if (minutes == null || minutes <= 0) return null;
    return Duration(minutes: minutes);
  }

  Future<void> _submit() async {
    if (_busy) return;
    AppHaptics.mediumImpact();

    final title = _title.text.trim();
    if (title.isEmpty) {
      _fail('Weka jina la rekodi kabla ya kupakia.');
      return;
    }

    // Link mode: the file is already hosted somewhere public, so there is
    // nothing to upload — publish that URL as given.
    if (_sourceMode == 'link') {
      final link = _url.text.trim();
      if (!link.startsWith('https://') && !link.startsWith('http://')) {
        _fail(
          'Kiungo lazima kiuanze na https://.',
          hint:
              'Mfano: https://res.cloudinary.com/zion-fellowship/.../hubiri.mp3',
        );
        return;
      }
      await _publish(
        id: 'admin-${DateTime.now().millisecondsSinceEpoch}',
        url: link,
      );
      return;
    }

    final bytes = _bytes;
    final name = _fileName;
    if (bytes == null || bytes.isEmpty || name == null) {
      _fail('Chagua faili ya sauti au video kwanza.');
      return;
    }
    if (bytes.length > CloudinaryMediaService.maxUploadBytes) {
      _fail(
        'Faili ni kubwa mno ($_sizeLabel). Upeo wa juu ni 200 MB — '
        'punguza saizi kwanza.',
      );
      return;
    }

    setState(() {
      _phase = _Phase.uploading;
      _error = null;
      _errorHint = null;
    });
    _startTicker();

    final request = MediaUploadRequest(
      title: title,
      category: _mediaCategory,
      filePath: name,
      artist: _preacher.text.trim(),
      description: _description.text.trim(),
      duration: _parsedDuration,
      bytes: bytes,
      isVideo: _mediaType == 'video',
    );

    try {
      final result = await MediaUploadService.cloudinary().submit(request);
      if (!mounted) return;
      _stopTicker();

      if (result.isSuccess && result.track != null) {
        final track = result.track!;
        if (!track.url.startsWith('http')) {
          // Defensive: a non-http URL can never play on a member's phone.
          _fail(
              'Cloudinary ilirudishi kiungo ambacho hakiwezi kucheza. Jaribu tena.');
          return;
        }
        await _publish(id: track.id, url: track.url);
        return;
      }

      if (result.isDraft) {
        // Nothing left the device. Say so instead of congratulating anyone.
        setState(() {
          _phase = _Phase.idle;
          _error = result.track?.subtitle ??
              'Rasimu imehifadhiwa kwenye simu tu — faili halijapakiwa mtandaoni.';
          _errorHint =
              'Washa Cloudinary kwenye Mipangilio ya Upakiaji, kisha ujaribu tena.';
        });
        return;
      }

      _fail(result.error ?? 'Upakiaji umeshindwa. Jaribu tena.');
    } on CloudinaryUploadException catch (e) {
      if (!mounted) return;
      _fail(e.message, hint: e.detail);
    } catch (e) {
      if (!mounted) return;
      _fail('Upakiaji umeshindwa kwa sababu isiyotarajiwa.', hint: '$e');
    }
  }

  /// Publishes a record that already has a playable URL.
  Future<void> _publish({required String id, required String url}) async {
    setState(() => _phase = _Phase.publishing);
    final media = PublishedMedia(
      id: id,
      title: _title.text.trim(),
      preacher: _preacher.text.trim(),
      scripture: _scripture.text.trim(),
      duration:
          _duration.text.trim().isEmpty ? '45 min' : _duration.text.trim(),
      type: _mediaType,
      category: _category,
      description: _description.text.trim(),
      url: url,
    );
    try {
      await widget.onPublish(media);
      if (!mounted) return;
      AppHaptics.heavyImpact();
      Navigator.pop(context, media);
    } catch (e) {
      if (!mounted) return;
      _fail(
        'Faili liko kwenye Cloudinary, lakini halijahifadhiwa kwenye maktaba ya kanisa.',
        hint: '$e',
      );
    }
  }

  // --------------------------------------------------------------- settings

  Future<void> _openSettings() async {
    final config = await CloudinaryConfig.load();
    if (!mounted) return;
    final cloudCtrl = TextEditingController(text: config.cloudName);
    final presetCtrl = TextEditingController(text: config.uploadPreset);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A2540), Color(0xFF0F3E7A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mipangilio ya Upakiaji',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cloud Name na Upload Preset ya kanisa hili. Preset lazima iwe '
                  'ya unsigned na iruhusu "Raw file uploads" kwa ajili ya sauti.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                const SizedBox(height: 14),
                _settingsField(cloudCtrl, 'Cloud Name', Icons.cloud_rounded),
                const SizedBox(height: 10),
                _settingsField(presetCtrl, 'Upload Preset', Icons.key_rounded),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await CloudinaryConfig.save(
                        cloudName: cloudCtrl.text,
                        uploadPreset: presetCtrl.text,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Hifadhi'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    cloudCtrl.dispose();
    presetCtrl.dispose();
    await _loadConfig();
  }

  Widget _settingsField(
      TextEditingController controller, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      child: TextField(
        controller: controller,
        cursorColor: AppColors.primaryLight,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: AppColors.primaryLight, fontSize: 12),
          prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, mq.viewInsets.bottom + 24),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A2540), Color(0xFF0F3E7A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 14),
              _buildTypeToggle(),
              const SizedBox(height: 12),
              _buildSourceToggle(),
              const SizedBox(height: 12),
              if (_sourceMode == 'device')
                _buildPickerCard()
              else
                _buildLinkField(),
              const SizedBox(height: 12),
              _buildField(_title, 'Jina la rekodi', Icons.title_rounded,
                  'Mf: Neno la Uhai',
                  autofocus: true),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildField(_preacher, 'Mhubiri / Msanii',
                        Icons.person_rounded, 'Mf: Askofu Mkuru'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                        _duration, 'Muda', Icons.schedule_rounded, '45 min'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildField(_scripture, 'Andiko',
                        Icons.menu_book_rounded, 'Mf: Yohana 3:16'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildCategoryDropdown()),
                ],
              ),
              const SizedBox(height: 10),
              _buildField(
                _description,
                'Maelezo (mridho)',
                Icons.notes_rounded,
                'Mf: Sehemu ya 3 ya mfululizo wa Yohana',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildStorageRow(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _buildErrorPanel(),
              ],
              const SizedBox(height: 16),
              _buildSubmitButton(),
              const SizedBox(height: 8),
              const Text(
                'Faili linapakiwa kwenye Cloudinary ya kanisa; maktaba ya waamini '
                'hupokea kiungo cha kweli. Hakuna kitu kinachohifadhiwa kwenye simu peke yake.',
                style: TextStyle(
                    color: Colors.white54, fontSize: 10.5, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.admin_panel_settings_rounded,
              color: AppColors.gold, size: 20),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pakia Sauti / Video Mpya',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                'Utawala • Cloudinary ya Sayuni',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _toggleChip({
    required bool selected,
    required String label,
    required IconData icon,
    required Color activeColor,
    required Color activeTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: activeTextColor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: activeTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    final audio = _mediaType == 'audio';
    return Row(
      children: [
        Expanded(
          child: _toggleChip(
            selected: audio,
            label: 'Sauti / Audio',
            icon: Icons.audiotrack_rounded,
            activeColor: AppColors.primary,
            activeTextColor: Colors.white,
            onTap: () {
              setState(() {
                _mediaType = 'audio';
                _bytes = null;
                _fileName = null;
              });
              _clearError();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _toggleChip(
            selected: !audio,
            label: 'Video ya Hubiri',
            icon: Icons.videocam_rounded,
            activeColor: AppColors.gold,
            activeTextColor: const Color(0xFF0A2540),
            onTap: () {
              setState(() {
                _mediaType = 'video';
                _bytes = null;
                _fileName = null;
              });
              _clearError();
            },
          ),
        ),
      ],
    );
  }

  Widget _sourceTab({
    required bool selected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: selected ? Colors.white : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceToggle() {
    final device = _sourceMode == 'device';
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _sourceTab(
              selected: device,
              label: 'Kutoka Kifaa',
              icon: Icons.folder_open_rounded,
              onTap: () => setState(() => _sourceMode = 'device'),
            ),
          ),
          Expanded(
            child: _sourceTab(
              selected: !device,
              label: 'Kiungo cha Mtandaoni',
              icon: Icons.link_rounded,
              onTap: () => setState(() => _sourceMode = 'link'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerCard() {
    final hasFile = _fileName != null && _fileBytes > 0;
    return GestureDetector(
      onTap: _busy
          ? null
          : () => _mediaType == 'audio' ? _pickAudio() : _pickVideo(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF162235),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                hasFile ? AppColors.gold : AppColors.primary.withOpacity(0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            if (_phase == _Phase.picking) ...[
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: AppColors.primaryLight),
              ),
              const SizedBox(height: 10),
              const Text(
                'Unafungua kichagua faili…',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ] else if (hasFile) ...[
              Row(
                children: [
                  Icon(
                    _mediaType == 'audio'
                        ? Icons.audio_file_rounded
                        : Icons.movie_rounded,
                    color: AppColors.gold,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                        Text(
                          '$_sizeLabel • tayari kupakiwa',
                          style: const TextStyle(
                              color: AppColors.primaryLight, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _bytes = null;
                      _fileName = null;
                    }),
                    child: const Text('Ondoa',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ),
            ] else ...[
              const Icon(Icons.cloud_upload_rounded,
                  color: AppColors.gold, size: 34),
              const SizedBox(height: 8),
              Text(
                _mediaType == 'audio'
                    ? 'Chagua faili ya sauti (mp3, m4a, aac, wav, ogg)'
                    : 'Chagua video (mp4, mov, webm)',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Maktaba ya simu au kadi ya microSD',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLinkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(_url, 'Kiungo cha sauti/video', Icons.link_rounded,
            'https://…/hubiri.mp3'),
        const SizedBox(height: 6),
        const Text(
          'Tumia kiungo kama faili liko tayari kwenye Cloudinary, YouTube '
          'au seva yako. Hakikisha linaweza kucheza moja kwa moja.',
          style: TextStyle(color: Colors.white54, fontSize: 10.5, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon,
    String hint, {
    int maxLines = 1,
    bool autofocus = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        autofocus: autofocus,
        cursorColor: AppColors.primaryLight,
        style: const TextStyle(
            color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: AppColors.primaryLight, fontSize: 12),
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
          prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF162235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
      ),
      child: DropdownButton<String>(
        value: _category,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: const Color(0xFF0F3E7A),
        icon: const Icon(Icons.expand_more_rounded, color: Colors.white70),
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        items: const [
          'Mahubiri',
          'Mafundisho',
          'Kwaya',
          'Tenzi',
          'Biblia',
          'Podcasts'
        ]
            .map((c) => DropdownMenuItem<String>(
                  value: c,
                  child: Row(
                    children: [
                      const Icon(Icons.category_rounded,
                          color: AppColors.primaryLight, size: 16),
                      const SizedBox(width: 8),
                      Text(c),
                    ],
                  ),
                ))
            .toList(),
        onChanged: _busy
            ? null
            : (value) {
                if (value != null) setState(() => _category = value);
              },
      ),
    );
  }

  Widget _buildStorageRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _cloudinaryReady
              ? AppColors.primaryLight.withOpacity(0.35)
              : AppColors.error.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _cloudinaryReady
                ? Icons.cloud_done_rounded
                : Icons.cloud_off_rounded,
            size: 18,
            color: _cloudinaryReady ? AppColors.primaryLight : AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cloudinaryReady
                      ? 'Cloudinary iko tayari'
                      : 'Cloudinary haijapangwa',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
                Text(
                  _cloudinaryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mipangilio ya Upakiaji',
            onPressed: _busy ? null : _openSettings,
            icon: const Icon(Icons.tune_rounded,
                color: AppColors.primaryLight, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.35),
                ),
              ),
            ],
          ),
          if (_errorHint != null && _errorHint!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _errorHint!,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10.5,
                  height: 1.35),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Jaribu Tena',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: _clearError,
                child: const Text('Futa',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final uploading = _phase == _Phase.uploading;
    final publishing = _phase == _Phase.publishing;
    final label = uploading
        ? 'Inapakia kwenye Cloudinary… ($_sizeLabel · $_elapsedLabel)'
        : publishing
            ? 'Inahifadhiwa kwenye maktaba…'
            : _sourceMode == 'link'
                ? 'Hifadhi kwenye maktaba'
                : 'Pakia kwenye Cloudinary';
    final ready = _sourceMode == 'link'
        ? _url.text.trim().isNotEmpty
        : _fileName != null && _fileBytes > 0;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: (_busy || !ready) ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.cloud_upload_rounded),
        label: Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        ),
      ),
    );
  }
}
