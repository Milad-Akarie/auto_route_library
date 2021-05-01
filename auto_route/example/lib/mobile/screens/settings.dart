import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../router/router.gr.dart';

class SettingsPage extends StatelessWidget {
  final String tab;

  SettingsPage({Key? key, @pathParam required this.tab}) : super(key: key) {
    print('constrocitng settings page');
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Settings/$tab'),
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
            child: Text('navigateNamed to profile/my-books'),
          )
        ],
      ),
    );
  }
}
