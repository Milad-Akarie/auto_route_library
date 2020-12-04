import 'package:auto_route/auto_route.dart';
import 'package:example/generic_model.dart';
import 'package:example/model.dart';
import 'package:flutter/material.dart';

typedef OnPopped<T> = GenericModel<T> Function(T result);

class UsersScreen extends StatelessWidget {
  final OnPopped<Model> onPopped;

  const UsersScreen({
    this.id,
    Function onDismiss,
    Function(int index) onClicked,
    int score = 1,
    @QueryParam('filter') this.filterFromQuery = 'none',
    this.onPopped,
  });

  final int id;
  final String filterFromQuery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Users id: $id, filter: $filterFromQuery'),
          actions: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                context.router.pop();
              },
            )
          ],
        ),
        body: AutoRouter());
  }
}
