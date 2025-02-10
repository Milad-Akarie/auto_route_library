//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:example/mobile/screens/books/book_details_page.dart';
import 'package:example/mobile/screens/books/book_list_page.dart';
import 'package:example/mobile/screens/profile/routes.dart';

@AutoRouterConfig(generateForDir: ['lib/mobile'])
class AppRouter extends RootStackRouter {
  @override
  final List<AutoRoute> routes = [
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
    AutoRoute(page: BooksTab.page, path: '/login'),
    RedirectRoute(path: '*', redirectTo: '/'),
  ];
}

const BooksTab = EmptyShellRoute('BooksTab');
const ProfileTab = EmptyShellRoute('ProfileTab');

x() {
  final router = AppRouter();

  router.push(NamedPath('init', args: null));
}

class NamedPath extends PageRouteInfo {
  NamedPath(
    super.name, {
    PageRouteInfo? child,
    super.args,
    Map<String, dynamic> params = const {},
    Map<String, dynamic> queryParams = const {},
    super.fragment,
  }) : super(
          initialChildren: [if (child != null) child],
          rawPathParams: params,
          rawQueryParams: queryParams,
        );

  NamedPath.withChildren(
    super.name,
    List<PageRouteInfo> children, {
    super.args,
    Map<String, dynamic> params = const {},
    Map<String, dynamic> queryParams = const {},
    super.fragment,
  }) : super(
          initialChildren: children,
          rawPathParams: params,
          rawQueryParams: queryParams,
        );
}

class SimpleRouter extends RootStackRouter {
  @override
  final List<AutoRoute> routes;

  @override
  final List<AutoRouteGuard> guards;

  @override
  final RouteType defaultRouteType;

  SimpleRouter({
    required this.routes,
    this.guards = const [],
    super.navigatorKey,
    this.defaultRouteType = const RouteType.material(),
  });
}

void worker() {
  final router = SimpleRouter(
    routes: [
      SimpleRoute(
        path: '/books',
        builder: (ctx, data) => const BookListScreen(),
      ),
      SimpleRoute(
        name: 'bookDetails', // optional, if null path is used
        path: '/books/:id',
        builder: (ctx, data) {
          final params = data.params; // data.queryParams, data.args ..etc
          return BookDetailsPage(
            id: params.getInt('id'),
          );
        },
      ),
    ],
  );

  router.pushPath('/books/1');
  // navigate using named route
  router.push(NamedPath('bookDetails', params: {'id': 1}));

}
