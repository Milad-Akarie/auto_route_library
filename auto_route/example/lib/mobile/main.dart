import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/db.dart';
import 'router/router.gr.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      routerDelegate: appRouter.delegate(),
      routeInformationParser: appRouter.defaultRouteParser(),
      builder: (_, router) {
        return BooksDBProvider(
          child: router,
        );
      },
    );
  }
}
