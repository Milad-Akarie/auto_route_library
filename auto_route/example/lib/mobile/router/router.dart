import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:example/mobile/screens/profile/routes.dart';
import 'package:material_ui/material_ui.dart';

// ignore_for_file: constant_identifier_names
@AutoRouterConfig(generateForDir: ['lib/mobile'])
class AppRouter extends RootStackRouter {
  AppRouter(this.authService);
  final AuthService authService;

  @override
  late final List<AutoRoute> routes = [
    AutoRoute(
      page: HomeRoute.page,
      initial: true,
      children: [
        AutoRoute(
          path: 'books',
          page: BooksTab.page,
          initial: true,
          children: [
            AutoRoute(
              path: '',
              page: BookListRoute.page,
              title: (ctx, _) => 'Books list',
            ),
            AutoRoute.guarded(
              path: ':id',
              page: BookDetailsRoute.page,
              onNavigation: (resolver, _) {
                if (authService.isAuthenticated) {
                  return resolver.next();
                } else {
                  resolver.redirectUntil(LoginRoute());
                }
              },
              title: (ctx, data) {
                return 'Book Details ${data.params.get('id')}';
              },
            ),
          ],
        ),
        profileRoute,
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

const BooksTab = EmptyShellRoute('BooksTab');
const ProfileTab = EmptyShellRoute('ProfileTab');

abstract class RouteDef {
  RouteDef(this.name, {this.path});
  final String name;
  final String? path;

  Widget build(BuildContext context, RouteData data);

  RouteDef buildFromData(RouteData data) {
    return this;
  }
}
