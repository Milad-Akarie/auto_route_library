import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/books/book_details_page.dart';
import 'package:example/mobile/screens/books/book_list_page.dart';

import '../screens/home_page.dart';
import '../screens/login_page.dart';
import '../screens/profile/routes.dart';
import '../screens/settings.dart';
import '../screens/user-data/routes.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page|Dialog,Route',
  routes: <AutoRoute>[
    // app stack

    AutoRoute<String>(
      path: '/',
      page: HomePage,
      // guards: [nAuthGuard],
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
  ],
)
class $RootRouter {}
