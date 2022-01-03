import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:flutter/material.dart';

import '../test_page.dart';

part 'router.gr.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: [
    AutoRoute(page: FirstPage, initial: true),
    AutoRoute(name: 'SecondRoute', page: EmptyRouterPage, children: [
      AutoRoute(page: SecondNested1Page, initial: true),
      AutoRoute(page: SecondNested2Page),
    ]),
  ],
)
class AppRouter extends _$AppRouter {}

class SecondNested1Page extends TestPage {}

class SecondNested2Page extends TestPage {}
