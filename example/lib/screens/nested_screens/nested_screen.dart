import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:flutter/material.dart';
import 'nested_router.gr.dart';

import 'nested_router.dart';

class NestedScreen extends StatelessWidget {
  final String id;

  const NestedScreen({Key key, @pathParam this.id}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FlatButton(
          child: Text("Nested Home"),
          onPressed: () {
            ExtendedNavigator.ofRouter<NestedRouter>()
                .pushNamed(NestedRoutes.nestedScreenTwo);
          },
        ),
      ],
    );
  }
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('id', id));
  }
}
