import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:example/mobile/screens/books/book_list_page.dart';
import 'package:example/mobile/screens/books/routes.dart';
import 'package:example/mobile/screens/home_page.dart';
import 'package:example/mobile/screens/login_page.dart';
import 'package:example/mobile/screens/profile/profile_page.dart';
import 'package:example/mobile/screens/profile/routes.dart';
import 'package:example/mobile/screens/settings.dart';
import 'package:example/mobile/screens/settings_tab_page.dart';
import 'package:example/mobile/screens/user-data/routes.dart';

export 'router.gr.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(
      path: '/',
      page: HomePage,
      // guards: [AuthGuard],
      usesTabsRouter: true,
      children: [
        // RedirectRoute(path: '', redirectTo: 'books'),
        booksTab,
        profileTab,
        AutoRoute(
          path: 'settings',
          page: SettingsTabPage,
          name: 'SettingsTab',
          usesTabsRouter: true,
          children: [
            AutoRoute(
              name: 'BookSettingsTab',
              path: '',
              page: BookListPage,
            ),
            AutoRoute(
              name: 'ProfileSettingsTab',
              path: 'profile',
              page: ProfilePage,
            ),
          ],
        ),
      ],
    ),
    userDataRoutes,
    AutoRoute(path: '/profile/books/details', page: SettingsPage),
    AutoRoute(path: '/login', page: LoginPage, fullscreenDialog: false),
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $AppRouter {}
