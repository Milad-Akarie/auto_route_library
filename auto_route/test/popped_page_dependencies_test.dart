import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/63364: a page that read its
  // route arguments with ModalRoute.of(context) in didChangeDependencies ran
  // it again when popped, and loaded its data again on the way out.
  // Steps: DetailRoute's state reads its args from context.routeData in
  // didChangeDependencies. Push it, then pop it.
  // Should: didChangeDependencies runs once, when the page is built, not when
  // it is popped. A page that reads ModalRoute.of still gets the extra call:
  // flutter_canary_popped_page_rebuilds_test.dart pins that.
  testWidgets(
    'A page reading its route data in didChangeDependencies is not told again when popped',
    (tester) async {
      final events = <String>[];
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HomeRoute',
              builder: (_) => const Text('HomeRoute'),
            ),
          ),
          AutoRoute(
            path: '/detail/:id',
            page: PageInfo('DetailRoute', builder: (_) => _DetailPage(events)),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      unawaited(router.pushPath('/detail/7'));
      await tester.pumpAndSettle();
      expect(events, ['load 7']);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('HomeRoute'), findsOneWidget);
      expect(events, ['load 7', 'dispose']);
    },
  );
}

class _DetailPage extends StatefulWidget {
  const new(this.events);

  final List<String> events;

  @override
  State<_DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<_DetailPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.events.add('load ${context.routeData.params.getString('id')}');
  }

  @override
  void dispose() {
    widget.events.add('dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Text('DetailRoute');
}
