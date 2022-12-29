//

import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:example/mobile/router/router.gr.dart';

@AutoRouterConfig()
class RootRouter extends $RootRouter {
  @override
  final List<AutoRoute> routes = [
    AutoRoute(
      path: '/',
      page: HomeRoute.page,
    ),
    AutoRoute(page: HomeRoute.page, children: [
      AutoRoute(page: ProfileRoute.page),
      AutoRoute(
        page: MyBooksRoute.page,
      ),
    ]),
    ...?AuthGuard.childList
  ];
}

// AutoRoute(
//
//   page: HomePage,
//   children: [
//     // AutoRoute(
//     //   path: 'books',
//     //   page: AutoRouter.emptyPage,
//     //   name: 'BooksTab',
//     //   initial: true,
//     //   maintainState: true,
//     //   children: [
//     //     AutoRoute(
//     //       path: '',
//     //       page: BookListScreen,
//     //     ),
//     //     AutoRoute(
//     //       path: ':id',
//     //       page: BookDetailsPage,
//     //       fullscreenDialog: true,
//     //     ),
//     //   ],
//     // ),
//     // profileTab,
//     AutoRoute(
//       path: 'settings/:tab',
//       page: SettingsPage,
//       name: 'SettingsTab',
//     ),
//   ],
// ),
//
// // auth
// AutoRoute(page: LoginPage, path: '/login'),
// RedirectRoute(path: '*', redirectTo: '/'),/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine/n//AddedLine
