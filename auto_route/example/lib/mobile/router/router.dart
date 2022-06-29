import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/books/book_details_page.dart';
import 'package:example/mobile/screens/books/book_list_page.dart';
import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../screens/login_page.dart';
import '../screens/profile/routes.dart';
import '../screens/settings.dart';
import '../screens/user-data/routes.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page|Screen,Route',
  routes: <AutoRoute>[
    // app stack
    AutoRoute<String>(
      path: '/',
      page: HomePage,
      // guards: [AuthGuard],
      children: [
        AutoRoute(
          path: 'books',
          page: EmptyRouterScreen,
          name: 'BooksTab',
          initial: true,
          maintainState: true,
          children: [
            AutoRoute(
              path: '',
              page: BookListScreen,
            ),
            AutoRoute(path: ':id', page: BookDetailsPage, fullscreenDialog: true, children: [AutoRoute(page: InheritedParamScreen)]
                // meta: {'hideBottomNav': true},
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

    AutoRoute(page: LoginPage, path: '/login'),
    RedirectRoute(path: '*', redirectTo: '/'),
  ],
)
class $RootRouter {}

class InheritedParamScreen extends StatelessWidget {
  const InheritedParamScreen({Key? key, @pathParam required String id, @queryParam String nonPathParam = 'defa'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}


