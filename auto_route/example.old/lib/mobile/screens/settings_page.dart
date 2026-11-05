import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:example/mobile/router/router.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

@RoutePage(name: 'SettingsTab')
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    @pathParam this.tab = 'none',
    @queryParam this.query = 'none',
  });
  final String tab;
  final String query;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutoRouteAwareStateMixin<SettingsPage> {
  int queryUpdateCont = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            Text(widget.tab),
            Text(widget.query),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  queryUpdateCont++;
                });
                unawaited(
                  context.navigateTo(
                    SettingsTab(
                      tab: 'Updated Path param $queryUpdateCont',
                      query: 'updated Query $queryUpdateCont',
                    ),
                  ),
                );
              },
              child: Text('Update Query $queryUpdateCont'),
            ),
            ElevatedButton(
              onPressed: () {
                unawaited(
                  context.navigateTo(
                    BooksTab(
                      children: [BookDetailsRoute(id: 1)],
                    ),
                  ),
                );
              },
              child: const Text('Navigate to book details/1'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AuthService>().logout();
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {
    debugPrint('init tab route from ${previousRoute?.name}');
  }

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    debugPrint('did change tab route from ${previousRoute.name}');
  }
}
