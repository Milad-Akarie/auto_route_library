import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  final String message;

  SecondScreen({@required this.message});

  final tabViews = <Widget>[
    Icon(Icons.book),
    Icon(Icons.notifications),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBuilder: (ctx, index) => Center(child: tabViews[index]),
      tabBar: CupertinoTabBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.book)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications))
        ],
      ),
    );
  }
}
