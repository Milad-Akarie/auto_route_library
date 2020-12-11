import 'package:auto_route/auto_route.dart';
import 'package:example/generic_model.dart';
import 'package:example/model.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/material.dart';

typedef OnPopped<T> = GenericModel<T> Function(T result);

class UsersScreen extends StatefulWidget {
  final OnPopped<Model> onPopped;

  const UsersScreen({
    @PathParam('id') this.idFromPath,
    Function onDismiss,
    Function(int index) onClicked,
    int score = 1,
    @QueryParam('filter') this.filter = 'none',
    this.onPopped,
  });

  final String idFromPath;
  final String filter;

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  Widget build(BuildContext context) {
    print(context.route.pathParams);
    return Scaffold(
        appBar: AppBar(
          title: Text('Users id: ${widget.idFromPath}, filter: ${widget.filter}'),
          actions: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                context.router.removeUntil((route) => route.key == HomeScreenRoute.key);
              },
            )
          ],
        ),
        body: AutoRouter());
  }
}
