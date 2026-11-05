import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/user-data/data_collector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Host of the user data flow; hands a [SettingsState] to the pages below it.
///
/// Its steps are commented out, so it shows an empty declarative router.
// An example page, kept as written so the example shows the same code.
// ignore: avoid-unnecessary-stateful-widgets
class UserDataCollectorPage extends StatefulWidget implements AutoRouteWrapper {
  /// Takes [onResult].
  const new({super.key, this.onResult});

  /// Called with the collected data when the flow ends.
  // The generated router copies this type into its args class.
  // ignore: inference_failure_on_function_return_type
  final Function(UserData data)? onResult;

  @override
  UserDataCollectorPageState createState() => .new();

  @override
  Widget wrappedRoute(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsState(),
      child: this,
    );
  }
}

/// State of [UserDataCollectorPage].
class UserDataCollectorPageState extends State<UserDataCollectorPage> {
  @override
  Widget build(BuildContext context) {
    // var settingsState = context.watch<SettingsState>();

    return Scaffold(
      body: AutoRouter.declarative(
        routes: (handler) {
          return [
            // if (settingsState.userData.favoriteBook == null)
            //   FavoriteBookFieldRoute(
            //     message: 'What is your favorite book?',
            //     willPopMessage: 'Please enter a book name!',
            //     onNext: (text) {
            //       settingsState.userData =
            //           settingsState.userData.copyWith(favoriteBook: text);
            //     },
            //   ),
            // if (settingsState.userData.name == null)
            //   NameFieldRoute(
            //     message: 'What is your name?',
            //     willPopMessage: 'Please enter a name!',
            //     onNext: (text) {
            //       settingsState.userData =
            //           settingsState.userData.copyWith(name: text);
            //     },
            //   ),
            // if (settingsState.userData.isDone)
            //   UserDataRoute(onResult: widget.onResult),
          ];
        },
        onPopRoute: (route, results) {
          // reset the state based on popped route
        },
      ),
    );
  }
}
