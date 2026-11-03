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

  // #2083: a page whose only parameter is `super.key` gets a route without a
  // `key` parameter. This is by design: a const constructor whose one
  // parameter is the key lets the route build the page with `const` and be
  // const itself (`PageRouteInfo<void>`). A page that needs its key passed
  // drops `const` from its constructor and its route takes the key.
  group('a page whose only parameter is the key (#2083)', () {
    test('gets a const route without the key when its constructor is const', () async {
      final result = await generateRouter({
        'lib/screen.dart': _keyOnlyScreen(isConst: true),
      });
      expect(result.compileErrors, isEmpty);
      final source = _flatten(result.source!);
      expect(source, contains('class InitializationInvitationMissingRoute extends PageRouteInfo<void>'));
      expect(source, contains('const InitializationInvitationMissingRoute({List<PageRouteInfo>? children,})'));
      expect(source, contains('return const InitializationInvitationMissingScreen();'));
    });

    test('gets a route that takes the key when its constructor is not const', () async {
      final result = await generateRouter({
        'lib/screen.dart': _keyOnlyScreen(isConst: false),
      });
      expect(result.compileErrors, isEmpty);
      final source = _flatten(result.source!);
      expect(source, contains('InitializationInvitationMissingRoute({Key? key, List<PageRouteInfo>? children,})'));
      expect(source, contains('return InitializationInvitationMissingScreen(key: args.key);'));
    });
  });
}

String _keyOnlyScreen({required bool isConst}) => '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class InitializationInvitationMissingScreen extends StatelessWidget {
  ${isConst ? 'const ' : ''}InitializationInvitationMissingScreen({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

/// [source] without import prefixes, and with each run of whitespace made
/// one space and none after an opening or before a closing bracket.
String _flatten(String source) => source
    .replaceAll(RegExp(r'_i\d+\.'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAllMapped(RegExp(r'([({\[]) | ([)}\]])'), (m) => m[1] ?? m[2]!);
