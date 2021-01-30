import 'package:auto_route/auto_route.dart';

import 'book_details_page.dart';
import 'book_list_page.dart';

const booksRoute = AutoRoute(
  path: 'books',
  page: EmptyRouterPage,
  name: 'BooksRoute',
  children: [
    AutoRoute(path: '', page: BookListPage),
    AutoRoute(
      path: ':id',
      fullscreenDialog: false,
      page: BookDetailsPage,
    ),
  ],
);
