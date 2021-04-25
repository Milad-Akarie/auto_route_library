import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../router/router.gr.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Settings'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // context.tabsRouter.pushChild(BookDetailsRoute(id: 4));
              //
              // context.navigateTo(
              //   HomeRoute(
              //     children: [
              //       ProfileTab(children: [
              //         MyBooksRoute(),
              //       ]),
              //     ],
              //   ),
              // );

              context.router.navigateNamed('profile/my-books', includePrefixMatches: true);
            },
            child: Text('Navigate to Book/4'),
          )
        ],
      ),
    );
  }
}
