import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../test_page.dart';

part 'router.gr.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: [
    PageInfo(page: FirstPage, initial: true),
    PageInfo(page: SecondPage),
    PageInfo(page: ThirdPage),
  ],
)
class AppRouter extends _$AppRouter {}
