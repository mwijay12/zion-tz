import 'package:flutter/services.dart';

/// Tactile feedback utilities for production-grade mobile interactions.
abstract class AppHaptics {
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
}
