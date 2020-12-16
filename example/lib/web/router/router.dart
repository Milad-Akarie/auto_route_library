import 'package:auto_route/auto_route.dart';
import 'package:example/web/screens/book_details_page.dart';
import 'package:example/web/screens/book_list_page.dart';
import 'package:example/web/screens/dashboard_page.dart';
import 'package:example/web/screens/settings_page.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AutoRoute(
      path: '/',
      page: DashboardPage,
      children: [
        AutoRoute(
          path: 'books',
          page: AutoRouter,
          name: 'BooksTabs',
          children: [
            AutoRoute(path: '', page: BookListPage),
            AutoRoute(path: ':id', page: BookDetailsPage),
          ],
        ),
        AutoRoute(
          path: 'settings',
          page: AutoRouter,
          name: 'SettingsTab',
          children: [AutoRoute(path: '', page: SettingsPage)],
        ),
      ],
    ),
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $WebRouterConfig {}
