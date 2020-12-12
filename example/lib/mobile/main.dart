import 'package:auto_route/auto_route.dart';
import 'package:example/data/books_data.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // create an instance of the generated router config
  final routerConfig = MyRouterConfig(authGuard: AuthGuard());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Books App',
      theme: ThemeData.dark(),
      routerDelegate: RootRouterDelegate(
        routerConfig,
        // initialDeepLink: '/books/5',
        // same as
        // defaultHistory: [
        //   HomePageRoute(),
        //   BookListPageRoute(),
        //   BookDetails(id: 5),// ],
      ),
      routeInformationParser: routerConfig.nativeRouteParser,
      builder: (_, router) {
        return Provider<BooksDB>(
          create: (_) => BooksDB(),
          child: router,
        );
      },
    );
  }
}
