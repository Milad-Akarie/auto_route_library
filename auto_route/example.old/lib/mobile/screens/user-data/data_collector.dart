import 'package:material_ui/material_ui.dart';

/// Holds the [UserData] while the user data flow runs and notifies listeners
/// when it changes.
class SettingsState extends ChangeNotifier {
  UserData _userData = const UserData();

  set userData(UserData data) {
    _userData = data;
    notifyListeners();
  }

  /// The data collected so far.
  ///
  /// Setting it notifies listeners.
  UserData get userData => _userData;
}

/// What the user data flow collects: a name and a favorite book.
class UserData {
  /// Both fields start empty.
  const new({
    this.name,
    this.favoriteBook,
  });

  /// The name entered, or `null` when not given yet.
  final String? name;

  /// The favorite book entered, or `null` when not given yet.
  final String? favoriteBook;

  @override
  String toString() {
    return 'UserData{name: $name, favoriteBook: $favoriteBook}';
  }

  /// Whether both the name and the favorite book are given.
  bool get isDone => name != null && favoriteBook != null;

  /// Returns a copy with [name] and [favoriteBook] replaced when they are not
  /// `null`.
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
