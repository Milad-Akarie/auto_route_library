import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget implements AutoRouteWrapper {
  final String message;

  const SecondScreen({@required String title, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Hero(
              tag: 'hero',
              child: Icon(
                Icons.ac_unit,
                size: 400,
              ),
            ),

            Text("Second Screen here"),

            // Expanded(
            //   child: ExtendedNavigator<NestedRouter>(
            //     router: NestedRouter(),
            //   ),
            // )
          ],
        ),
      ),
    );
  }

  @override
  Widget get wrappedRoute => Container(child: this);
}
