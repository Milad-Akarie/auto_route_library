import 'package:test/test.dart';

import 'support/generate.dart';

const _failure = '''
class Failure {}

class IndexCubit<F extends Failure, T> {}
''';

/// The generated source without import prefixes, white space and trailing
/// commas, so a test can look for a line of code.
String _flat(GeneratedRouter result) => result.source!
    .replaceAll(RegExp(r'_i\d+\.'), '')
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAll(RegExp(r',(?=[)}\]])'), '');

void main() {
  // #2050, #1879, #1739: a page class with type parameters, such as
  // `PickerPage<T>`, failed the build with "Could not format because the
  // source could not be parsed": the generator wrote the type parameters
  // into the route's names, as `PickerRoute<T>Args`. Since #332 the build
  // refused such a page. Now the route and its args take the page's type
  // parameters, so `PickerRoute<int>(...)` opens `PickerPage<int>`.
  group('a generic page (#2050)', () {
    test('gives a generic route and args class that build the page with their type', () async {
      final result = await generateRouter({
        'lib/picker_page.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class PickerPage<T> extends StatelessWidget {
  const PickerPage({super.key, required this.items, this.selected, this.onPicked});

  final List<T> items;
  final T? selected;
  final void Function(T item)? onPicked;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''',
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = _flat(result);
      expect(source, contains('classPickerRoute<T>extendsPageRouteInfo<PickerRouteArgs<T>>'));
      expect(source, contains('args:PickerRouteArgs<T>(key:key,items:items,selected:selected,onPicked:onPicked)'));
      expect(source, contains('classPickerRouteArgs<T>{'));
      expect(source, contains('finalList<T>items;'));
      expect(source, contains('finalT?selected;'));
      expect(source, contains('PickerPage<T>buildPage()'));
      expect(source, contains('returnargs.buildPage();'));
      // A constant can't name T, so the items are compared as dynamic.
      expect(source, contains('constListEquality<dynamic>().equals(items,other.items)'));
    });

    // #332's page: two type parameters, one with a bound from another
    // library.
    test('keeps each bound, with its import', () async {
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
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = _flat(result);
      expect(source, contains('classViewAllRoute<FextendsFailure,T>extendsPageRouteInfo<ViewAllRouteArgs<F,T>>'));
      expect(source, contains('finalIndexCubit<F,T>indexCubit;'));
    });

    test('without parameters still carries its type in its args', () async {
      final result = await generateRouter({
        'lib/editing_page.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class EditingController {}

@RoutePage()
class EditingPage<T extends EditingController> extends StatelessWidget {
  const EditingPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''',
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = _flat(result);
      expect(source, contains('classEditingRoute<TextendsEditingController>extendsPageRouteInfo<EditingRouteArgs<T>>'));
      expect(source, contains('args:EditingRouteArgs<T>(key:key)'));
      expect(source, contains('orElse:()=>constEditingRouteArgs()'));
    });

    // #1296: `DetailScreen<T>` with a path param and an optional `T? detail`,
    // opened from a url, gets its type's bound and reads the path param.
    test('with a path param reads it from the url', () async {
      final result = await generateRouter({
        'lib/detail_screen.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class DetailScreen<T> extends StatelessWidget {
  const DetailScreen({super.key, @PathParam() required this.detailName, this.detail});

  final String detailName;
  final T? detail;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''',
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(_flat(result), contains("orElse:()=>DetailRouteArgs(detailName:pathParams.getString('detailName'))"));
    });

    test('with an inherited path param passes it to the page', () async {
      final result = await generateRouter({
        'lib/detail_screen.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class DetailScreen<T> extends StatelessWidget {
  const DetailScreen({super.key, @PathParam.inherit() required this.id, this.detail});

  final String id;
  final T? detail;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''',
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(_flat(result), contains("args.buildPage(id:pathParams.getString('id'))"));
    });
  });

  // What works without a generic route: a page class without type
  // parameters that builds the generic widget with its type.
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
