import 'package:flutter/material.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/church_theme_service.dart';
import '../../../core/utils/haptics.dart';
import '../../giving/presentation/giving_screen.dart';
import '../../media/presentation/online_radio_screen.dart';
import '../../pastoral/presentation/appointments_screen.dart';
import '../../prayer/presentation/prayer_war_room_screen.dart';
import '../models/copilot_action.dart';
import '../services/sayuni_copilot_service.dart';

class SayuniCopilotSheet extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const SayuniCopilotSheet({
    super.key,
    this.onNavigateToTab,
  });

  static void show(BuildContext context, {Function(int tabIndex)? onNavigateToTab}) {
    AppHaptics.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => SayuniCopilotSheet(onNavigateToTab: onNavigateToTab),
    );
  }

  @override
  State<SayuniCopilotSheet> createState() => _SayuniCopilotSheetState();
}

class _SayuniCopilotSheetState extends State<SayuniCopilotSheet> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final SayuniCopilotService _copilotService = SayuniCopilotService();

  @override
  void initState() {
    super.initState();
    _copilotService.init();
    _copilotService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _copilotService.removeListener(_onServiceUpdate);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleSend([String? presetText]) {
    final text = presetText ?? _inputCtrl.text;
    if (text.trim().isEmpty) return;
    AppHaptics.selectionClick();
    if (presetText == null) {
      _inputCtrl.clear();
    }
    _copilotService.sendMessage(text);
  }

  void _openOrderSheet(String productTitle, String priceFormatted) {
    final isDark = ChurchThemeService().isDarkMode;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedBranch = ChurchProfile.branches.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kamilisha Oda ya Kitabu',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$productTitle • $priceFormatted',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'Jina Kamili la Muombaji *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'mf. David Erick',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Namba ya Simu (WhatsApp) *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'mf. 0744 123 456',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tawi la Kuchukulia Kitabu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBranch,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                        items: ChurchProfile.branches.map((b) {
                          return DropdownMenuItem(
                            value: b,
                            child: Text(
                              b,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedBranch = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48, // 48px Touch-First target
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        if (name.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text('Tafadhali weka jina na namba ya simu.'),
                            ),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        await _copilotService.placeBookOrder(
                          productTitle: productTitle,
                          priceFormatted: priceFormatted,
                          buyerName: name,
                          buyerPhone: phone,
                          branch: selectedBranch,
                        );

                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF16A34A),
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Oda imepokelewa na kuhifadhiwa kikamilifu!',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text('Thibitisha & Tuma Oda'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ChurchThemeService().isDarkMode;
    final messages = _copilotService.messages;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A1220) : const Color(0xFFFAF8F5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.6 : 0.2),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Liturgical Sandy Grain Header
            _buildLiturgicalHeader(isDark),

            // Messages Stream
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, idx) {
                        final msg = messages[idx];
                        return _buildMessageItem(msg, isDark);
                      },
                    ),
            ),

            if (_copilotService.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sayuni Copilot inatafakari Neno...',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Touch-First Action Chips Bar
            _buildQuickPromptChips(isDark),

            // Bottom Input Bar with 44px min touch ergonomics
            _buildInputBar(isDark, bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildLiturgicalHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2F) : const Color(0xFFF5EFEB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE5DDD0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              // Gold Shimmer Icon Badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withOpacity(0.35),
                      const Color(0xFF0D52CD).withOpacity(0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold, width: 1.2),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'SAYUNI COPILOT',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF16A34A), width: 0.8),
                          ),
                          child: const Text(
                            'HYBRID 2026',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hekima ya Kikanisa • 100% Salama & Bila Vifunguo',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, size: 22),
                tooltip: 'Futa Mazungumzo',
                color: isDark ? Colors.white60 : Colors.black54,
                onPressed: () {
                  AppHaptics.lightImpact();
                  _copilotService.clearHistory();
                },
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                color: isDark ? Colors.white70 : Colors.black87,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_alt_rounded, size: 48, color: AppColors.gold),
            const SizedBox(height: 12),
            Text(
              'Habari! Mimi ni Sayuni Copilot.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Unaweza kuniambia: "Badili theme ya giza", "Agiza kitabu cha Tenzi", "Soma Yohana 3:16", au kuuliza chochote kuhusu kanisa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(CopilotMessage msg, bool isDark) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 2, right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 1),
                  ),
                  child: const Icon(Icons.church_rounded, size: 14, color: AppColors.gold),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF0D52CD)
                        : (isDark ? const Color(0xFF132035) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? Colors.transparent
                          : (isDark ? const Color(0xFF1E304F) : const Color(0xFFE2E8F0)),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    msg.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: isUser ? Colors.white : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Action Dispatch View
          if (!isUser && msg.actionType != CopilotActionType.none)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 6),
              child: _buildActionExecutionCard(msg, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildActionExecutionCard(CopilotMessage msg, bool isDark) {
    switch (msg.actionType) {
      case CopilotActionType.changeTheme:
        final mode = msg.actionData['mode']?.toString() ?? 'dark';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF16A34A), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
              const SizedBox(width: 8),
              Text(
                'Mandhari ya ${mode == 'dark' ? 'Giza' : 'Mchana'} imewekwa mara moja!',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        );

      case CopilotActionType.orderProduct:
        final title = msg.actionData['productTitle']?.toString() ?? 'Kitabu cha Sayuni';
        final price = msg.actionData['priceFormatted']?.toString() ?? 'TZS 10,000';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF132035) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories_rounded, color: AppColors.gold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44, // 44px min touch ergonomics
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openOrderSheet(title, price),
                  icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
                  label: const Text('Kamilisha Oda Sasa (Agiza)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );

      case CopilotActionType.openHymn:
        final hymnNum = msg.actionData['hymnNumber'] ?? 1;
        return Container(
          margin: const EdgeInsets.only(top: 2),
          child: OutlinedButton.icon(
            onPressed: () {
              AppHaptics.lightImpact();
              Navigator.pop(context);
              widget.onNavigateToTab?.call(1); // Navigates to Book Hub
            },
            icon: const Icon(Icons.queue_music_rounded, size: 16, color: AppColors.gold),
            label: Text('Fungua Tenzi #$hymnNum Kwenye Kitabu'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: const BorderSide(color: AppColors.gold, width: 1.1),
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );

      case CopilotActionType.openScripture:
        final ref = msg.actionData['reference']?.toString() ?? 'Yohana 3:16';
        return Container(
          margin: const EdgeInsets.only(top: 2),
          child: OutlinedButton.icon(
            onPressed: () {
              AppHaptics.lightImpact();
              Navigator.pop(context);
              widget.onNavigateToTab?.call(1);
            },
            icon: const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF0D52CD)),
            label: Text('Soma $ref Kwenye Biblia'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0D52CD),
              side: const BorderSide(color: Color(0xFF0D52CD), width: 1.1),
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );

      case CopilotActionType.openRadio:
        return Container(
          margin: const EdgeInsets.only(top: 2),
          child: ElevatedButton.icon(
            onPressed: () {
              AppHaptics.lightImpact();
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnlineRadioScreen()),
              );
            },
            icon: const Icon(Icons.radio_rounded, size: 16),
            label: const Text('Fungua Redio ya Sayuni'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D52CD),
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );

      case CopilotActionType.submitPrayer:
        return Container(
          margin: const EdgeInsets.only(top: 2),
          child: ElevatedButton.icon(
            onPressed: () {
              AppHaptics.lightImpact();
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrayerWarRoomScreen()),
              );
            },
            icon: const Icon(Icons.volunteer_activism_rounded, size: 16),
            label: const Text('Tuma kwa Askofu & Wachungaji'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );

      case CopilotActionType.openAppointments:
        return Container(
          margin: const EdgeInsets.only(top: 2),
          child: OutlinedButton.icon(
            onPressed: () {
              AppHaptics.lightImpact();
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
              );
            },
            icon: const Icon(Icons.calendar_month_rounded, size: 16),
            label: const Text('Weka Miadi ya Kichungaji'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );

      case CopilotActionType.openGiving:
        return Container(
          margin: const EdgeInsets.only(top: 2),
          child: ElevatedButton.icon(
            onPressed: () {
              AppHaptics.lightImpact();
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GivingScreen()),
              );
            },
            icon: const Icon(Icons.favorite_rounded, size: 16),
            label: const Text('Fungua Dirisha la Sadaka'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: const Color(0xFF0F172A),
              minimumSize: const Size(120, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuickPromptChips(bool isDark) {
    final chips = [
      {'icon': Icons.dark_mode_rounded, 'label': 'Theme ya Giza', 'prompt': 'Weka theme ya giza'},
      {'icon': Icons.light_mode_rounded, 'label': 'Theme ya Mchana', 'prompt': 'Weka theme ya mchana'},
      {'icon': Icons.auto_stories_rounded, 'label': 'Agiza Kitabu cha Tenzi', 'prompt': 'Nataka kuagiza Kitabu cha Tenzi'},
      {'icon': Icons.menu_book_rounded, 'label': 'Soma Yohana 3:16', 'prompt': 'Soma Yohana 3:16'},
      {'icon': Icons.radio_rounded, 'label': 'Redio ya Sayuni', 'prompt': 'Washa redio ya Sayuni'},
      {'icon': Icons.access_time_rounded, 'label': 'Ratiba za Ibada', 'prompt': 'Ratiba za ibada zipoje?'},
      {'icon': Icons.phone_rounded, 'label': 'Mawasiliano ya Mchungaji', 'prompt': 'Mawasiliano ya mchungaji na viongozi'},
    ];

    return Container(
      height: 44, // 44px touch ergonomics
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final item = chips[idx];
          return ActionChip(
            avatar: Icon(item['icon'] as IconData, size: 16, color: AppColors.gold),
            label: Text(
              item['label'] as String,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            backgroundColor: isDark ? const Color(0xFF16243C) : const Color(0xFFEFE8DE),
            side: BorderSide(
              color: isDark ? const Color(0xFF223659) : const Color(0xFFDFD6C8),
            ),
            onPressed: () => _handleSend(item['prompt'] as String),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(bool isDark, double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 8, 14, 10 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2F) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                child: TextField(
                  controller: _inputCtrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Uliza au toa amri (mf. "Badili theme ya giza")...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF17263E) : const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44, // 44px min touch target
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: const Color(0xFF0F172A),
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                onPressed: () => _handleSend(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
