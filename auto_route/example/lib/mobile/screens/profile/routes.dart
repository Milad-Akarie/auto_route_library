import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/profile/my_books_page.dart';
import 'package:auto_route/empty_router_widgets.dart';
import 'profile_page.dart';

const profileTab = AutoRoute(
  path: 'profile',
  name: 'ProfileTab',
  page: EmptyRouterPage,
  children: [
    AutoRoute(path: '', page: ProfilePage),
    AutoRoute(path: 'my-books', page: MyBooksPage),
  ],
);
