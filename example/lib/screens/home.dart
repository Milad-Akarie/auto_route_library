import 'package:auto_route/auto_route_annotation.dart';
import 'package:example/router.dart';
import 'package:flutter/material.dart';

@initialRoute
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: FlatButton(child: Text("Second Screen"),onPressed: (){
          Navigator.of(context).pushNamed(Router.secondScreenRoute);
        },),
      ),
    );
  }
}

