import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
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
          page: booksTab.page,
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
    AutoRoute(page: booksTab.page, path: '/login'),
    RedirectRoute(path: '*', redirectTo: '/'),
  ];
}

const booksTab = EmptyShellRoute('BooksTab');
const profileTab = EmptyShellRoute('ProfileTab');
