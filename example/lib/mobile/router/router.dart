import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/books/routes.dart';
import 'package:example/mobile/screens/home_page.dart';
import 'package:example/mobile/screens/login_page.dart';
import 'package:example/mobile/screens/profile/routes.dart';
import 'package:example/mobile/screens/settings.dart';
import 'package:example/mobile/screens/user-data/routes.dart';

export 'router.gr.dart';

@CupertinoAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(
      path: '/',
      page: HomePage,
      usesTabsRouter: true,
      children: [
        booksTab,
        profileTab,
        AutoRoute(path: 'settings', page: SettingsPage, name: 'SettingsTab'),
      ],
    ),
    userDataRoutes,
    AutoRoute(path: '/login', page: LoginPage, fullscreenDialog: false),
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $AppRouter {}
