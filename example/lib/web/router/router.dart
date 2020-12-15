import 'package:auto_route/auto_route.dart';
import 'package:example/web/screens/book_details_page.dart';
import 'package:example/web/screens/book_list_page.dart';
import 'package:example/web/screens/dashboard_page.dart';
import 'package:example/web/screens/settings_page.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AutoRoute(path: '/', page: DashboardPage, children: [
      RedirectRoute(path: '', redirectTo: 'books'),
      AutoRoute(path: 'books', page: BookListPage, children: [
        RedirectRoute(path: '', redirectTo: '1'),
        AutoRoute(path: ':id', page: BookDetailsPage),
      ]),
      AutoRoute(path: 'settings', page: SettingsPage),
    ]),
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $WebRouterConfig {}
