import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../test_page.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  deferredLoading: true,
  routes: [
    PageInfo(page: FirstPage, initial: true),
    PageInfo(name: 'SecondRoute', page: EmptyRouterPage, children: [
      PageInfo(page: SecondNested1Page, initial: true),
      PageInfo(page: SecondNested2Page),
    ]),
  ],
)
class $AppRouter {}

class EmptyRouterPage extends AutoRouter {
  const EmptyRouterPage({Key? key}) : super(key: key);
}

class SecondNested1Page extends TestPage {
  const SecondNested1Page({Key? key}) : super(key: key);
}

class SecondNested2Page extends TestPage {
  const SecondNested2Page({Key? key}) : super(key: key);
}
