import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:example/mobile/screens/user-data/data_collector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserDataCollectorPage extends StatefulWidget implements AutoRouteWrapper {
  final Function(UserData data)? onResult;

  const UserDataCollectorPage({Key? key, this.onResult}) : super(key: key);

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
  Widget build(context) {
    var settingsState = context.watch<SettingsState>();

    return Scaffold(
      body: AutoRouter.declarative(routes: (handler) {
        return [
          if (settingsState.userData.favoriteBook == null)
            FavoriteBookFieldRoute(
              message: 'What is your favorite book?',
              willPopMessage: 'Please enter a book name!',
              onNext: (text) {
                settingsState.userData = settingsState.userData.copyWith(favoriteBook: text);
              },
            ),
          if (settingsState.userData.name == null)
            NameFieldRoute(
              message: 'What is your name?',
              willPopMessage: 'Please enter a name!',
              onNext: (text) {
                settingsState.userData = settingsState.userData.copyWith(name: text);
              },
            ),
          if (settingsState.userData.isDone) UserDataRoute(onResult: widget.onResult),
        ];
      }, onPopRoute: (route, results) {
        // reset the state based on popped route
      }),
    );
  }
}
