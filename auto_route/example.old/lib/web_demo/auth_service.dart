import 'package:material_ui/material_ui.dart';

/// A mock sign-in state for the web example.
///
/// Nothing is checked or stored; it holds two flags and tells listeners when
/// they change.
// mock auth state
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;

  /// Whether the user is signed in.
  ///
  /// Setting it to `false` also clears [isVerified].
  bool get isAuthenticated => _isAuthenticated;

  bool _isVerified = false;

  /// Whether the user is verified; required for the posts of a user.
  bool get isVerified => _isVerified;

  set isVerified(bool value) {
    _isVerified = value;
    notifyListeners();
  }

  set isAuthenticated(bool value) {
    _isAuthenticated = value;
    if (!_isAuthenticated) {
      _isVerified = false;
    }
    notifyListeners();
  }

  /// Signs the user in and verifies them in one step.
  void loginAndVerify() {
    _isAuthenticated = true;
    _isVerified = true;
    notifyListeners();
  }
}
