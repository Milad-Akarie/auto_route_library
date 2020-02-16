import 'package:auto_route/auto_route.dart';
import 'package:example/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model.dart';
import '../router.gr.dart';

class HomeScreen extends StatelessWidget implements AutoRouteWrapper {
  @override
  Widget get wrappedRoute => Provider(create: (ctx) => Model(), child: this);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: Center(
          child: FlatButton(
            child: Text(Provider.of<Model>(context, listen: false).value),
            onPressed: () async {
              NavigationService.registerGuard(AuthGuard());
              NavigationService.registerGuard(UserRoleGaurd());

              print(await Router.instance.pushNamed(Router.secondScreenRoute));
            },
          ),
        ),
      ),
    );
  }
}
