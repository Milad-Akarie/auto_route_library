import 'package:test/test.dart';

import 'support/generate.dart';

void main() {
  // #2060: a page extending riverpod's ConsumerWidget with only `super.key`
  // was reported to generate `ContributionsPage(key: args.key)` with a
  // dynamic `args.key`: "The argument type 'dynamic' can't be assigned to
  // the parameter type 'Key?'". It works: the key's type comes from the
  // base class's constructor, so the page gets a const route without
  // arguments. The base class here has ConsumerWidget's constructor and
  // lives in its own package, as riverpod's does.
  test('a page whose base class in another package takes the key (#2060)', () async {
    final result = await generateRouter({
      'riverpod_stub|lib/riverpod_stub.dart': '''
import 'package:flutter/widgets.dart';

abstract class ConsumerWidget extends StatefulWidget {
  const ConsumerWidget({super.key});

  Widget build(BuildContext context, Object ref);

  @override
  State<ConsumerWidget> createState() => _ConsumerState();
}

class _ConsumerState extends State<ConsumerWidget> {
  @override
  Widget build(BuildContext context) => widget.build(context, this);
}
''',
      'lib/contributions_page.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_stub/riverpod_stub.dart';

@RoutePage()
class ContributionsPage extends ConsumerWidget {
  const ContributionsPage({super.key});

  @override
  Widget build(BuildContext context, Object ref) => const SizedBox();
}
''',
      'lib/router.dart': '''
import 'package:auto_route/auto_route.dart';

import 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: '/', page: ContributionsRoute.page),
        RedirectRoute(path: '*', redirectTo: '/'),
      ];
}
''',
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    final source = result.source!.replaceAll(RegExp(r'_i\d+\.'), '');
    expect(source, contains('class ContributionsRoute extends PageRouteInfo<void>'));
    expect(source, contains('return const ContributionsPage();'));
  });
}
