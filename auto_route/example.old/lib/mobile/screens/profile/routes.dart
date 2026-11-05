import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.dart';
import 'package:example/mobile/router/router.gr.dart';

/// Route of the profile tab: a profile page and a my books page below it.
final profileRoute = AutoRoute(
  path: 'profile',
  page: kProfileTab.page,
  children: [
    AutoRoute(path: '', page: ProfileRoute.page),
    AutoRoute(path: 'my-books', page: MyBooksRoute.page),
  ],
);
