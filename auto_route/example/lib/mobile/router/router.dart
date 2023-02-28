//

import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:example/mobile/screens/profile/routes.dart';

@AutoRouterConfig()
class RootRouter extends $RootRouter {
  @override
  RouteType get defaultRouteType => RouteType.material();

  @override
  final List<AutoRoute> routes = [
    AutoRoute(
      page: HomeRoute.page,
      path: '/',
      // guards: [AuthGuard()],
      children: [
        RedirectRoute(path: '', redirectTo: 'books'),
        AutoRoute(
          path: 'books',
          page: BooksTab.page,
          maintainState: true,
          children: [
            AutoRoute(
              path: '',
              page: BookListRoute.page,
              title: (ctx, _) => 'Books list',
            ),
            CustomRoute(
              path: ':id',
              page: BookDetailsRoute.page,
              durationInMilliseconds: 0,
              reverseDurationInMilliseconds: 0,
              opaque: false,
              title: (ctx, data) {
                return 'Book Details ${data.pathParams.get('id')}';
              },
            ),
          ],
        ),
        profileTab,
        AutoRoute(
          path: 'settings/:tab',
          page: SettingsTab.page,
        ),
      ],
    ),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    RedirectRoute(path: '*', redirectTo: '/'),
  ];
}

@RoutePage(name: 'BooksTab')
class BooksTabPage extends AutoRouter {
  const BooksTabPage({super.key});
}

@RoutePage(name: 'ProfileTab')
class ProfileTabPage extends AutoRouter {
  const ProfileTabPage({super.key});
}
