import 'package:auto_route/auto_route.dart';
import 'package:example/web/books/book_details_page.dart';

import 'book_list_page.dart';

const booksRoute = AutoRoute(
  path: 'books',
  page: EmptyRouterPage,
  name: 'BooksRoute',
  children: [
    AutoRoute(path: '', page: BookListPage, fullMatch: false),
    AutoRoute(
      path: ':id',
      fullscreenDialog: false,
      page: BookDetailsPage,
    ),
  ],
);
