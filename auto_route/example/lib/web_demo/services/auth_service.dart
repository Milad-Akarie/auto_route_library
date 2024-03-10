//ignore_for_file: public_member_api_docs
// mock auth state
// Converted to singleton for easier usage and referencing.
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {

  static AuthService _instance = AuthService._();

  AuthService._() {
    _instance = this;
  }

  static AuthService get instance => _instance;

  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  bool _isVerified = false;

  bool get isVerified => _isVerified;

  void login() {
    isAuthenticated = true;
  }

  void logout() {
    isAuthenticated = false;
  }

  void verifyAccount() {
    isVerified = true;
  }

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

  void loginAndVerify() {
    _isAuthenticated = true;
    _isVerified = true;
    notifyListeners();
  }

}
