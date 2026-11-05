import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'build_counts.dart';
import 'universal_link_test.dart' show sendPlatformLink;

// flutter/flutter#137037: an app opened by a link to a route that redirects
// opened the target page twice, the reporter's log showing its builder run
// twice.
// The routes are '/test' (initial), '/my_details', and a redirect from
// '/details' to '/my_details'. Open the app at '/details': only the details
// page should be in the stack, opened and built once. Then send '/details'
// from the platform again, as when the link is tapped with the app in the
// background: the details page stays, not opened again.
void main() {
  final opened = <String, int>{};
  final builds = <String, int>{};
  setUp(() {
    opened.clear();
    builds.clear();
  });

  PageInfo page(String name) => .new(name, builder: (_) => _CountedPage(name, opened, builds));

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(path: '/test', initial: true, page: page('HomeRoute')),
      AutoRoute(path: '/my_details', page: page('DetailsRoute')),
      RedirectRoute(path: '/details', redirectTo: '/my_details'),
    ],
  );

  testWidgets('A link to a redirect opens the target page once', (tester) async {
    final router = buildRouter();
    await pumpAtDeepLink(tester, router, '/details', includePrefixMatches: false);
    expect(router.stack.map((page) => page.name), ['DetailsRoute']);
    expect(opened, {'DetailsRoute': 1});
    expect(builds, {'DetailsRoute': 1});
    expect(router.currentUrl, '/my_details');
  });

  testWidgets('A later link to a redirect keeps the target page open', (tester) async {
    final router = buildRouter();
    await pumpAtDeepLink(tester, router, '/details', includePrefixMatches: false);

    await sendPlatformLink(tester, '/details');
    expect(router.stack.map((page) => page.name), ['DetailsRoute']);
    expect(opened, {'DetailsRoute': 1});
    expect(router.currentUrl, '/my_details');
  });
}

class _CountedPage extends StatefulWidget {
  const new(this.name, this.opened, this.builds);

  final String name;
  final BuildCounts opened;
  final BuildCounts builds;

  @override
  State<_CountedPage> createState() => _CountedPageState();
}

class _CountedPageState extends State<_CountedPage> {
  @override
  void initState() {
    super.initState();
    widget.opened[widget.name] = (widget.opened[widget.name] ?? 0) + 1;
  }

  @override
  Widget build(BuildContext context) {
    widget.builds[widget.name] = (widget.builds[widget.name] ?? 0) + 1;
    return Scaffold(body: Text(widget.name));
  }
}
