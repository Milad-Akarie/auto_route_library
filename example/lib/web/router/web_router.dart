import 'package:auto_route/auto_route.dart';
import 'package:example/web/books/routes.dart';
import 'package:example/web/settings/settings.dart';
import 'package:example/web/unknown_page.dart';
import 'package:example/web/users/routes.dart';

import '../dashboard_page.dart';

export 'web_router.gr.dart';

@CustomAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(
      path: '/',
      page: DashboardPage,
      children: [
        // RedirectRoute(path: 'books', redirectTo: 'books'),
        booksRoute,
        usersRoute,
        AutoRoute(path: 'settings', page: SettingsPage),
      ],
    ),
    AutoRoute(path: '*', page: UnknownPage),
  ],
)
class $WebAppRouter {}
