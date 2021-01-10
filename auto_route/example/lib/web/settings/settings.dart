import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../router/web_router.gr.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Settings'),
            const SizedBox(height: 24),
            RaisedButton(
                child: Text('Books'),
                onPressed: () {
                  context.router.navigate(BooksRoute());
                })
          ],
        ),
      ),
    );
  }
}
