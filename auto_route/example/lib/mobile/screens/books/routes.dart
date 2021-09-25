import 'package:auto_route/auto_route.dart';
import 'package:example/data/db.dart';
import 'package:example/mobile/router/auth_guard.dart';

import 'book_details_page.dart';
import 'book_list_page.dart';

const booksTab = AutoRoute(
  path: 'books',
  page: EmptyRouterPage,
  name: 'BooksTab',
  children: [
    AutoRoute(path: '', page: BookListPage),
    AutoRoute<Book>(
      path: ':id',
      usesPathAsKey: true,
      page: BookDetailsPage,
      guards: [AuthGuard],
    ),
  ],
);
