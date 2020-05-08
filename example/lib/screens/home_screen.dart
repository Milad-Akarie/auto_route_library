import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
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
                child: Text("Second Screen"),
                onPressed: () async {
                  ExtendedNavigator.ofRouter<Router>().pushNamed(
                    Routes.secondScreen,
                    arguments: SecondScreenArguments(title: 'title'),
                    onReject: (guard) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('You need to be logged in'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
