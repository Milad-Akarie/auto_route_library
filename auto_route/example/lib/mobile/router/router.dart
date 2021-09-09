import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/books/book_details_page.dart';
import 'package:example/mobile/screens/books/book_list_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screens/home_page.dart';
import '../screens/login_page.dart';
import '../screens/profile/routes.dart';
import '../screens/settings.dart';
import '../screens/user-data/routes.dart';
import 'auth_guard.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
export 'router.gr.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page|Dialog,Route',
  routes: <AutoRoute>[
    // app stack
    AutoRoute<String>(
      path: '/',
      page: HomePage,
      children: [
        AutoRoute(
          path: 'books',
          page: EmptyRouterPage,
          name: 'BooksTab',
          children: [
            AutoRoute(path: '', page: BookListPage),
            AutoRoute(
              path: ':id',
              usesPathAsKey: true,
              page: BookDetailsPage,
              guards: [AuthGuard],
            ),
          ],
        ),
        profileTab,
        AutoRoute(
          path: 'settings/:tab',
          page: SettingsPage,
          name: 'SettingsTab',
        ),
      ],
    ),
    userDataRoutes,
    // auth

    DialogModalRoute(page: LoginPage, path: '/login'),

    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $RootRouter {}

// CustomRoute is coming from auto_route
class DialogModalRoute<T> extends CustomRoute<T> {
  const DialogModalRoute({required Type page, String? path})
      : super(
          page: page,
          path: path,
          customRouteBuilder: dialogRouteBuilder,
        );

  // must be static and public
  static Route<T> dialogRouteBuilder<T>(
    BuildContext context,
    Widget child,
    CustomPage<T> page,
  ) {
    // DialogRoute is coming from flutter material
    if (kIsWeb) {
      return DialogRoute<T>(
        context: context,
        settings: page,
        builder: (context) => child,
      );
    } else {
      return MaterialPageRoute<T>(
        settings: page,
        builder: (context) => child,
      );
    }
  }
}

// typedef CustomRouteBuilder = Route<T> Function<T>(BuildContext context, Widget child, CustomPage page);

Route<T> myCustomRouteBuilder<T>(BuildContext context, Widget child, CustomPage<T> page) {
  return PageRouteBuilder(
      fullscreenDialog: page.fullscreenDialog,
      // this's important
      settings: page,
      pageBuilder: (_, __, ___) => child);
}
