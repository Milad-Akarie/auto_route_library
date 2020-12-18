import 'package:auto_route/auto_route.dart';
import 'package:example/data/books_data.dart';
import 'package:example/mobile/router/router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final booksDb = BooksDB();

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final routerConfig = MyRouterConfig();

  @override
  Widget build(BuildContext context) {
    var matcher = routerConfig.root.matcher;
    // print(matcher.match('/books/list/4', includePrefixMatches: true));
    return MaterialApp.router(
      theme: ThemeData.dark(),
      routerDelegate: RootRouterDelegate(
        routerConfig,
        initialDeepLink: '/books/list/2?queryFilter=bar',
      ),
      routeInformationParser: routerConfig.defaultRouteParser(),
      builder: (_, router) {
        return Provider(
          create: (_) => BooksDB(),
          child: router,
        );
      },
    );
  }
}
