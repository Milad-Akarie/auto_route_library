import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String state = 'initial';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(state),
          Container(
            child: Column(
              children: [
                TextField(
                  onChanged: (t) {
                    setState(() {
                      state = t;
                    });
                  },
                ),
                FlatButton(
                  child: Text('Go To Book 4'),
                  onPressed: () {
                    AutoTabsRouter.of(context)
                      ..setActiveIndex(0)
                      ..childRouterOf<StackRouter>(BooksTab.name).push(
                        BookDetailsRoute(id: 4),
                      );
                  },
                )
              ],
            ),
          ),
        ],
      )),
    );
  }
}
