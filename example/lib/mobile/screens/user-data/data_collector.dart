import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserDataCollectorPage extends StatefulWidget implements AutoRouteWrapper {
  final Function(UserData data) onResult;

  const UserDataCollectorPage({Key key, this.onResult}) : super(key: key);

  @override
  _UserDataCollectorPageState createState() => _UserDataCollectorPageState();

  @override
  Widget wrappedRoute(BuildContext context) {
    return ChangeNotifierProvider<SettingsState>(
      create: (_) => SettingsState(),
      child: this,
    );
  }
}

class _UserDataCollectorPageState extends State<UserDataCollectorPage> {
  @override
  Widget build(context) => AutoRouter.declarative(onGenerateRoutes: (_, __) {
        var settingsState = Provider.of<SettingsState>(context);
        var user = settingsState.userData;
        return [
          if (user.isDone) UserDataRoute(onResult: widget.onResult),
          if (user.favoriteBook == null)
            SingleFieldRoute(
              message: 'What is your favorite book?',
              willPopMessage: 'Please enter a book name!',
              onNext: (text) {
                settingsState.userData = user.copyWith(favoriteBook: text);
              },
            ),
          if (user.name == null)
            SingleFieldRoute(
              message: 'What is your name?',
              willPopMessage: 'Please enter a name!',
              onNext: (text) {
                settingsState.userData = user.copyWith(name: text);
              },
            ),
        ];
      });
}

class SettingsState extends ChangeNotifier {
  UserData _userData = UserData();

  set userData(UserData data) {
    _userData = data;
    notifyListeners();
  }

  UserData get userData => _userData;
}

class UserData {
  final String name;
  final String favoriteBook;

  const UserData({
    this.name,
    this.favoriteBook,
  });

  bool get isDone => name != null && favoriteBook != null;

  UserData copyWith({
    String name,
    String favoriteBook,
  }) {
    return UserData(
      name: name ?? this.name,
      favoriteBook: favoriteBook ?? this.favoriteBook,
    );
  }
}
