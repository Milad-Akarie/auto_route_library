import 'package:test/test.dart';

import 'support/generate.dart';

const _failure = '''
class Failure {}

class IndexCubit<F extends Failure, T> {}
''';

void main() {
  // #332: a page class with type parameters, such as
  // `ViewAllPage<F extends Failure, T>`, failed the build with "Could not
  // format because the source could not be parsed": the generator wrote the
  // type parameters into the route's names, as `ViewAllRoute<F, T>Args`. A
  // route builds its page from its name and args alone, so a generic page
  // class is not supported; the build now says so and how to get around it.
  test('a page class with type parameters fails the build naming it (#332)', () async {
    final result = await generateRouter({
      'lib/failure.dart': _failure,
      'lib/view_all_page.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'failure.dart';

@RoutePage()
class ViewAllPage<F extends Failure, T> extends StatelessWidget {
  const ViewAllPage({super.key, required this.indexCubit, required this.title});

  final IndexCubit<F, T> indexCubit;
  final String title;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''',
    });
    expect(result.errors.join(), contains('ViewAllPage has type parameters, and a @RoutePage class can not have any.'));
    expect(result.errors.join(), isNot(contains('Could not format')));
  });

  // What works instead: a page class without type parameters that builds the
  // generic widget with its type, taking arguments of that type.
  test('a page that builds a generic widget with its type compiles (#332)', () async {
    final result = await generateRouter({
      'lib/failure.dart': _failure,
      'lib/view_all_page.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'failure.dart';

class ViewAll<F extends Failure, T> extends StatelessWidget {
  const ViewAll({super.key, required this.indexCubit});

  final IndexCubit<F, T> indexCubit;

  @override
  Widget build(BuildContext context) => const SizedBox();
}

@RoutePage()
class ViewAllNamesPage extends StatelessWidget {
  const ViewAllNamesPage({super.key, required this.indexCubit});

  final IndexCubit<Failure, String> indexCubit;

  @override
  Widget build(BuildContext context) => ViewAll<Failure, String>(indexCubit: indexCubit);
}
''',
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    expect(result.source, matches(RegExp(r'final _i\d+\.IndexCubit<_i\d+\.Failure, String> indexCubit;')));
  });
}
