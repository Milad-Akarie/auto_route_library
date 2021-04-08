import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/login_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../data/db.dart';
import 'router/router.gr.dart';

void main() {
  runApp(MyApp());

  // var root = Notifier('root');
  // root.addListener(() {
  //   print('notifying root ${root.segments}');
  // });
  // var parent = Notifier('parent', root);
  // parent.addListener(() {
  //   print('notifying parent');
  // });
  //
  // parent.notifyRoot();
  // var child = Notifier('child', parent);
  // child.addListener(() {
  //   print('notifying child');
  // });
  // child.notifyRoot();
}

class Notifier with ChangeNotifier {
  final String name;
  final Notifier? parent;
  final List<Notifier> children = [];

  Notifier(this.name, [this.parent]) {
    if (parent != null) {
      parent!.attachChild(this);
    }
  }
  void attachChild(Notifier notifer) {
    children.add(notifer);
  }

  List<String> get segments {
    return [name, if (children.isNotEmpty) ...children.first.segments];
  }

  void notifyAll() {
    notifyListeners();
    children.forEach((i) => i.notifyAll());
  }

  void notifyRoot() => root.notifyAll();

  Notifier get root => parent?.root ?? this;

  void addChildrenAwareListener(VoidCallback cb) {
    addListener(cb);
    children.forEach((notifier) => notifier.addChildrenAwareListener(cb));
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appRouter = AppRouter();

  var showHome = false;

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
        //     if (showHome)
        //       HomeRoute()
        //     else
        //       LoginRoute(
        //         onLoginResult: (loggedIn) {
        //           setState(() {
        //             showHome = loggedIn;
        //           });
        //         },
        //       ),
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
