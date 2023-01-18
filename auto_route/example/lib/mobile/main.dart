import 'package:example/data/db.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:example/mobile/router/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final authService = AuthService();

  final _rootRouter = RootRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _rootRouter.config(),
      theme: ThemeData.dark().copyWith(
        pageTransitionsTheme: PageTransitionsTheme(builders: {
          TargetPlatform.iOS: NoShadowCupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        }),
      ),
      builder: (_, router) {
        return ChangeNotifierProvider<AuthService>(
          create: (_) => authService,
          child: BooksDBProvider(
            child: router!,
          ),
        );
      },
    );
  }
}
