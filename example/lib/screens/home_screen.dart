import 'package:auto_route/auto_route.dart';
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
                  onPressed: () async {
                    ExtendedNavigator.of(context);
//                  context.navigator.router.findMatch(settings)
                    // ignore: unawaited_futures
                    context.navigator.push('/users/23');
//                   ExtendedNavigator.of(context);
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
