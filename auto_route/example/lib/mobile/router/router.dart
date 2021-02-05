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
    AutoRoute(
      path: '/',
      page: HomePage,
      // guards: [AuthGuard],
      usesTabsRouter: true,
      children: [
        RedirectRoute(path: '', redirectTo: 'books'),
        booksTab,
        profileTab,
        AutoRoute(
          path: 'settings',
          page: SettingsPage,
          name: 'SettingsTab',
        ),
      ],
    ),
    userDataRoutes,
    AutoRoute(path: '/login', page: LoginPage, fullscreenDialog: false),
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $AppRouter {}
