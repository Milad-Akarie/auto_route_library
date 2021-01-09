import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/auth_guard.dart';

import 'book_details_page.dart';
import 'book_list_page.dart';

const booksTab = AutoRoute(
  path: '',
  page: EmptyRouterPage,
  name: 'BooksTab',
  children: [
    RedirectRoute(path: '', redirectTo: 'books'),
    AutoRoute(path: 'books', page: BookListPage),
    AutoRoute(
      path: 'books/:id',
      page: BookDetailsPage,
      // guards: [AuthGuard],
    ),
  ],
);
