import 'package:auto_route/auto_route.dart';

import 'book_details_page.dart';
import 'book_list_page.dart';

const booksRoute = AutoRoute(
  path: '',
  page: EmptyRouterPage,
  name: 'BooksRoute',
  children: [
    RedirectRoute(path: '', redirectTo: 'books'),
    AutoRoute(path: 'books', page: BookListPage),
    AutoRoute(
      path: 'books/:id',
      fullscreenDialog: false,
      page: BookDetailsPage,
    ),
  ],
);
