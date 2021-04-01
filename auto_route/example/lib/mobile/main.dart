import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../data/db.dart';
import 'router/router.gr.dart';

void main() {
  runApp(MyApp());
  // var parent = Notifier('parent');
  // var child = Notifier('child', parent);
  // var subChild = Notifier('subChild', child);
  //
  // subChild.notifyListeners();
}

// class Notifier with ChangeNotifier {
//   final String name;
//   final Notifier? parent;
//
//   Notifier(this.name, [this.parent]);
//
//   @override
//   void notifyListeners() {
//     super.notifyListeners();
//     print('notifying $name');
//     if (parent != null) {
//       parent!.notifyListeners();
//     }
//   }
// }

class MyApp extends StatelessWidget {
  final _appRouter = AppRouter();
  var showHome = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      routerDelegate: AutoRouterDelegate(
        _appRouter,
        // initialDeepLink: '/home/books/2'
        // initialRoutes: [
        //   HomeRoute(),
        // ],
        // routes: (context) {
        //   return [
        //     WelcomeRoute(),
        //     HomeRoute(),
        //   ];
        // },
        // onPopRoute: (route) {
        //   if (route.routeName == HomeRoute.name) {
        //     showHome = false;
        //   }
        // },
      ),
      routeInformationParser: _appRouter.defaultRouteParser(),
      builder: (_, router) {
        return BooksDBProvider(
          child: router!,
        );
      },
    );
  }
}
