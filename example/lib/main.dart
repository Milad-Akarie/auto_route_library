import 'package:auto_route/auto_route.dart';
import 'package:example/router.dart';
import 'package:example/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home: Scaffold(
      //   appBar: AppBar(
      //     backgroundColor: Colors.grey,
      //   ),
      //   body: LayoutBuilder(
      //     builder: (ctx, _) => Center(
      //       child: FlatButton(
      //         child: Text("Start"),
      //         onPressed: () async {
      //           final prefs = await SharedPreferences.getInstance();
      //           prefs.remove('token');
      //           Navigator.of(ctx).push(
      //             MaterialPageRoute(
      //               builder: (_) => RedirectWidget(),
      //             ),
      //           );
      //         },
      //       ),
      //     ),
      //   ),
      // ),
      builder: ExtendedNavigator<Router>(
        router: Router(),
        guards: [AuthGuard()],
      ),
    );
  }
}

class RedirectWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ExtendedNavigator<Router>(
        // initialRoute: Routes.homeScreen,
        router: Router(),
        guards: [AuthGuard()],
      ),
    );
  }
}
