import 'package:auto_route/auto_route.dart';
import 'package:example/data/db.dart';
import 'package:example/web/books/book_details_page.dart';
import 'package:example/web/users/user_details_page.dart';
import 'package:example/web/users/user_list_page.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';

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
  Widget wrappedRoute(BuildContext context) {
    return Provider<UsersDB>(
      create: (_) => UsersDB(),
      child: this,
    );
  }
}
