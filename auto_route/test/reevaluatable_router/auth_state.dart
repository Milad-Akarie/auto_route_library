import 'package:flutter/foundation.dart';

/// Whether the user is logged in; notifies its listeners on each change, so
/// it can be a router's reevaluateListenable.
class AuthState extends ChangeNotifier {
  bool _isLoggedIn = false;

  /// Whether the user is logged in; false at first.
  bool get isLoggedIn => _isLoggedIn;

  set isLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }
}
