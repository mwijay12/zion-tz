import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/church_theme_service.dart';
import '../../../core/utils/haptics.dart';
import '../models/copilot_action.dart';
import 'local_faith_ai_engine.dart';

class SayuniCopilotService extends ChangeNotifier {
  static final SayuniCopilotService _instance = SayuniCopilotService._internal();
  factory SayuniCopilotService() => _instance;
  SayuniCopilotService._internal();

  static const String _apiEndpoint = 'https://sayuni-portal.vercel.app/api/copilot';
  static const String _storageKey = 'sayuni_copilot_chat_history_v1';
  static const String _ordersKey = 'sayuni_member_book_orders_v1';

  final List<CopilotMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<CopilotMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _loadSavedHistory();

    // If chat is empty, insert welcoming greeting
    if (_messages.isEmpty) {
      _messages.add(
        CopilotMessage(
          id: 'welcome_msg',
          text: 'Bwana Yesu asifiwe! Mimi ni Sayuni Copilot. '
              'Ninaweza kukusaidia kubadili theme (Giza au Mchana), kutafuta na kuagiza vitabu vya Tenzi na Biblia, '
              'kufungua nyimbo au kukusaidia kwa maombi na ratiba za ibada. Niambie nikusaidie nini leo?',
          isUser: false,
          timestamp: DateTime.now(),
          isOffline: true,
        ),
      );
      notifyListeners();
    }
  }

  Future<void> _loadSavedHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        _messages.clear();
        for (final item in list) {
          _messages.add(CopilotMessage.fromJson(Map<String, dynamic>.from(item)));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
    }
  }

  Future<void> _persistHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = jsonEncode(_messages.map((m) => m.toJson()).toList());
      await prefs.setString(_storageKey, serialized);
    } catch (e) {
      debugPrint('Failed to save chat history: $e');
    }
  }

  Future<void> clearHistory() async {
    _messages.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await init();
    notifyListeners();
  }

  /// Main method: handles user query with online Vercel Groq proxy + seamless offline fallback
  Future<CopilotMessage> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      return _messages.last;
    }

    final userMsg = CopilotMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: clean,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    CopilotMessage botResponse;

    try {
      // 1. Try Live Vercel Serverless Endpoint (Groq powered, zero keys in APK)
      final onlineResult = await _callOnlineProxy(clean);
      if (onlineResult != null) {
        botResponse = onlineResult;
      } else {
        // Fallback to local offline engine
        botResponse = _runLocalEngine(clean);
      }
    } catch (_) {
      // If network offline or failed, seamlessly fall back to local rule engine
      botResponse = _runLocalEngine(clean);
    }

    _isLoading = false;
    _messages.add(botResponse);
    await _persistHistory();
    notifyListeners();

    // Automatically execute safe actions like theme switching immediately
    if (botResponse.actionType == CopilotActionType.changeTheme && !botResponse.isActionExecuted) {
      await executeAction(botResponse);
    }

    return botResponse;
  }

  Future<CopilotMessage?> _callOnlineProxy(String query) async {
    try {
      // Prepare history slice
      final history = _messages
          .where((m) => m.id != 'welcome_msg')
          .take(4)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      final response = await http
          .post(
            Uri.parse(_apiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': query,
              'history': history,
            }),
          )
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          final actionStr = data['action'] as String? ?? 'none';
          CopilotActionType actionType = CopilotActionType.none;
          try {
            actionType = CopilotActionType.values.byName(actionStr);
          } catch (_) {}

          return CopilotMessage(
            id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
            text: data['reply'] ?? 'Ubarikiwe katika Sayuni.',
            isUser: false,
            timestamp: DateTime.now(),
            actionType: actionType,
            actionData: Map<String, dynamic>.from(data['actionData'] ?? {}),
            isOffline: false,
          );
        }
      }
    } catch (e) {
      debugPrint('Online copilot unreachable, switching to offline: $e');
    }
    return null;
  }

  CopilotMessage _runLocalEngine(String query) {
    final localResult = LocalFaithAiEngine.processQuery(query);

    return CopilotMessage(
      id: 'bot_offline_${DateTime.now().millisecondsSinceEpoch}',
      text: localResult.reply,
      isUser: false,
      timestamp: DateTime.now(),
      actionType: localResult.actionType,
      actionData: localResult.actionData,
      isOffline: true,
    );
  }

  /// Executes an action triggered by the AI
  Future<bool> executeAction(CopilotMessage message) async {
    AppHaptics.lightImpact();

    switch (message.actionType) {
      case CopilotActionType.changeTheme:
        final mode = message.actionData['mode']?.toString().toLowerCase();
        if (mode == 'dark') {
          await ChurchThemeService().setThemeMode(ThemeMode.dark);
        } else if (mode == 'light') {
          await ChurchThemeService().setThemeMode(ThemeMode.light);
        } else {
          // Liturgical Gold / Default Dark
          await ChurchThemeService().setThemeMode(ThemeMode.dark);
        }
        message.isActionExecuted = true;
        notifyListeners();
        return true;

      case CopilotActionType.orderProduct:
        message.isActionExecuted = true;
        notifyListeners();
        return true;

      default:
        message.isActionExecuted = true;
        notifyListeners();
        return true;
    }
  }

  /// Places a book order and records it locally
  Future<bool> placeBookOrder({
    required String productTitle,
    required String priceFormatted,
    required String buyerName,
    required String buyerPhone,
    required String branch,
    String? notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingRaw = prefs.getString(_ordersKey);
      final List orders = existingRaw != null ? jsonDecode(existingRaw) : [];

      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final orderData = {
        'orderId': orderId,
        'productTitle': productTitle,
        'price': priceFormatted,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'branch': branch,
        'notes': notes ?? '',
        'status': 'Imepokelewa (Inasubiri Kuchukuliwa)',
        'createdAt': DateTime.now().toIso8601String(),
      };

      orders.insert(0, orderData);
      await prefs.setString(_ordersKey, jsonEncode(orders));

      // Append confirmation message in chat
      _messages.add(
        CopilotMessage(
          id: 'ord_conf_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Hongera ndugu $buyerName! Oda yako namba **$orderId** ya "$productTitle" imepokelewa kikamilifu kwa ajili ya tawi la **$branch**.\n'
              'Mhudumu wa ofisi ya Sayuni atawasiliana nawe kupitia $buyerPhone kukukabidhi kitabu chako.',
          isUser: false,
          timestamp: DateTime.now(),
          isOffline: true,
        ),
      );
      await _persistHistory();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error placing book order: $e');
      return false;
    }
  }
}
