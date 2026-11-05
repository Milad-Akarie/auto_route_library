import 'package:example/web_demo/router/web_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const App());
}

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
    return context.findAncestorStateOfType<AppState>()!;
  }
}

/// State of [App]; holds the [AuthService].
class AppState extends State<App> {
  /// The mock sign-in state, shared with the router and the pages.
  late final authService = AuthService()
    // Disposed with the service in dispose, so the listener goes with it.
    // ignore: avoid-unremovable-callbacks-in-listeners
    ..addListener(() {
      setState(() {});
    });

  late final _router = WebAppRouter(authService);

  @override
  void dispose() {
    _router.dispose();
    authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      routerConfig: _router.config(reevaluateListenable: authService),
    );
  }
}

/// Page with buttons that sign in, verify, or do both.
class LoginPage extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login to continue')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                App.of(context).authService.isAuthenticated = true;
              },
              child: const Text('Login'),
            ),
            ElevatedButton(
              onPressed: () {
                App.of(context).authService.isVerified = true;
              },
              child: const Text('Verify'),
            ),
            ElevatedButton(
              onPressed: () {
                App.of(context).authService.loginAndVerify();
              },
              child: const Text('Login & Verify'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A mock sign-in state for the web example.
///
/// Nothing is checked or stored; it holds two flags and tells listeners when
/// they change.
// mock auth state
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;

  /// Whether the user is signed in.
  ///
  /// Setting it to `false` also clears [isVerified].
  bool get isAuthenticated => _isAuthenticated;

  bool _isVerified = false;

  /// Whether the user is verified; required for the posts of a user.
  bool get isVerified => _isVerified;

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

  /// Signs the user in and verifies them in one step.
  void loginAndVerify() {
    _isAuthenticated = true;
    _isVerified = true;
    notifyListeners();
  }
}
