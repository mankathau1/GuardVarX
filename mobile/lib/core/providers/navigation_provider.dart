import 'package:flutter_riverpod/flutter_riverpod.dart';

final mainNavigationProvider = StateNotifierProvider<MainNavigationNotifier, int>((ref) {
  return MainNavigationNotifier();
});

class MainNavigationNotifier extends StateNotifier<int> {
  MainNavigationNotifier() : super(0);

  final List<int> _history = [0];
  List<int> get history => List.unmodifiable(_history);

  void setTab(int index) {
    if (index < 0 || index > 4) return;
    if (state == index) return;

    if (_history.isEmpty || _history.last != index) {
      _history.add(index);
    }
    state = index;
  }

  /// Handles back navigation between tabs. Returns true if handled, false if at root.
  bool handleBack() {
    if (_history.length > 1) {
      _history.removeLast();
      state = _history.last;
      return true;
    } else if (state != 0) {
      state = 0;
      _history.clear();
      _history.add(0);
      return true;
    }
    return false;
  }

  void resetToHome() {
    state = 0;
    _history.clear();
    _history.add(0);
  }
}
