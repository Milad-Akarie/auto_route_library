import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/812
  // Reported: a shell route PostRouter holds PostScreen (initial) and
  // PostDetailScreen. Its pages open the detail with
  // AutoRouter.of(context).navigate(PostRouter(children: [PostDetailRoute])).
  // After a second PostRouter was pushed and popped, that call did nothing
  // in the first one.
  // Steps: open the detail in the first PostRouter and go back, push a
  // second PostRouter and open its detail, pop both, then open the detail
  // from the first PostRouter's page again.
  // Should: the detail opens in the first PostRouter each time.
  testWidgets(
    'A shell pushed twice and popped still navigates inside the first one',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef.shell(
            name: 'PostRouter',
            path: '/',
            children: [
              NamedRouteDef(
                name: 'PostRoute',
                path: '',
                builder: (_, _) => const Text('PostRoute'),
              ),
              NamedRouteDef(
                name: 'PostDetailRoute',
                path: 'detail',
                builder: (_, _) => const Text('PostDetailRoute'),
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());

      // The PostRouter each openDetail ran in, and what then showed.
      final postRouters = <StackRouter>[];
      final shown = <String>[];
      Future<StackRouter> openDetail() async {
        final postRouter = tester.element(find.text('PostRoute')).router;
        postRouter
            .navigate<void>(
              const NamedRoute(
                'PostRouter',
                children: [NamedRoute('PostDetailRoute')],
              ),
            )
            .ignore();
        await tester.pumpAndSettle();
        postRouters.add(postRouter);
        shown.add(
          '${postRouter.topRoute.name} '
          '${find.text('PostDetailRoute').evaluate().length}',
        );
        return postRouter;
      }

      await (await openDetail()).maybePop();
      await tester.pumpAndSettle();

      router.push(const NamedRoute('PostRouter')).ignore();
      await tester.pumpAndSettle();
      await (await openDetail()).maybePop();
      await tester.pumpAndSettle();
      await router.maybePop();
      await tester.pumpAndSettle();
      final stackAfterPops = router.stack.length;

      await openDetail();
      expect(tester.takeException(), isNull);
      final [first, second, again] = postRouters;
      expect(
        (identical(first, second), identical(first, again), stackAfterPops),
        (false, true, 1),
      );
      expect(shown, List.filled(3, 'PostDetailRoute 1'));
    },
  );
}
