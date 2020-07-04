import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/material.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({
    @PathParam() this.id,
    @QueryParam('filter') this.filterFromQuery = "none",
  });

  final int id;
  final String filterFromQuery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Users id: $id, filter: $filterFromQuery")),
//      body:   Container(
//        child: Center(
//          child: FlatButton(
//            child: Text("Users Posts"),
//            onPressed: () async {
//            },
//          ),
//        ),
//      ),
      // this navigator will obtain it's router
      // on it's own
      body: NestedNavigator(name: 'usersRouter'),
    );
  }
}
