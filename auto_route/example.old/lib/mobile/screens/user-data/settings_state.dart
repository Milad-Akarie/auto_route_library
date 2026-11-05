import 'package:example/mobile/screens/user-data/user_data.dart';
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
