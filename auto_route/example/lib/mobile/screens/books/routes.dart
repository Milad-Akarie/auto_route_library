import 'package:auto_route/auto_route.dart';
import 'package:auto_route/empty_router_widgets.dart';
import 'package:example/mobile/router/auth_guard.dart';

import 'book_details_page.dart';
import 'book_list_page.dart';

const booksTab = PageInfo(
  path: 'books',
  page: EmptyRouterPage,
  name: 'BooksTab',
  children: [
    PageInfo(path: '', page: BookListScreen),
    PageInfo(
      path: ':id',
      usesPathAsKey: true,
      page: BookDetailsPage,
      guards: [AuthGuard],
    ),
  ],
);
