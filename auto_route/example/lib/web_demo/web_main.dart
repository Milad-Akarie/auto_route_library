import 'package:example/web_demo/router/web_router.dart';
import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs
void main() {
  runApp(App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  AppState createState() => AppState();

  static AppState of(BuildContext context) {
    return context.findAncestorStateOfType<AppState>()!;
  }
}

class AppState extends State<App> {
  late final authService = AuthService()
    ..addListener(() {
      setState(() {});
    });

  late final _router = WebAppRouter(authService);
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      routerConfig: _router.config(
        reevaluateListenable: authService,
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login to continue'),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                App.of(context).authService.isAuthenticated = true;
              },
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: () {
                App.of(context).authService.isVerified = true;
              },
              child: Text('Verify'),
            ),
            ElevatedButton(
              onPressed: () {
                final authService = App.of(context).authService;
                authService.loginAndVerify();
              },
              child: Text('Login & Verify'),
            ),
          ],
        ),
      ),
    );
  }
}

// mock auth state
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  bool _isVerified = false;

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

  void loginAndVerify() {
    _isAuthenticated = true;
    _isVerified = true;
    notifyListeners();
  }
}
