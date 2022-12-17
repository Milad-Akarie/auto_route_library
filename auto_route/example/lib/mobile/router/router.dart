//

import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:example/mobile/router/router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page|Screen,Route')
class RootRouter extends $RootRouter {
  @override
  final List<AutoRoute> routes = [
    AutoRoute(
      path: '/',
      name: HomeRoute,
    ),
    // AutoRoute(path: '/books', name: BookListRoute, children: [
    //   AutoRoute(name: BookDetailsRoute),
    // ]),
    AutoRoute(name: HomeRoute, children: [
      AutoRoute(name: ProfileRoute),
      AutoRoute(
        name: MyBooksRoute,
      ),
    ]),
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
