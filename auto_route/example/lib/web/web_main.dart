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
  UrlState? urlState;
  final rootRoutes = <PageRouteInfo>[];
  PageRouteInfo? _notFoundRoute;
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
        // onInitialRoutes: (urlState) {
        //   this.urlState = urlState;
        //   if (urlState.hasSegments) {
        //     rootRoutes.clear();
        //     rootRoutes.addAll(urlState.segments);
        //   }
        // },
        routes: (context) {
          return [
            if (!authService.isAuthenticated)
              LoginRoute(onLoginResult: (_) {
                authService.isAuthenticated = true;
              })
            else ...[
              if (rootRoutes.isEmpty)
                HomeRoute(navigate: () {
                  setState(() {
                    rootRoutes.add(UserRoute(id: 4));
                  });
                }),
              ...rootRoutes,
            ],
          ];
        },
        onPopRoute: (route, _) {
          if (route.routeName == UserRoute.name) {
            rootRoutes.remove(route);
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
              context.read<AuthService>().isAuthenticated = true;
              onLoginResult?.call(true);
            },
            child: Text('Login'),
          ),
        ),
      ),
    );
  }
}
