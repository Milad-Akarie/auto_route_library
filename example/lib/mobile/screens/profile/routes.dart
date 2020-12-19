import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/profile/profile_page.dart';

import 'my_books_page.dart';

const profileTab = AutoRoute(
  path: 'profile',
  name: 'ProfileTab',
  page: EmptyRouterPage,
  children: [
    RedirectRoute(path: '', redirectTo: 'me'),
    AutoRoute(path: 'me', page: ProfilePage),
    AutoRoute(path: 'me/books', page: MyBooksPage),
  ],
);
