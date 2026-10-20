import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/services/church_audio_service.dart';
import '../../../core/services/church_auth_service.dart';
import '../../../core/services/church_sync_service.dart';
import '../../../core/services/cloudinary_media_service.dart';
import '../../../core/services/church_customization_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../notes/presentation/notes_screen.dart';
import '../../choir/presentation/choir_screen.dart';
import 'online_radio_screen.dart';
import '../../../core/services/radio_browser_service.dart';

class SermonMediaItem {
  final String id;
  final String title;
  final String preacher;
  final String scripture;
  final String date;
  final String duration;
  final String type; // 'video' | 'audio'
  final String category; // 'Mahubiri' | 'Mafundisho' | 'Kwaya' | 'Podcasts'
  final String description;
  final String imageUrl;
  final String audioUrl;
  final String videoUrl;
  final bool isAdminUpload;

  const SermonMediaItem({
    required this.id,
    required this.title,
    required this.preacher,
    required this.scripture,
    required this.date,
    required this.duration,
    required this.type,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.audioUrl = 'https://stream.zeno.fm/4v4e91y9sm8uv',
    this.videoUrl = '',
    this.isAdminUpload = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'preacher': preacher,
    'scripture': scripture,
    'date': date,
    'duration': duration,
    'type': type,
    'category': category,
    'description': description,
    'imageUrl': imageUrl,
    'audioUrl': audioUrl,
    'videoUrl': videoUrl,
    'isAdminUpload': isAdminUpload,
  };

  factory SermonMediaItem.fromJson(Map<String, dynamic> json) => SermonMediaItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    preacher: json['preacher']?.toString() ?? '',
    scripture: json['scripture']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    duration: json['duration']?.toString() ?? '45 min',
    type: json['type']?.toString() ?? 'video',
    category: json['category']?.toString() ?? 'Mahubiri',
    description: json['description']?.toString() ?? '',
    imageUrl: json['imageUrl']?.toString() ?? 'assets/images/church_front.jpg',
    audioUrl: json['audioUrl']?.toString() ?? 'https://stream.zeno.fm/4v4e91y9sm8uv',
    videoUrl: json['videoUrl']?.toString() ?? '',
    isAdminUpload: json['isAdminUpload'] == true,
  );
}

class MediaHubScreen extends StatefulWidget {
  const MediaHubScreen({super.key});

  @override
  State<MediaHubScreen> createState() => _MediaHubScreenState();
}

class _MediaHubScreenState extends State<MediaHubScreen> {
  String _selectedCategory = 'Yote';
  String _searchQuery = '';

  final List<String> _categories = [
    'Yote',
    'Radio za Injili',
    'Mahubiri',
    'Mafundisho',
    'Kwaya & Sifa',
    'Podcasts',
  ];

  List<SermonMediaItem> _customSermons = [];
  final ChurchAuthService _auth = ChurchAuthService();

