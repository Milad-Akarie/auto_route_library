import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:example/mobile/router/app_router.gr.dart';
import 'package:example/mobile/router/auth_service.dart';
import 'package:example/mobile/screens/profile/routes.dart';
import 'package:material_ui/material_ui.dart';

// Route names here are written as the paths they stand for.
/// Routes of the mobile example app.
///
/// Holds a home page with books, profile and settings tabs, and a login page.
/// The book details route is guarded: it sends users who are not signed in to
/// the login page.
@AutoRouterConfig(generateForDir: ['lib/mobile'])
class AppRouter extends RootStackRouter {
  /// Takes the [AuthService] that the guard of the book details route asks.
  new(this.authService);

  /// The sign-in state that decides whether book details can be opened.
  final AuthService authService;

  @override
  late final List<AutoRoute> routes = [
    AutoRoute(
      page: HomeRoute.page,
      initial: true,
      children: [
        AutoRoute(
          path: 'books',
          page: kBooksTab.page,
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
                }
                unawaited(resolver.redirectUntil(LoginRoute()));
              },
              title: (ctx, data) {
                return 'Book Details ${data.params.get('id')}';
              },
            ),
          ],
        ),
        profileRoute,
        AutoRoute(path: 'settings/:tab', page: SettingsTab.page),
      ],
    ),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    RedirectRoute(path: '*', redirectTo: '/'),
  ];
}

/// Shell route of the books tab, which only holds the book pages.
const kBooksTab = EmptyShellRoute('BooksTab');

/// Shell route of the profile tab, which only holds the profile pages.
const kProfileTab = EmptyShellRoute('ProfileTab');

/// A named route that can build its own page.
abstract class RouteDef {
  /// Takes the route [name] and, optionally, its [path].
  const new(this.name, {this.path});

  /// The name of this route.
  final String name;

  /// The path of this route, or `null` when it has none of its own.
  final String? path;

  /// Builds the page for this route from its [data].
  Widget build(BuildContext context, RouteData<Object?> data);

  /// Returns the definition that matches the route [data].
  RouteDef buildFromData(RouteData<Object?> data);
}
