import 'package:auto_route/auto_route.dart';

import '../screens/books/routes.dart';
import '../screens/home_page.dart';
import '../screens/login_page.dart';
import '../screens/profile/routes.dart';
import '../screens/settings.dart';
import '../screens/user-data/routes.dart';

export 'router.gr.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    // app stack
    CustomRoute(
      transitionsBuilder: TransitionsBuilders.fadeIn,
      path: '/',
      page: EmptyRouterPage,
      name: 'AppRoute',
      // guards: [AuthGuard],
      children: [
        AutoRoute(
          path: '',
          page: HomePage,
          children: [
            booksTab,
            profileTab,
            AutoRoute(
              path: 'settings/:tab',
              page: SettingsPage,
              name: 'SettingsTab',
            ),
          ],
        ),
        userDataRoutes,
      ],
    ),

    // auth
    AutoRoute(
      path: '/login',
      page: LoginPage,
    ),
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $RootRouter {}
