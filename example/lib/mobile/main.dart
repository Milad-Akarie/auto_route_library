import 'package:example/data/books_data.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:example/mobile/router/router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final appRouter = AppRouter(authGuard: AuthGuard());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      routerDelegate: appRouter.delegate(),
      routeInformationParser: appRouter.defaultRouteParser(),
      builder: (_, router) {
        return Provider(
          create: (_) => BooksDB(),
          child: router,
        );
      },
    );
  }
}
