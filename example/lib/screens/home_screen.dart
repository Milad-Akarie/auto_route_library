import 'package:auto_route/auto_route_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../router.dart';
import '../router.gr.dart';


class HomeScreen extends StatelessWidget implements AutoRouteWrapper {
  @override
  Widget get wrappedRoute =>
      Provider(create: (_) {
        return Model();
      }, child: this);

  @override
  Widget build(BuildContext context) {
    print("built");
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: Center(
          child: FlatButton(
            child: Text(Provider
                .of<Model>(context, listen: false)
                .value),
            onPressed: () {
              Router.navigator.pushNamed(Router.secondScreenRoute, arguments: SecondScreenArguments(title: "Title"));
            },
          ),
        ),
      ),
    );
  }
}
