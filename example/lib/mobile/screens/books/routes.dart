import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/auth_guard.dart';

import 'book_details_page.dart';
import 'book_list_page.dart';

const booksTab = AutoRoute(
  path: 'books',
  page: EmptyRouterPage,
  name: 'BooksTab',
  children: [
    RedirectRoute(path: '', redirectTo: 'list'),
    AutoRoute(path: 'list', page: BookListPage),
    AutoRoute(
      path: 'list/:id',
      fullscreenDialog: false,
      page: BookDetailsPage,
      guards: [AuthGuard],
    ),
  ],
);
