

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: AppRouterDelegate(),
      routeInformationParser: AppRouteInformationParser(),
    );
  }
}

class AppRoutePath {
  final bool isHomePage;
  AppRoutePath.home() : isHomePage = true;
  AppRoutePath.details() : isHomePage = false;
}

class AppRouteInformationParser extends RouteInformationParser<AppRoutePath> {
  @override
  Future<AppRoutePath> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation.uri.toString() == '/details' ? AppRoutePath.details() : AppRoutePath.home();
  }

  @override
  RouteInformation? restoreRouteInformation(AppRoutePath path) {
    return RouteInformation(uri: Uri(path: path.isHomePage ? '/' : '/details'));
  }
}

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool isHomePage = true;

  @override
  AppRoutePath get currentConfiguration => isHomePage ? AppRoutePath.home() : AppRoutePath.details();

  void _goToDetails() {
    isHomePage = false;
    notifyListeners();
  }

  void _goHome() {
    isHomePage = true;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(key: ValueKey('HomePage'), child: HomePage(onNavigate: _goToDetails)),
        if (!isHomePage) MaterialPage(key: ValueKey('DetailsPage'), child: DetailsPage(onBack: _goHome)),
      ],

      onDidRemovePage: (page) {
       isHomePage = true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    isHomePage = configuration.isHomePage;
  }
}

class HomePage extends StatelessWidget {
  final VoidCallback onNavigate;
  HomePage({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: onNavigate,
          child: Text('Go to Details'),
        ),
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  final VoidCallback onBack;
  DetailsPage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details Page')),
      body: PopScope(
        onPopInvokedWithResult: (didPop,result){
          print('didPop: $didPop, result: $result');
        },
        child: Center(
          child: ElevatedButton(
            onPressed: onBack,
            child: Text('Back to Home'),
          ),
        ),
      ),
    );
  }
}
