import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/book_details_page.dart';
import 'package:example/mobile/screens/book_list_page.dart';
import 'package:example/mobile/screens/home_page.dart';
import 'package:example/mobile/screens/settings_page.dart';

export 'router.gr.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AutoRoute(
      path: '/',
      page: HomePage,
      usesTabsRouter: true,
      children: [
        AutoRoute(
          path: 'books',
          page: TabRouterPage,
          name: 'BooksTab',
          children: [
            AutoRoute(path: 'list', page: BookListPage),
            AutoRoute(path: 'list/:id', page: BookDetailsPage),
          ],
        ),
        AutoRoute(
          path: 'settings',
          page: TabRouterPage,
          name: 'SettingsTab',
          children: [AutoRoute(path: '', page: SettingsPage)],
        ),
      ],
    ),
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $MyRouterConfig {}
