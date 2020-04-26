import 'package:auto_route/auto_route.dart';
import 'package:example/screens/nested_screens/nested_router.gr.dart'
    as nestedRouter;
import 'package:flutter/material.dart';

import 'nested_router.gr.dart';

class NestedScreen extends StatelessWidget {
  NestedScreen();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FlatButton(
          child: Text("NestedScreen two Screen"),
          onPressed: () {
            ExtendedNavigator.ofRouter<NestedRouter>()
                .pushNamed(nestedRouter.NestedRoutes.nestedScreenTwo);
          },
        ),
      ],
    );
  }
}
