import 'package:material_ui/material_ui.dart';

class SettingsState extends ChangeNotifier {
  UserData _userData = const UserData();

  set userData(UserData data) {
    _userData = data;
    notifyListeners();
  }

  UserData get userData => _userData;
}

class UserData {
  const new({
    this.name,
    this.favoriteBook,
  });
  final String? name;
  final String? favoriteBook;

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
