import 'package:flutter/foundation.dart';

/// Whether the app is currently locked into "child mode" (read-only view,
/// no rating buttons). Session-only by design — reopening the app always
/// starts back in parent mode.
class ChildModeProvider extends ChangeNotifier {
  bool isChildMode = false;

  void enter() {
    isChildMode = true;
    notifyListeners();
  }

  /// Returns true and exits child mode if [pin] matches [expectedPin].
  bool tryExit(String pin, String? expectedPin) {
    final target = expectedPin ?? '0000';
    if (pin == target) {
      isChildMode = false;
      notifyListeners();
      return true;
    }
    return false;
  }
}
