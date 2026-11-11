import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/user-data/settings_state.dart';
import 'package:example/mobile/screens/user-data/user_data.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Host of the user data flow; hands a [SettingsState] to the pages below it.
///
/// It shows an empty declarative router: no step of the flow is wired up.
class UserDataCollectorPage extends StatelessWidget
    implements AutoRouteWrapper {
  /// Takes [onResult].
  const new({super.key, this.onResult});

  /// Called with the collected data when the flow ends.
  // The generated router copies this type into its args class.
  final void Function(UserData data)? onResult;

  @override
  Widget wrappedRoute(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => SettingsState(), child: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AutoRouter.declarative(
        routes: (handler) {
          return [];
        },
      ),
    );
  }
}
