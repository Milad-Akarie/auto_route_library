import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/web_router.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(App());
}

class App extends StatefulWidget {
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

  late final _appRouter = WebAppRouter(authService);
 List<PageRouteInfo>? urlRoutes;
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      routeInformationProvider: _appRouter.routeInfoProvider(),
      routeInformationParser: _appRouter.defaultRouteParser(),
      routerDelegate: _appRouter.delegate(
        // initialDeepLink: '/user/1/posts/favorite',
        // onNavigate: (urlState){
        //   print(urlState.path);
        //   setState(() {
        //     urlRoutes = urlState.segments.map((e) => e.toPageRouteInfo()).toList();
        //   });
        // },
        // routes: (handler) {
        //   print(handler.peek?.map((e) => e.routeName));
        //   if (!authService.isAuthenticated) return [LoginRoute()];
        //   return handler.initialPendingRoutes ?? [HomeRouter()];
        // },
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
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
    notifyListeners();
  }


  void loginAndVerify() {
    _isAuthenticated = true;
    _isVerified = true;
    notifyListeners();
  }
}
