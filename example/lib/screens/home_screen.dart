import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            child: Center(
              child: Hero(
                tag: 'Hero',
                child: FlatButton(
                  color: Colors.green,
                  child: Text('Users Screen'),
                  onPressed: () {
                    context.router.push(UsersScreenRoute(
                        id: '2',
                        // ignore: missing_return
                        onPoppedArg: (model) {
                          print('UsersScreenRoute popped $model');
                        }));
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
