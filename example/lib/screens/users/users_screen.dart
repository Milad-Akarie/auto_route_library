import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/material.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({
    this.id,
    @QueryParam('filter') this.filterFromQuery = 'none',
    Container container,
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
