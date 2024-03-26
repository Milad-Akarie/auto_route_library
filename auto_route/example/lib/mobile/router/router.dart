//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:example/mobile/screens/home_page.dart';
import 'package:example/mobile/screens/profile/routes.dart';
import 'package:example/mobile/screens/settings_page.dart';
import 'package:example/web_demo/web_main.dart';

@AutoRouterConfig(generateForDir: ['lib/mobile'])
class RootRouter extends $RootRouter {
  @override
  final List<RouteDef> routes = [
    RouteDef(
      page: HomeRoute.page,
      path: '/',
      children: [
        RedirectRoute(path: '', redirectTo: 'books'),
        RouteDef(
          path: 'books',
          page: BooksTab.page,
          maintainState: true,
          children: [
            RouteDef(
              path: '',
              page: BookListRoute.page,
              title: (ctx, _) => 'Books list',
            ),
            RouteDef(
              path: ':id',
              page: BookDetailsRoute.page,
              title: (ctx, data) {
                return 'Book Details ${data.pathParams.get('id')}';
              },
            ),
          ],
        ),
        profileTab,
        RouteDef(
          path: 'settings/:tab',
          page: SettingsTab.page,
        ),
      ],
    ),
    RouteDef(page: LoginRoute.page, path: '/login'),
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

x() {
  RootNavGraph(
    homeRoute: AutoRoute(
      builder: (data) => HomePage(),
    ),
  );
}

class RootNavGraph extends AutoNavGraph {
  RootNavGraph({
    AutoRoute<HomeNavGraph>? homeRoute,
    AutoRoute? loginRoute,
  }) : super(
          routes: [
            RouteDef(
              page: HomeRoute.page,
              path: homeRoute?.path,
              builder: (data) => HomePage(),
              children: homeRoute?.navGraph?.routes,
            ),
            RouteDef(
              page: LoginRoute.page,
              path: loginRoute?.path,
              builder: (data) => LoginPage(),
            ),
          ],
        );
}

class HomeNavGraph extends AutoNavGraph {
  HomeNavGraph({
    AutoRoute? booksTab,
    AutoRoute? profileTab,
    AutoRoute? settingsTab,
  }) : super(
          routes: [
            RouteDef(
              page: BooksTab.page,
              path: booksTab?.path,
              title: booksTab?.title,
              builder: booksTab?.builder ?? (data) => BooksTabPage(),
            ),
            RouteDef(
              page: ProfileTab.page,
              path: profileTab?.path,
              builder: profileTab?.builder ?? (data) => ProfileTabPage(),
            ),
            RouteDef(
              page: SettingsTab.page,
              path: settingsTab?.path,
              builder: settingsTab?.builder ?? (data) => SettingsPage(),
            ),
          ],
        );
}

abstract class AutoNavGraph {
  List<RouteDef> routes;

  AutoNavGraph({required this.routes});
}

class AutoRoute<TGraph extends AutoNavGraph> {
  final String? path;
  final RouteType? routeType;
  final bool? fullScreenDialog;
  final TGraph? navGraph;
  final PageBuilder? builder;
  final TitleBuilder? title;

  const AutoRoute({
    this.path,
    this.routeType,
    this.fullScreenDialog,
    this.title,
    this.navGraph,
    this.builder,
  });
}
