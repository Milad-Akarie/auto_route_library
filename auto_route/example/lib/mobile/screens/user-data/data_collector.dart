import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs
class SettingsState extends ChangeNotifier {
  UserData _userData = UserData();

  set userData(UserData data) {
    _userData = data;
    notifyListeners();
  }

  UserData get userData => _userData;
}

class UserData {
  final String? name;
  final String? favoriteBook;

  const UserData({
    this.name,
    this.favoriteBook,
  });

  @override
  String toString() {
    return 'UserData{name: $name, favoriteBook: $favoriteBook}';
  }

  bool get isDone => name != null && favoriteBook != null;

  UserData copyWith({
    String? name,
    String? favoriteBook,
  }) {
    return UserData(
      name: name ?? this.name,
      favoriteBook: favoriteBook ?? this.favoriteBook,
    );
  }
}
