import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:example/mobile/screens/book_details_page.dart';
import 'package:example/mobile/screens/book_list_page.dart';
import 'package:example/mobile/screens/home_page.dart';
import 'package:example/mobile/screens/login_page.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AutoRoute(path: '/', page: HomePage),
    AutoRoute(page: BookListPage),
    AutoRoute(path: '/books/:id', page: BookDetailsPage, guards: [AuthGuard]),
    AutoRoute(path: '/login', page: LoginPage),
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $MyRouterConfig {}
