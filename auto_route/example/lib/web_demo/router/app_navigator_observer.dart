//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/app_router.dart';
import 'package:flutter/material.dart';

class AppNavigatorObserver extends AutoRouterObserver {
  final AppRouter _appRouter;

  AppNavigatorObserver({required AppRouter appRouter}) : _appRouter = appRouter;

  @override
  void didPush(Route route, Route? previousRoute) {
    print('didPush ${route.settings.name}');
    _printStack();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    print('didPop ${route.settings.name}');
    _printStack();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    print('didRemove ${route.settings.name}');
    _printStack();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    print('didReplace ${newRoute?.settings.name}');
    _printStack();
  }

  void _printStack() {
    _appRouter.printRouterStack();
  }
}