import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/user-data/single_field_page.dart';
import 'package:example/mobile/screens/user-data/user_data_page.dart';

import 'data_collector.dart';

const userDataRoutes = AutoRoute<UserData>(
  path: '/user-data',
  page: UserDataCollectorPage,
  children: [
    CustomRoute(
      path: 'name',
      name: 'NameFieldRoute',
      page: SingleFieldPage,
      transitionsBuilder: TransitionsBuilders.slideRightWithFade,
    ),
    CustomRoute(
      path: 'favorite-book',
      page: SingleFieldPage,
      name: 'FavoriteBookFieldRoute',
      transitionsBuilder: TransitionsBuilders.slideRightWithFade,
    ),
    CustomRoute(
      path: 'results',
      page: UserDataPage,
      transitionsBuilder: TransitionsBuilders.slideRightWithFade,
    ),
  ],
);
