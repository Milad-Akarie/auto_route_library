import 'package:example/router.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen() {
    print('constructing  Home screen');
  }
  @override
  Widget build(BuildContext context) {
    print('building home scree');
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Hero(
            tag: 'hero',
            child: Icon(Icons.ac_unit),
          ),
          Container(
            child: Center(
              child: FlatButton(
                child: Text("Second Screen"),
                onPressed: () async {
                  // ExtendedNavigator.of(context)
                  //     .pushSecondScreen(title: 'title', onReject: (guard) {

                  //     });

                  ExtendedNavigator.rootNavigator.pushNamed(Routes.secondScreen,
                      arguments: SecondScreenArguments(title: 'title'),
                      onReject: (guard) {
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: Text('You need to be looged in'),
                            ));
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
