//

import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:example/mobile/screens/profile/routes.dart';

@AutoRouterConfig(generateForDir: ['lib/mobile'])
class RootRouter extends $RootRouter {
  @override
  RouteType get defaultRouteType => RouteType.custom(
        reverseDurationInMilliseconds: 800,
        transitionsBuilder: (ctx, animation1, animation2, child) {
          // print('Anim1 ${animation1.value}');
          print('Anim2 ${animation2.value}');
          return child;
        },
      );

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
            AutoRoute(
              path: ':id',
              page: BookDetailsRoute.page,
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
