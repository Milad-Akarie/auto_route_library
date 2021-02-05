import 'package:auto_route/auto_route.dart';

import '../books/routes.dart';
import '../dashboard_page.dart';
import '../settings/settings.dart';
import '../unknown_page.dart';
import '../users/routes.dart';

export 'web_router.gr.dart';

@CustomAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(
      path: '/',
      page: DashboardPage,
      children: [
        RedirectRoute(path: '', redirectTo: 'books'),
        booksRoute,
        usersRoute,
        AutoRoute(path: 'settings', page: SettingsPage),
      ],
    ),
    AutoRoute(path: '*', page: UnknownPage),
  ],
)
class $WebAppRouter {}
