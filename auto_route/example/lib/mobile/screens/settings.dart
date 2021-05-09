import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../router/router.gr.dart';

class SettingsPage extends StatefulWidget {
  final String tab;

  SettingsPage({Key? key, @pathParam required this.tab}) : super(key: UniqueKey()) {
    print('constrocitng settings page');
  }

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutoRouteAware {
  var _count = 0;
  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {
    print('did init settings tab');
  }

  @override
  void didPush() {
    print('did push settings tab');
  }

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    print('Changed to settings tab from ${previousRoute.name}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = RouterScope.of(context).firstObserverOfType<AutoRouteObserver>();
    if (observer != null) {
      observer.subscribe(this, context.routeData);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Settings/${widget.tab} $_count'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _count++;
              });
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

              // context.tabsRouter.navigateNamed(route)
              // context.tabsRouter.navigate(const ProfileTab());
              // context.navigateNamedTo('profile/my-books?filter=changed', includePrefixMatches: true);
            },
            child: Text('navigateNamed to profile/my-books'),
          )
        ],
      ),
    );
  }
}
