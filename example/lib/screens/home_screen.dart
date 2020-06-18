import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
//  final  TypedFunction onSelected;
//  HomeScreen(this.onSelected);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            child: Center(
              child: FlatButton(
                child: Text("Users Screen"),
                onPressed: () async {
                  ExtendedNavigator.of(context).pushNamed(Routes.users);
//                  AutoRouter.of(context).push(Routes.initalRoute);
//                ExtendedNavigator.of(context).pushNamed(Routes.secondScreen);
//                  ExtendedNavigator.ofRouter<Router>().pushNamed(
//                    Routes.secondScreen,
//                    arguments: SecondScreenArguments(message: 'title'),
//                    onReject: (guard) {
//                      showDialog(
//                        context: context,
//                        builder: (_) => AlertDialog(
//                          title: Text('You need to be logged in'),
//                        ),
//                      );
//                    },
//                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
