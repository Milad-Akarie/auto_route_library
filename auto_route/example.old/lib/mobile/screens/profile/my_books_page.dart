import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:material_ui/material_ui.dart';

/// Page of the profile tab with buttons that test navigation: to settings, back
/// and to home.
///
/// Shows the `filter` query parameter and the url fragment.
@RoutePage()
class MyBooksPage extends StatelessWidget {
  /// Takes the [filter] query parameter.
  const new({super.key, @queryParam this.filter = 'none2'});

  /// The `filter` query parameter, `none2` when the url has none.
  final String? filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text(
              'My Books -> filter: $filter',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Fragment Support? ${context.routeData.fragment}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                unawaited(
                  context.navigateTo(
                    SettingsTab(tab: 'newSegment', query: 'newQuery'),
                  ),
                );
              },
              child: const Text('navigate to /settings/newSegment'),
            ),
            ElevatedButton(
              onPressed: () => context.back(),
              child: const Text('Navigate back'),
            ),
            ElevatedButton(
              onPressed: () => context.router.root.pushAndPopUntil(
                const HomeRoute(),
                predicate: (_) => false,
              ),
              child: const Text('Pop until /home'),
            ),
          ],
        ),
      ),
    );
  }
}
