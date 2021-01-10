import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../data/db.dart';
import '../router/web_router.gr.dart';

class UserDetailsPage extends StatefulWidget {
  final int id;

  const UserDetailsPage({@PathParam('id') this.id});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    final usersDb = UsersDBProvider.of(context);
    final user = usersDb.findUserById(widget.id);
    return user == null
        ? Container(child: Text('User null'))
        : Material(
            child: Column(
            children: [
              ListTile(
                title: Text(user.name),
                subtitle: Text(user.email),
              ),
              Expanded(
                child: ListView(
                  children: user.books
                      .map((book) => Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(book.name),
                              subtitle: Text(book.genre),
                              onTap: () {
                                AutoRouter.innerRouterOf(context, UserDetailsRoute.name)
                                    .push(UserBookDetails(id: book.id));
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              Expanded(
                child: AutoRouter(),
              )
            ],
          ));
  }
}
