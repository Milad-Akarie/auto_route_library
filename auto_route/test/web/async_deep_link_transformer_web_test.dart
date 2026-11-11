@TestOn('browser')
library;

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' show window;

import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // The reporter's books app: a list at '/' and a book at '/book/:id', with a
  // parser that awaits a 1 ms delay before it answers, here the router's
  // deepLinkTransformer.
  RouterConfig<UrlState> booksConfig() {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'BooksRoute',
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('books')),
        ),
        NamedRouteDef(
          name: 'BookRoute',
          path: '/book/:id',
          builder: (_, data) =>
              Scaffold(body: Text('book ${data.params.getString('id')}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    return router.config(
      deepLinkTransformer: (uri) =>
          Future.delayed(const Duration(milliseconds: 1), () => uri),
    );
  }

  // flutter/flutter#80494: with a parser that awaited before it answered, a
  // url typed into the address bar opened its page, but the address bar was
  // rewritten to another url.
  // Steps: open the app, then type '/book/0' into the address bar.
  // Should: the book page shows and the address bar keeps '/book/0'.
  testWidgets(
    'On web, a typed url keeps its address with an async deepLinkTransformer (flutter/flutter#80494)',
    (tester) async {
      await pumpRouterConfigApp(tester, booksConfig());
      await settleBrowser(tester);

      await browserMove(tester, () => window.location.hash = '/book/0');
      expect(
        (find.text('book 0').evaluate().length, browserPath),
        (1, '/book/0'),
      );
    },
  );

  // flutter/flutter#80494, the app opened at the url, as a reload after
  // typing it does.
  // Steps: open the app at '/book/0'.
  // Should: the book page shows and the address bar keeps '/book/0'.
  testWidgets(
    'On web, the app opened at a url keeps it with an async deepLinkTransformer (flutter/flutter#80494)',
    (tester) async {
      openBrowserAt(tester, '/book/0');
      await pumpAsRunApp(
        tester,
        MaterialApp.router(routerConfig: booksConfig()),
      );
      await settleBrowser(tester);
      expect(
        (find.text('book 0').evaluate().length, browserPath),
        (1, '/book/0'),
      );
    },
  );
}
