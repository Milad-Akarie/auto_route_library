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
        AutoRoute(page: FirstRoute.page, path: '/', initial: true),
        AutoRoute(page: _CmsRoute.page, path: '/cms/:path'),
        RedirectRoute(path: '/test1/:path', redirectTo: '/cms/:path'),
        RedirectRoute(path: '/old/:pa/:path', redirectTo: '/cms/:path'),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2212
  // A path param holds one segment, so a value with a '/' is sent encoded.
  // Open '/cms/test1%2Ftest2': the page should read the whole 'test1/test2',
  // not 'test1'.
  testWidgets('An encoded "/" reaches the path param whole', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/cms/test1%2Ftest2');
    expect(find.text('Cms test1/test2'), findsOneWidget);
    expect(router.urlState.uri.toString(), '/cms/test1%2Ftest2');
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2212
  // Open '/test1/a%2Fb', which RedirectRoute(path: '/test1/:path',
  // redirectTo: '/cms/:path') sends on. The redirect should keep the '/'
  // encoded, so the page reads 'a/b'.
  testWidgets('A redirect passes an encoded "/" on whole', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/test1/a%2Fb');
    expect(find.text('Cms a/b'), findsOneWidget);
    expect(router.urlState.uri.toString(), '/cms/a%2Fb');
  });

  // A redirect read ':path' as the param ':pa' followed by 'th': the params were matched by name with no
  // segment end, and 'pa' came first.
  // Open '/old/1/2', which RedirectRoute(path: '/old/:pa/:path', redirectTo: '/cms/:path') sends on.
  // Should: the page reads '2' and the url is '/cms/2', not '/cms/1th'.
  testWidgets('A redirect expands a param whose name starts another whole', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/old/1/2');
    expect(find.text('Cms 2'), findsOneWidget);
    expect(router.urlState.uri.toString(), '/cms/2');
  });
}

abstract final class _CmsRoute {
  static const String pageName = 'CmsRoute';
  static final PageInfo page = PageInfo(
    pageName,
    builder: (data) => Text('Cms ${data.inheritedPathParams.getString('path')}'),
  );
}
