import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/books/book_details_page.dart';
import 'package:example/mobile/screens/books/book_list_page.dart';
import 'package:example/mobile/screens/tabbar/page_one_Screen.dart';
import 'package:example/mobile/screens/tabbar/tabbar_screen.dart';

import '../screens/home_page.dart';
import '../screens/login_page.dart';
import '../screens/profile/routes.dart';
import '../screens/settings.dart';
import '../screens/tabbar/page_two_screen.dart';
import '../screens/user-data/routes.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page|Dialog,Route',
  routes: <AutoRoute>[
    // app stack
    AutoRoute<String>(
      path: '/',
      page: HomePage,
      // guards: [AuthGuard],
      children: [
        AutoRoute(
          path: 'books',
          page: EmptyRouterPage,
          name: 'BooksTab',
          initial: true,
          children: [
            AutoRoute(
              path: '',
              page: BookListPage,
            ),
            AutoRoute(
              path: ':id',
              page: BookDetailsPage,
              meta: {'hideBottomNav': true},
            ),
          ],
        ),
        profileTab,
        AutoRoute(
          path: 'settings/:tab',
          page: SettingsPage,
          name: 'SettingsTab',
        ),
      ],
    ),
    userDataRoutes,
    // auth
    AutoRoute(page: LoginPage, path: '/login'),
    RedirectRoute(path: '*', redirectTo: '/'),
    AutoRoute(
        name: 'TabbarRoute',
        path: '/tabbar',
        page: TabbarScreen,
        children: [
          AutoRoute(name: 'PageOneRoute', path: 'page-1', page: PageOneScreen),
          AutoRoute(name: 'PageTowRoute', path: 'page-2', page: PageTwoScreen),
        ])
  ],
)
class $RootRouter {}
