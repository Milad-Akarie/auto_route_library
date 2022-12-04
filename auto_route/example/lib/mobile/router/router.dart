import 'package:auto_route/auto_route.dart';
import '../screens/home_page.dart';
import '../screens/login_page.dart';
import '../screens/settings.dart';

@AutoRouterAnnotation(
  replaceInRouteName: 'Page|Screen,Route',
)
class $RootRouter extends RootStackRouter{

  @override
  List<AutoRouteConfig> get routes => [
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
