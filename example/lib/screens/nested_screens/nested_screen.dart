import 'package:auto_route/auto_route.dart';
import 'package:example/screens/nested_screens/nested_router.gr.dart';
import 'package:flutter/material.dart';

class NestedScreen extends StatelessWidget {
  NestedScreen(int x);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FlatButton(
          child: Text("NestedScreen two Screen"),
          onPressed: () {
            ExtendedNavigator.ofRouter<NestedRouter>()
                .pushNamed(Routes.nestedScreenTwo);
          },
        ),
      ],
    );
  }
}
