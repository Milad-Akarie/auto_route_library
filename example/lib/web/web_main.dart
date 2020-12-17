import 'package:auto_route/auto_route.dart';
import 'package:example/data/books_data.dart';
import 'package:example/web/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final booksDb = BooksDB();

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final routerConfig = WebRouterConfig();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      routerDelegate: RootRouterDelegate(
        routerConfig,
        initialDeepLink: '/bookshhgj/kjhkj3',
        // defaultHistory: [
        //   DashboardPageRoute(children: [
        //     BooksTabs(
        //       children: [
        //         BookListPageRoute(),
        //         BookDetailsPageRoute(id: 3),
        //       ],
        //     )
        //   ])
        // ],
      ),
      routeInformationParser: routerConfig.nativeRouteParser,
    );
  }
}
