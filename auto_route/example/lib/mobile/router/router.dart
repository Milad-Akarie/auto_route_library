import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';

@AutoRouterAnnotation(replaceInRouteName: 'Page|Screen,Route')
class RootRouter extends $RootRouter {
  @override
  final List<AutoRouteEntry> routes = [
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: BookListRoute.page),

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
    // RedirectRoute(path: '*', redirectTo: '/'),
  ];
}
