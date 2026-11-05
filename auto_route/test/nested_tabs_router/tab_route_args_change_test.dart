import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

final ValueNotifier<String> _channel = ValueNotifier('news');

void main() {
  tearDownAll(_channel.dispose);
  setUp(() => _channel.value = 'news');

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _HostRoute.page,
          path: '/',
          initial: true,
          children: [
            AutoRoute(page: _ChannelRoute.page, path: 'channel'),
            AutoRoute(page: _SelectionRoute.page, path: 'selection'),
          ],
        ),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/990
  // An AutoTabsScaffold has the routes [ChannelRoute(channel: value), SelectionRoute()],
  // with the value read from a provider (here a ValueNotifier). Change the
  // value. Reported: the channel route keeps its first argument. Should: the
  // tab shows the new channel.
  testWidgets(
    'AutoTabsScaffold shows the new argument of a route when the routes it is given change',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      expect(find.text('Channel news'), findsOneWidget);

      _channel.value = 'sports';
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Channel sports'), findsOneWidget);
      expect(find.text('Channel news'), findsNothing);
    },
  );

  // Same issue, as the comments ask: while the channel tab is open, call
  // navigate(ChannelRoute(channel: 'sports')).
  // Should: the page shows 'sports'.
  testWidgets(
    'navigate() to the open tab route with another argument shows the new argument',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      expect(find.text('Channel news'), findsOneWidget);

      unawaited(router.navigate(_ChannelRoute(channel: 'sports')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Channel sports'), findsOneWidget);
      expect(find.text('Channel news'), findsNothing);
    },
  );
}

abstract final class _HostRoute {
  static const String name = 'HostRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder<String>(
      valueListenable: _channel,
      builder: (_, channel, _) => AutoTabsScaffold(
        routes: [
          _ChannelRoute(channel: channel),
          const _SelectionRoute(),
        ],
      ),
    ),
  );
}

class _ChannelRoute extends PageRouteInfo<_ChannelArgs> {
  new({required String channel}) : super(name, args: _ChannelArgs(channel));

  static const String name = 'ChannelRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (data) => Text('Channel ${data.argsAs<_ChannelArgs>().channel}'),
  );
}

class _ChannelArgs {
  const new(this.channel);
  final String channel;
}

class _SelectionRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'SelectionRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Text('Selection'),
  );
}
