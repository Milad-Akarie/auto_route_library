import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/web_auth_guard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'router/web_router.gr.dart';

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
  final _appRouter = WebAppRouter();
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
      routeInformationProvider: AutoRouteInformationProvider(),
      routerDelegate: AutoRouterDelegate(
        _appRouter,
        // initialDeepLink: '/user/5',
        // onNavigate: (urlState, initial) async {
        //   print(urlState.path);
        //   _userId = -1;
        //   if (urlState.topMatch?.routeName == UserRoute.name) {
        //     _userId = urlState.topMatch!.pathParams.getInt('userID');
        //   }
        //   return null;
        // },
        // routes: (_) => [
        //   if (!authService.isAuthenticated)
        //     LoginRoute(onLoginResult: (_) {
        //       print('onLogin');
        //       authService.isAuthenticated = true;
        //     })
        //   else ...[
        //     HomeRoute(
        //       navigate: () {
        //         setState(() {
        //           _userId = 1;
        //         });
        //       },
        //     ),
        //     if (_userId != -1) UserRoute(id: _userId),
        //   ],
        // ],
        // onPopRoute: (route, _) {
        //   if (route.routeName == UserRoute.name) {
        //     _userId = -1;
        //   }
        // },
      ),
      routeInformationParser: _appRouter.defaultRouteParser(),
      // builder: (_, router) {
      //   return ChangeNotifierProvider(
      //     create: (_) => AuthService(),
      //     child: router,
      //   );
      // },
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
