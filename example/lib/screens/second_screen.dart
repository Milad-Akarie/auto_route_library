import 'package:auto_route/auto_route_annotations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  final String id;

  const SecondScreen({
    @pathParam this.id,
    int score,
    double limit = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SecondScreen $id"),
      ),
//      body: ExtendedNavigator<NestedRouter>(
//        router: NestedRouter(),
//        initialRoute: NestedRoutes.nestedScreenTwo,
//      ),
    );
  }
}

class SecondNested extends StatelessWidget {
  final String user;
  final String id;

  const SecondNested({Key key, @pathParam this.user, @pathParam this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ThirdScree $user")),
    );
  }
}
