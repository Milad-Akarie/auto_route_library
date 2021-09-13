import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String tab;

  SettingsPage({Key? key, @pathParam required this.tab}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutoRouteAware {
  var _count = 0;

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {}

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
              // setState(() {
              //   _count++;
              // });

              // context.navigateNamedTo(
              //   'profile/my-books?filter=yedds',
              //   includePrefixMatches: true,
              // );
              context.navigateTo(
                ProfileTab(children: [
                  ProfileRoute(),
                  MyBooksRoute(),
                ]),
              );
            },
            child: Text('navigateNamed to profile/my-books'),
          )
        ],
      ),
    );
  }
}
