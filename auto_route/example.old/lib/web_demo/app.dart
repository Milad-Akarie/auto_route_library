import 'package:example/web_demo/auth_service.dart';
import 'package:example/web_demo/router/web_app_router.dart';
import 'package:material_ui/material_ui.dart';

/// Root widget of the web example app.
///
/// Owns the [AuthService] and the router, and rebuilds when the sign-in state
/// changes.
class App extends StatefulWidget {
  /// Creates the app.
  const new({super.key});

  @override
  AppState createState() => .new();

  /// Returns the [AppState] above [context].
  ///
  /// Throws when there is no [App] above [context].
  static AppState of(BuildContext context) {
    return context.findAncestorStateOfType()!;
  }
}

/// State of [App]; holds the [AuthService].
class AppState extends State<App> {
  /// The mock sign-in state, shared with the router and the pages.
  late final authService = AuthService();

  late final _router = WebAppRouter(authService);

  @override
  void dispose() {
    _router.dispose();
    authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authService,
      builder: (_, _) => MaterialApp.router(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        routerConfig: _router.config(reevaluateListenable: authService),
      ),
    );
  }
}
