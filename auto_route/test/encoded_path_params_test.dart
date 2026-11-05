import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: _FileRoute.page, path: '/files/:name'),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2070
  // Push a page whose path param holds a reserved character, such as 'a/b',
  // then open the app at the url it shows. The url should hold the value
  // encoded, '/files/a%2Fb', and reopening it should read the whole value back,
  // not split it at the '/' and match nothing.
  for (final name in ['reports/2024', 'what?', 'part#2', '100%', 'a b', 'café', '12:30']) {
    testWidgets('A path param "$name" is encoded in the url and reads back whole', (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.push(_FileRoute(name: name)));
      await tester.pumpAndSettle();
      expect(find.text('File $name'), findsOneWidget);
      final url = router.urlState.uri;
      expect(url.pathSegments, ['files', name]);

      final reopened = router.matcher.matchUri(Uri.parse(url.toString()));
      expect(reopened?.lastOrNull?.name, _FileRoute.pageName);
      expect(reopened?.lastOrNull?.params.rawMap, {'name': name});
    });
  }

  // https://github.com/Milad-Akarie/auto_route_library/issues/2070
  // Open the app at '/files/reports%2F2024'. The '%2F' is part of the param,
  // so the page should read 'reports/2024', not fail to match '/files/reports/2024'.
  testWidgets('An encoded "/" in a deep link stays inside its path param', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/files/reports%2F2024');
    expect(tester.takeException(), isNull);
    expect(find.text('File reports/2024'), findsOneWidget);
    expect(router.urlState.uri.toString(), '/files/reports%2F2024');
  });
}

class _FileRoute extends PageRouteInfo<void> {
  new({required String name}) : super(pageName, rawPathParams: {'name': name});

  static const String pageName = 'FileRoute';
  static final PageInfo page = PageInfo(
    pageName,
    builder: (data) => Text('File ${data.inheritedPathParams.getString('name')}'),
  );
}
