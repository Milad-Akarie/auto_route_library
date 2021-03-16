import 'package:example/mobile/router/auth_guard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../data/db.dart';
import 'router/router.gr.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final _appRouter = AppRouter(authGuard: AuthGuard());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      routerDelegate: _appRouter.delegate(
        initialDeepLink: '/books/4',
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
