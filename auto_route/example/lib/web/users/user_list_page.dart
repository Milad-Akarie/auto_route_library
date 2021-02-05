import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../data/db.dart';
import '../router/web_router.gr.dart';

class UserListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var usersDb = UsersDBProvider.of(context);
    return ListView(
      children: usersDb.users
          .map((user) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  onTap: () {
                    context.router.push(UserDetailsRoute(id: user.id, children: [
                      UserBookDetails(
                        id: user.books.first.id,
                      )
                    ]));
                  },
                ),
              ))
          .toList(),
    );
  }
}
