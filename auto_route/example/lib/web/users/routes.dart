import 'package:auto_route/auto_route.dart';
import 'package:flutter/src/widgets/framework.dart';

import '../../data/db.dart';
import '../books/book_details_page.dart';
import 'user_details_page.dart';
import 'user_list_page.dart';

const usersRoute = AutoRoute(
  path: 'users',
  page: UsersRouterPage,
  name: 'UsersRoute',
  children: [
    AutoRoute(path: '', page: UserListPage),
    AutoRoute(
      path: ':id',
      page: UserDetailsPage,
      children: [
        AutoRoute(
          name: 'UserBookDetails',
          path: 'book/:id',
          page: BookDetailsPage,
        )
      ],
    ),
  ],
);

class UsersRouterPage extends AutoRouter implements AutoRouteWrapper {
  @override
  Widget wrappedRoute(BuildContext context) => UsersDBProvider(
        child: this,
      );
}
