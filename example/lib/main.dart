import 'package:auto_route/auto_route.dart';
import 'package:example/router.dart';
import 'package:example/router.gr.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey,
        ),
        body: LayoutBuilder(
          builder: (ctx, _) => Center(
            child: FlatButton(
              child: Text("Start"),
              onPressed: () {
                Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => RedirectWidget(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class RedirectWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ExtendedNavigator(
        // initialRoute: Routes.homeScreen,
        router: Router(),
        guards: [AuthGuard()],
      ),
    );
  }
}
