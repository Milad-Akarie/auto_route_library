import 'package:auto_route/auto_route.dart';
import 'package:example/generic_model.dart';
import 'package:example/model.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/material.dart';

typedef OnPopped<T> = GenericModel<T> Function(T result);

class UsersScreen extends StatelessWidget {
  final OnPopped<Model> onPopped;

  const UsersScreen({
    this.id,
    @required Function onDismiss,
    Function(int index) onClicked,
    @QueryParam('filter') this.filterFromQuery = 'none',
    this.onPopped,
  });

  final int id;
  final String filterFromQuery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ignore: prefer_single_quotes
      appBar: AppBar(title: Text("Users id: $id, filter: $filterFromQuery")),
//      body: Hero(
//        tag: 'Hero',
//        child: Center(
//          child: FlatButton(
//            shape: RoundedRectangleBorder(borderRadius:
//            BorderRadius.circular(30)),
//            color: Colors.red,
//            child: Text("Users Posts"),
//            onPressed: () async {},
//          ),
//        ),
//      ),
      // this router will obtain it's route generator
      // on it's own
      body: ExtendedNavigator(
        initialRoute: UsersScreenRoutes.postsScreen,
        name: 'usersRouter',
      ),
    );
  }
}
