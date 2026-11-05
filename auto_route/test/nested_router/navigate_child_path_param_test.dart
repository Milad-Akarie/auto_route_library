import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/'),
        AutoRoute(
          page: _shell('AccountsRouter'),
          path: '/accounts',
          children: [
            AutoRoute(page: _page('AccountsListRoute'), path: ''),
            AutoRoute(
              page: _AccountRoute.page,
              path: ':accountId',
              children: [AutoRoute(page: _ContactRoute.page, path: ':contactId')],
            ),
          ],
        ),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1015
  // Open the account '123' at '/accounts/:accountId', then go to the contact
  // '999' at '/accounts/:accountId/:contactId', which has a path param too.
  // Reported: "Looks like you're trying to navigate to a nested route without
  // adding their parent to stack first". Should: the contact opens under the
  // account '123', the url is '/accounts/123/999', and nothing throws.
  Future<void> openAccount(WidgetTester tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.navigatePath('/accounts/123'));
    await tester.pumpAndSettle();
    expect(find.text('Account 123'), findsOneWidget);
  }

  testWidgets('navigatePath from an account to one of its contacts opens it', (tester) async {
    await openAccount(tester);
    unawaited(router.navigatePath('/accounts/123/999'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Contact 999 of 123'), findsOneWidget);
    expect(router.urlState.url, '/accounts/123/999');
  });

  testWidgets('navigate to the contact route alone keeps the account it is opened from', (tester) async {
    await openAccount(tester);
    unawaited(router.navigate(_ContactRoute(contactId: '999')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Contact 999 of 123'), findsOneWidget);
    expect(router.urlState.url, '/accounts/123/999');
  });

  testWidgets('navigate to the account route with the contact as its child opens both', (tester) async {
    await openAccount(tester);
    unawaited(
      router.navigate(
        _AccountRoute(
          accountId: '123',
          children: [_ContactRoute(contactId: '999')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Contact 999 of 123'), findsOneWidget);
    expect(router.urlState.url, '/accounts/123/999');
  });

  testWidgets('pushing the contact from the account page opens it', (tester) async {
    await openAccount(tester);
    unawaited(router.push(_ContactRoute(contactId: '999')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Contact 999 of 123'), findsOneWidget);
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

PageInfo _shell(String name) => .new(name, builder: (_) => const AutoRouter());

abstract final class _HomeRoute {
  static const String name = 'HomeRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const Text('Home'));
}

class _AccountRoute extends PageRouteInfo<void> {
  new({required String accountId, required List<PageRouteInfo> children})
    : super(pageName, rawPathParams: {'accountId': accountId}, initialChildren: children);

  static const String pageName = 'AccountRoute';
  static final PageInfo page = PageInfo(
    pageName,
    builder: (data) => Column(
      children: [
        Text('Account ${data.inheritedPathParams.getString('accountId')}'),
        const Expanded(child: AutoRouter()),
      ],
    ),
  );
}

class _ContactRoute extends PageRouteInfo<void> {
  new({required String contactId}) : super(pageName, rawPathParams: {'contactId': contactId});

  static const String pageName = 'ContactRoute';
  static final PageInfo page = PageInfo(
    pageName,
    builder: (data) => Text(
      'Contact ${data.inheritedPathParams.getString('contactId')} of ${data.inheritedPathParams.getString('accountId')}',
    ),
  );
}
