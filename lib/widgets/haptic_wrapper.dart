import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class HapticWrapper {
  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }
}
