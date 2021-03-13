import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/user-data/sinlge_field_page.dart';
import 'package:example/mobile/screens/user-data/user_data_page.dart';

import 'data_collector.dart';

const userDataRoutes = AutoRoute(
  path: '/user-data',
  page: UserDataCollectorPage,
  children: [
    CustomRoute(
      page: SingleFieldPage,
      transitionsBuilder: TransitionsBuilders.slideRightWithFade,
    ),
    CustomRoute(
      page: UserDataPage,
      transitionsBuilder: TransitionsBuilders.slideRightWithFade,
    ),
  ],
);