  @override
  void initState() {
    super.initState();
    _auth.addListener(_handleAuthChange);
    _loadSavedCustomSermons();
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChange);
    super.dispose();
  }

  void _handleAuthChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSavedCustomSermons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('zion_admin_uploaded_media');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        setState(() {
          _customSermons = decoded
              .map((e) => SermonMediaItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        });
      }
      final customService = ChurchCustomizationService();
      await customService.init();
      if (customService.customSermons.isNotEmpty) {
        final synced = customService.customSermons.map((cs) => SermonMediaItem(
          id: cs.id,
          title: cs.title,
          preacher: cs.preacher,
          scripture: cs.scripture,
          date: 'Ibada ya Sayuni',
          duration: cs.duration,
          type: cs.type,
          category: cs.category,
          description: 'Ujumbe wa kiroho kutoka Hekalu Kuu la Sayuni.',
          imageUrl: cs.thumbnailUrl ?? 'assets/images/church_front.jpg',
          audioUrl: cs.type == 'audio' ? cs.mediaUrl : 'https://stream.zeno.fm/4v4e91y9sm8uv',
          videoUrl: cs.type == 'video' ? cs.mediaUrl : '',
          isAdminUpload: true,
        )).toList();
        for (final s in synced) {
          if (!_customSermons.any((existing) => existing.id == s.id)) {
            _customSermons.add(s);
          }
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading custom sermons: $e');
    }
  }

  Future<void> _saveCustomSermons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_customSermons.map((e) => e.toJson()).toList());
      await prefs.setString('zion_admin_uploaded_media', encoded);
    } catch (e) {
      debugPrint('Error saving custom sermons: $e');
    }
  }

  List<SermonMediaItem> get _allSermons => _customSermons;

  List<SermonMediaItem> get _filteredSermons {
    return _allSermons.where((item) {
      final matchesCategory = _selectedCategory == 'Yote' ||
          item.category == _selectedCategory ||
          (_selectedCategory == 'Kwaya & Sifa' && item.category == 'Kwaya');
      final matchesQuery = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.preacher.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.scripture.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Widget _buildAdminField(
    TextEditingController controller,
    String label,
    IconData icon,
    String hint, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        cursorColor: AppColors.primaryLight,
        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF162235),
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.primaryLight, fontSize: 12),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
          prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }

  void _showAdminUploadVideoDialog() {
    AppHaptics.mediumImpact();
    final titleCtrl = TextEditingController();
    final preacherCtrl = TextEditingController(text: ChurchProfile.headBishop);
    final scriptureCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '45 min');
    final descCtrl = TextEditingController();
    String mediaType = 'video';
    String category = 'Mahubiri';
    String sourceMode = 'gallery'; // 'gallery' | 'link'
    XFile? pickedVideo;
    String? pickedVideoName;
    bool isPicking = false;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.gold, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ongeza Video / Hubiri Jipya',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Sehemu ya Administrator • Maktaba ya Simu au Kiungo',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Media Type Selector (Video vs Audio)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => mediaType = 'video'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: mediaType == 'video' ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: mediaType == 'video' ? Colors.white : Colors.white24,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text('Video ya Hubiri', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => mediaType = 'audio'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: mediaType == 'audio' ? AppColors.gold : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: mediaType == 'audio' ? Colors.white : Colors.white24,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.audiotrack_rounded, color: mediaType == 'audio' ? const Color(0xFF0A2540) : Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sauti / Audio',
                                      style: TextStyle(
                                        color: mediaType == 'audio' ? const Color(0xFF0A2540) : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Dual Source Selector: Gallery / Device Library vs Online Link
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => sourceMode = 'gallery'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sourceMode == 'gallery' ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.video_library_rounded,
                                        size: 16,
                                        color: sourceMode == 'gallery' ? Colors.white : Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Kutoka Maktaba (Library)',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: sourceMode == 'gallery' ? FontWeight.bold : FontWeight.normal,
                                          color: sourceMode == 'gallery' ? Colors.white : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => sourceMode = 'link'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sourceMode == 'link' ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.link_rounded,
                                        size: 16,
                                        color: sourceMode == 'link' ? Colors.white : Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Kiungo cha Mtandaoni (Link)',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: sourceMode == 'link' ? FontWeight.bold : FontWeight.normal,
                                          color: sourceMode == 'link' ? Colors.white : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Device Library Upload Picker Card
                      if (sourceMode == 'gallery')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF162235),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: pickedVideo != null
                                  ? AppColors.gold
                                  : AppColors.primary.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (pickedVideo == null) ...[
                                const Icon(Icons.cloud_upload_rounded, color: AppColors.gold, size: 36),
                                const SizedBox(height: 8),
                                const Text(
                                  'Chagua Video Kutoka Maktaba ya Simu yako',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Inasaidia faili za MP4, MOV au WebM kutoka gallery',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: isPicking
                                      ? null
                                      : () async {
                                          AppHaptics.lightImpact();
                                          setModalState(() => isPicking = true);
                                          try {
                                            final picker = ImagePicker();
                                            final XFile? file = await picker.pickVideo(
                                              source: ImageSource.gallery,
                                            );
                                            if (file != null) {
                                              setModalState(() {
                                                pickedVideo = file;
                                                pickedVideoName = file.name;
                                                urlCtrl.text = file.path;
                                              });
                                            }
                                          } catch (e) {
                                            debugPrint('Video pick error: $e');
                                          } finally {
                                            setModalState(() => isPicking = false);
                                          }
                                        },
                                  icon: isPicking
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.video_collection_rounded, size: 18),
                                  label: Text(isPicking ? 'Inafungua Maktaba...' : 'Fungua Maktaba ya Kifaa'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Video Imechaguliwa Kutoka Maktaba!',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            pickedVideoName ?? 'video.mp4',
                                            style: const TextStyle(
                                              color: AppColors.gold,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        AppHaptics.lightImpact();
                                        try {
                                          final picker = ImagePicker();
                                          final XFile? file = await picker.pickVideo(
                                            source: ImageSource.gallery,
                                          );
                                          if (file != null) {
                                            setModalState(() {
                                              pickedVideo = file;
                                              pickedVideoName = file.name;
                                              urlCtrl.text = file.path;
                                            });
                                          }
                                        } catch (_) {}
                                      },
                                      child: const Text('Badili', style: TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        _buildAdminField(
                          urlCtrl,
                          'URL ya Video / Audio (YouTube / Cloudinary / MP4)',
                          Icons.link_rounded,
                          'https://www.youtube.com/watch?v=... au https://res.cloudinary.com/...',
                        ),

                      const SizedBox(height: 10),

                      // Input Fields
                      _buildAdminField(titleCtrl, 'Kichwa cha Hubiri / Somo', Icons.title_rounded, 'Mf. Nuru ya Sayuni Inang\'aa'),
                      const SizedBox(height: 10),
                      _buildAdminField(preacherCtrl, 'Mhubiri / Mtumishi', Icons.person_rounded, 'Askofu Messi Mgala'),
                      const SizedBox(height: 10),
                      _buildAdminField(scriptureCtrl, 'Mstari wa Biblia', Icons.menu_book_rounded, 'Isaya 60:1-3'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAdminField(durationCtrl, 'Muda', Icons.timer_rounded, '45 min'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: category,
                                  dropdownColor: const Color(0xFF0F2644),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  isExpanded: true,
                                  items: ['Mahubiri', 'Mafundisho', 'Kwaya', 'Podcasts'].map((c) {
                                    return DropdownMenuItem(value: c, child: Text(c));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => category = val);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildAdminField(descCtrl, 'Maelezo ya Hubiri', Icons.description_rounded, 'Ujumbe wa ukombozi kutoka Sayuni...', maxLines: 2),
                      const SizedBox(height: 18),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final title = titleCtrl.text.trim();
                            final url = urlCtrl.text.trim();
                            if (title.isEmpty) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Tafadhali weka Kichwa cha Hubiri')),
                              );
                              return;
                            }
                            if (sourceMode == 'gallery' && pickedVideo == null && url.isEmpty) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Tafadhali chagua video kutoka kwenye maktaba ya simu yako')),
                              );
                              return;
                            }

                            String finalVideoUrl = url;
                            if (sourceMode == 'gallery' && pickedVideo != null) {
                              setModalState(() => isUploading = true);
                              try {
                                final bytes = await pickedVideo!.readAsBytes();
                                final uploadedUrl = await CloudinaryMediaService.uploadMediaBytes(
                                  bytes: bytes,
                                  filename: pickedVideo!.name,
                                  resourceType: mediaType == 'video' ? 'video' : 'auto',
                                );
                                if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                                  finalVideoUrl = uploadedUrl;
                                } else {
                                  finalVideoUrl = pickedVideo!.path;
                                }
                              } catch (e) {
                                debugPrint('Cloudinary upload error: $e');
                                finalVideoUrl = pickedVideo!.path;
                              } finally {
                                setModalState(() => isUploading = false);
                              }
                            }

                            final newItem = SermonMediaItem(
                              id: 'admin-${DateTime.now().millisecondsSinceEpoch}',
                              title: title,
                              preacher: preacherCtrl.text.trim().isNotEmpty ? preacherCtrl.text.trim() : ChurchProfile.headBishop,
                              scripture: scriptureCtrl.text.trim().isNotEmpty ? scriptureCtrl.text.trim() : 'Zaburi 121:1-8',
                              date: 'Leo, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              duration: durationCtrl.text.trim().isNotEmpty ? durationCtrl.text.trim() : '45 min',
                              type: mediaType,
                              category: category,
                              description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : 'Ujumbe wa kiroho uliowekwa na Utawala wa Sayuni.',
                              imageUrl: 'assets/images/church_front.jpg',
                              audioUrl: mediaType == 'audio' ? finalVideoUrl : 'https://stream.zeno.fm/4v4e91y9sm8uv',
                              videoUrl: mediaType == 'video' ? finalVideoUrl : '',
                              isAdminUpload: true,
                            );

                            setState(() {
                              _customSermons.insert(0, newItem);
                            });
                            await _saveCustomSermons();

                            // Synchronize with Web Admin Portal & Supabase
                            await ChurchSyncService().syncNewSermon(
                              id: newItem.id,
                              title: newItem.title,
                              preacher: newItem.preacher,
                              scripture: newItem.scripture,
                              duration: newItem.duration,
                              type: newItem.type,
                              category: newItem.category,
                              mediaUrl: finalVideoUrl,
                            );

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Hubiri limepakiwa kikamilifu na linapatikana kwa waumini wote!'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            }
                          },
                          icon: isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                          label: Text(
                            isUploading ? 'Inapakia kwenye Cloudinary...' : 'Hifadhi & Chapisha Video',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openMediaPlayer(SermonMediaItem item) {
    AppHaptics.mediumImpact();
    if (item.type == 'video') {
      _openVideoPlayer(item);
    } else {
      ChurchAudioService().playTrack(
        id: item.id,
        title: item.title,
        subtitle: '${item.preacher} • ${item.scripture}',
        audioUrl: item.audioUrl,
        imageUrl: item.imageUrl,
      );
    }
  }

  void _openVideoPlayer(SermonMediaItem item) {
    AppHaptics.mediumImpact();
    ChurchAudioService().playTrack(
      id: item.id,
      title: item.title,
      subtitle: '${item.preacher} • ${item.scripture}',
      audioUrl: item.audioUrl,
      imageUrl: item.imageUrl,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0A192F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool isPlaying = true;
        final isVideo = item.type == 'video';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.92,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isVideo ? const Color(0xFFDC2626) : AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isVideo ? Icons.videocam_rounded : Icons.headphones_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isVideo ? 'VIDEO YA MAHUBIRI' : 'SAUTI YA MAHUBIRI & KWAYA',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (isVideo) ...[
                          // Video Player AspectRatio Frame
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image(
                                    image: (item.imageUrl.startsWith('http') || item.imageUrl.startsWith('blob:') || item.imageUrl.startsWith('assets/'))
                                        ? (item.imageUrl.startsWith('assets/') ? AssetImage(item.imageUrl) as ImageProvider : NetworkImage(item.imageUrl))
                                        : const AssetImage('assets/images/pastoral_leadership_1788577468703.jpg'),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.black87,
                                      child: const Center(
                                        child: Icon(Icons.play_circle_fill_rounded, size: 60, color: AppColors.gold),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.45),
                                  ),
                                  IconButton(
                                    iconSize: 64,
                                    icon: Icon(
                                      isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                      color: AppColors.gold,
                                    ),
                                    onPressed: () {
                                      AppHaptics.lightImpact();
                                      ChurchAudioService().togglePlayPause();
                                      setModalState(() => isPlaying = !isPlaying);
                                    },
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 12,
                                    right: 12,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'HD • Cloudinary CDN Streaming',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          item.duration,
                                          style: const TextStyle(
                                            color: AppColors.gold,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          // Audio Player Disc Artwork Frame
                          Center(
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [Color(0xFF1E6BFF), Color(0xFF0A2540)],
                                ),
                                border: Border.all(color: AppColors.gold, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: (item.imageUrl.startsWith('http') || item.imageUrl.startsWith('blob:'))
                                  ? Image.network(
                                      item.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Icon(Icons.music_note_rounded, size: 54, color: Colors.white),
                                      ),
                                    )
                                  : Image.asset(
                                      item.imageUrl.startsWith('assets/') ? item.imageUrl : 'assets/images/church_front.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Icon(Icons.music_note_rounded, size: 54, color: Colors.white),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Live Audio Progress & Scrubbing Bar
                          ListenableBuilder(
                            listenable: ChurchAudioService(),
                            builder: (context, _) {
                              final audio = ChurchAudioService();
                              final maxSec = audio.duration.inSeconds > 0 ? audio.duration.inSeconds.toDouble() : 1.0;
                              final curSec = audio.position.inSeconds.toDouble().clamp(0.0, maxSec);
                              String fmt(Duration d) {
                                final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
                                final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
                                return '$m:$s';
                              }

                              return Column(
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppColors.gold,
                                      inactiveTrackColor: Colors.white24,
                                      thumbColor: AppColors.gold,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      trackHeight: 3,
                                    ),
                                    child: Slider(
                                      value: curSec,
                                      max: maxSec,
                                      onChanged: (val) {
                                        audio.seek(Duration(seconds: val.toInt()));
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(fmt(audio.position), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                        Text(fmt(audio.duration), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 8),

                          // Dedicated Audio Controls: Rewind 10s, Play/Pause, Forward 10s
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_10_rounded, color: Colors.white70, size: 28),
                                onPressed: () {
                                  AppHaptics.lightImpact();
                                  final audio = ChurchAudioService();
                                  audio.seek(audio.position - const Duration(seconds: 10));
                                },
                              ),
                              const SizedBox(width: 14),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFDF70), Color(0xFFD4AF37)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.gold.withValues(alpha: 0.4),
                                      blurRadius: 14,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: const Color(0xFF0A2540),
                                    size: 32,
                                  ),
                                  onPressed: () {
                                    AppHaptics.selectionClick();
                                    ChurchAudioService().togglePlayPause();
                                    setModalState(() => isPlaying = !isPlaying);
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                icon: const Icon(Icons.forward_10_rounded, color: Colors.white70, size: 28),
                                onPressed: () {
                                  AppHaptics.lightImpact();
                                  final audio = ChurchAudioService();
                                  audio.seek(audio.position + const Duration(seconds: 10));
                                },
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Lock Screen & Cloudinary Streaming Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D233A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock_clock_rounded, color: AppColors.gold, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Inaendelea kucheza hata ukifunga simu (Lock Screen Controls)',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${item.preacher} • ${item.scripture} • ${item.date}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),

                        if (item.videoUrl.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                AppHaptics.mediumImpact();
                                final uri = Uri.tryParse(item.videoUrl);
                                if (uri != null) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                              label: const Text(
                                'Fungua Kiungo cha Video (YouTube / Cloudinary / MP4)',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sermons = _filteredSermons;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Liturgical App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E6BFF), Color(0xFF0D52CD)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mahubiri & Nyimbo za Injili',
                            style: AppTypography.titleMedium(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Neno la Uzima, Sauti & Video za Ibada',
                            style: AppTypography.caption(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_auth.isAdmin)
                      IconButton(
                        onPressed: _showAdminUploadVideoDialog,
                        icon: const Icon(Icons.video_call_rounded, color: AppColors.primary, size: 24),
                        tooltip: 'Ongeza Hubiri / Video (Admin)',
                      ),
                    IconButton(
                      onPressed: () {
                        AppHaptics.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OnlineRadioScreen()),
                        );
                      },
                      icon: const Icon(Icons.radio_rounded, color: Colors.redAccent, size: 22),
                      tooltip: 'Redio za Moja kwa Moja',
                    ),
                    IconButton(
                      onPressed: () {
                        AppHaptics.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotesScreen()),
                        );
                      },
                      icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                      tooltip: 'Daftari la Mahubiri',
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Tafuta mahubiri, mchungaji au andiko...',
                      hintStyle: AppTypography.bodySmall(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
            ),

            // Categories Filter Chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, idx) {
                    final cat = _categories[idx];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) {
                          AppHaptics.selectionClick();
                          setState(() => _selectedCategory = cat);
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Admin Upload Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Maudhui & Video za Sayuni',
                      style: AppTypography.titleSmall(color: AppColors.textPrimary),
                    ),
                    if (_auth.isAdmin)
                      InkWell(
                        onTap: _showAdminUploadVideoDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                '+ Ongeza Video (Admin)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Online Gospel Radios Carousel
            if (_selectedCategory == 'Yote' || _selectedCategory == 'Radio za Injili') ...[
              SliverToBoxAdapter(
                child: _buildGospelRadioSection(),
              ),
              if (_selectedCategory == 'Radio za Injili')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: AppCard(
                      backgroundColor: const Color(0xFF1B072C),
                      borderColor: AppColors.gold.withValues(alpha: 0.5),
                      onTap: () {
                        AppHaptics.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OnlineRadioScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.tune_rounded, color: AppColors.gold, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sikiliza Redio za Moja kwa Moja (Live Radio)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Afro Gospel 🇳🇬, Tanzania 🇹🇿, Global Worship & Habari za Dunia 📰',
                                  style: AppTypography.caption(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.gold, size: 15),
                        ],
                      ),
                    ),
                  ),
                ),
            ],

            // Featured Hero Card (Mahubiri Kinara)
            if ((_selectedCategory == 'Yote' || _selectedCategory == 'Mahubiri') && sermons.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0A2540),
                            Color(0xFF031B4E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Icon(
                              Icons.church_rounded,
                              size: 160,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.fiber_manual_record_rounded, size: 10, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            'MAHUBIRI KINARA',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${sermons.first.duration} • ${sermons.first.type.toUpperCase()}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  sermons.first.title,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.4,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${sermons.first.preacher} • ${sermons.first.scripture}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openMediaPlayer(sermons.first),
                                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                                      label: const Text('Tazama Sasa'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.gold,
                                        foregroundColor: const Color(0xFF0A2540),
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const NotesScreen()),
                                        );
                                      },
                                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                                      label: const Text('Dokezo'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Quick Access to Choir Screen
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: AppCard(
                  backgroundColor: AppColors.surface,
                  borderColor: AppColors.border,
                  onTap: () {
                    AppHaptics.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChoirScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.music_note_rounded, color: Color(0xFF16A34A), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nyimbo za Kwaya ya Galilaya & Sifa',
                              style: AppTypography.titleSmall(color: AppColors.textPrimary),
                            ),
                            Text(
                              'Maneno kamili, key, na tempo za nyimbo zote',
                              style: AppTypography.caption(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),

            // Sermons List
            if (sermons.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 180 + MediaQuery.of(context).padding.bottom),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.video_library_outlined,
                              size: 38,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Hakuna Maudhui Yaliyopakiwa Bado',
                            style: AppTypography.titleSmall(color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedCategory == 'Yote'
                                ? 'Mahubiri mapya na masomo ya kiroho yataonekana hapa punde yatakapopakiwa.'
                                : 'Hakuna maudhui yaliyopatikana kwa kipengele cha "$_selectedCategory".',
                            style: AppTypography.caption(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          if (_auth.isAdmin) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showAdminUploadVideoDialog,
                              icon: const Icon(Icons.video_call_rounded, size: 18),
                              label: const Text('Pakia Hubiri / Video (Admin)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 180 + MediaQuery.of(context).padding.bottom),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, idx) {
                      final item = sermons[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          backgroundColor: AppColors.surface,
                          borderColor: AppColors.border,
                          onTap: () => _openMediaPlayer(item),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Thumbnail / Icon
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  item.type == 'video'
                                      ? Icons.smart_display_rounded
                                      : Icons.mic_external_on_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (item.isAdminUpload)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.gold.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                                            ),
                                            child: const Text(
                                              'ADMIN',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.goldDark,
                                              ),
                                            ),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: item.type == 'video'
                                                ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                                                : AppColors.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.type.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: item.type == 'video'
                                                  ? const Color(0xFFDC2626)
                                                  : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.duration,
                                          style: AppTypography.caption(color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${item.preacher} • ${item.scripture}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  item.type == 'video'
                                      ? Icons.play_circle_fill_rounded
                                      : Icons.play_circle_outline_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                onPressed: () => _openMediaPlayer(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: sermons.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGospelRadioSection() {
    final audio = ChurchAudioService();
    // Combine featured Afro Gospel & Tanzania Gospel for instant preview
    final previewStations = <RadioStation>[
      ...RadioBrowserService.curatedAfroGospelRadios.take(4),
      ...RadioBrowserService.curatedTanzaniaGospelRadios.take(3),
      ...RadioBrowserService.curatedNewsRadios.take(2),
    ];

    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'ONLINE RADIO',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Radio za Injili & Habari',
                      style: AppTypography.titleSmall(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      AppHaptics.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OnlineRadioScreen()),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 15, color: AppColors.gold),
                    label: const Text(
                      'Ona Zote',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 132,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: previewStations.length + 1,
                separatorBuilder: (ctx, idx) => const SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  if (idx == previewStations.length) {
                    // Explore more card at the end
                    return GestureDetector(
                      onTap: () {
                        AppHaptics.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OnlineRadioScreen()),
                        );
                      },
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Radio Zote (40+)',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Afro Gospel, TZ & Habari',
                              style: AppTypography.caption(color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final station = previewStations[idx];
                  final isCurrentRadio = audio.currentTrack?.id == station.stationuuid;
                  final isPlayingThis = isCurrentRadio && audio.isPlaying;

                  return GestureDetector(
                    onTap: () {
                      AppHaptics.mediumImpact();
                      if (isPlayingThis) {
                        audio.togglePlayPause();
                      } else {
                        audio.playRadioStation(station);
                        RadioBrowserService().registerStationClick(station.stationuuid);
                      }
                    },
                    child: Container(
                      width: 230,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCurrentRadio
                              ? [const Color(0xFF0A2540), const Color(0xFF0D52CD)]
                              : [AppColors.surface, AppColors.surfaceLow],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isCurrentRadio
                              ? AppColors.primaryLight
                              : AppColors.border,
                          width: isCurrentRadio ? 1.5 : 1,
                        ),
                        boxShadow: isCurrentRadio
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCurrentRadio
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: (station.favicon.isNotEmpty && station.favicon.startsWith('http'))
                                    ? Image.network(
                                        station.favicon,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Center(
                                          child: Text(
                                            station.flagEmoji,
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          station.flagEmoji,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      station.country.isNotEmpty ? station.country : 'Live Radio',
                                      style: TextStyle(
                                        color: isCurrentRadio
                                            ? AppColors.gold
                                            : AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      station.state.isNotEmpty ? station.state : station.codec,
                                      style: AppTypography.caption(
                                        color: isCurrentRadio ? Colors.white70 : AppColors.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isPlayingThis
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: isCurrentRadio ? AppColors.gold : AppColors.primary,
                                size: 30,
                              ),
                            ],
                          ),
                          Text(
                            station.name,
                            style: TextStyle(
                              color: isCurrentRadio ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            station.tags.isNotEmpty ? station.tags : 'Gospel & Praise 24/7',
                            style: TextStyle(
                              color: isCurrentRadio ? Colors.white60 : AppColors.textSecondary,
                              fontSize: 10.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
