import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String state = 'initial';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print('+++++++++ Setting page init $state');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(state),
          Container(
            child: TextField(
              onChanged: (t) {
                setState(() {
                  state = t;
                });
              },
            ),
          ),
        ],
      )),
    );
  }
}
