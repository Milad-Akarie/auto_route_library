import 'package:flutter/foundation.dart';

/// A mock sign-in state for the mobile example.
///
/// Nothing is checked or stored: [login] and [logout] only flip a flag and tell
/// listeners.
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;

  /// Whether the user is signed in.
  bool get isAuthenticated => _isAuthenticated;

  /// Marks the user as signed in and notifies listeners.
  void login() {
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Marks the user as signed out and notifies listeners.
  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }
}
