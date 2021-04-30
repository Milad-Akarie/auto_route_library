import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'router/web_router.gr.dart';

void main() {
  runApp(App());
  // var route1 = UserRoute(id: 1, children: [
  //   UserProfileRoute(),
  //   UserPostsRoute(),
  // ]);
  // var route2 = UserRoute(
  //   id: 1,
  //   children: [
  //     UserProfileRoute(),
  //     UserPostsRoute(),
  //   ],
  // );
  // print(route1 == route2);
}

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();

  static AppState of(BuildContext context) {
    return context.findAncestorStateOfType<AppState>()!;
  }
}

class AppState extends State<App> {
  final _appRouter = WebAppRouter();
  PageRouteInfo? _userRoute;
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    authService.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      routerDelegate: AutoRouterDelegate.declarative(
        _appRouter,
        onRoutes: (urlState, initial) async {
          print(urlState.path);
          _userRoute = null;
          if (urlState.topRoute?.routeName == UserRoute.name) {
            _userRoute = urlState.topRoute;
          }

          return null;
        },
        routes: (_) => [
          if (!authService.isAuthenticated)
            LoginRoute(onLoginResult: (_) {
              authService.isAuthenticated = true;
            })
          else ...[
            HomeRoute(
              navigate: () {
                setState(() {
                  _userRoute = UserRoute(id: 1);
                });
              },
            ),
            if (_userRoute != null) UserRoute(id: 3),
          ],
        ],
        onPopRoute: (route, _) {
          if (route.routeName == UserRoute.name) {
            _userRoute = null;
          }
        },
      ),
      routeInformationParser: _appRouter.defaultRouteParser(),
      builder: (_, router) {
        return ChangeNotifierProvider(
          create: (_) => AuthService(),
          child: router,
        );
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  final void Function(bool isLoggedIn)? onLoginResult;

  const LoginPage({Key? key, this.onLoginResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // onWillPop: () {
      //   onLoginResult?.call(false);
      //   return SynchronousFuture(true);
      // },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Login to continue'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // context.read<AuthService>().isAuthenticated = true;
              onLoginResult?.call(true);
            },
            child: Text('Login'),
          ),
        ),
      ),
    );
  }
}
