import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

typedef TypedFunction = void Function(int);
class HomeScreen extends StatelessWidget {
  final  TypedFunction onSelected;
  HomeScreen(this.onSelected);
  @override
  Widget build(BuildContext context) {
    print('building home scree');
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
                      arguments: SecondScreenArguments(message: 'title'),
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
