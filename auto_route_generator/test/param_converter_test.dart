import 'package:test/test.dart';

import 'support/generate.dart';

/// A value class for ids and its converter, as the issue describes.
const _kUserId = '''
import 'package:auto_route/auto_route.dart';

class UserId {
  const UserId(this.value);

  final String value;
}

class UserIdConverter extends ParamConverter<UserId> {
  const UserIdConverter();

  @override
  UserId? fromParam(String value) => value.isEmpty ? null : UserId(value);

  @override
  String toParam(UserId value) => value.value;
}

const userIdConverter = UserIdConverter();
''';

/// A page library holding `@RoutePage() class UserPage` whose constructor
/// takes [parameters], declared as [fields].
String _userPage(String parameters, String fields) =>
    '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'user_id.dart';

@RoutePage()
class UserPage extends StatelessWidget {
  const UserPage({super.key, $parameters});

$fields

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

/// The generated source without import prefixes, white space and trailing
/// commas, so a test can look for a line of code.
String _flat(GeneratedRouter result) => result.source!
    .replaceAll(RegExp(r'_i\d+\.'), '')
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAll(RegExp(r',(?=[)}\]])'), '');

void main() {
  // #1794: an app with value classes for its ids could not take one as a path
  // or query param; `@PathParam() UserId id` was refused at build time. A
  // ParamConverter given to the annotation now reads the value from the url
  // and writes it back.
  group('a ParamConverter (#1794)', () {
    test('reads and writes a path param of its type', () async {
      final result = await generateRouter({
        'lib/user_id.dart': _kUserId,
        'lib/user_page.dart': _userPage("@PathParam('id', userIdConverter) required this.id", 'final UserId id;'),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = _flat(result);
      expect(source, contains("rawPathParams:{'id':userIdConverter.toParam(id)}"));
      expect(source, contains("id:pathParams.getTyped<UserId>('id',userIdConverter)"));
    });

    test('reads and writes an optional query param, with or without a default', () async {
      final result = await generateRouter({
        'lib/user_id.dart': _kUserId,
        'lib/user_page.dart': _userPage(
          "@QueryParam('by', userIdConverter) this.by, "
              "@QueryParam('to', userIdConverter) this.to = const UserId('me')",
          'final UserId? by;\nfinal UserId to;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = _flat(result);
      expect(source, contains("'by':by==null?null:userIdConverter.toParam(by)"));
      expect(source, contains("'to':userIdConverter.toParam(to)"));
      expect(source, contains("by:queryParams.optTyped<UserId>('by',userIdConverter)"));
      expect(source, contains("to:queryParams.getTyped<UserId>('to',userIdConverter,constUserId('me'))"));
    });

    test('on an inherited path param reads it from the parent', () async {
      final result = await generateRouter({
        'lib/user_id.dart': _kUserId,
        'lib/user_page.dart': _userPage(
          "@PathParam.inherit('id', userIdConverter) required this.id",
          'final UserId id;',
        ),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(_flat(result), contains("id:pathParams.getTyped<UserId>('id',userIdConverter)"));
    });

    test('on an enum replaces reading it by its name', () async {
      final result = await generateRouter({
        'lib/user_id.dart': r'''
import 'package:auto_route/auto_route.dart';

enum Level { low, high }

class LevelConverter extends ParamConverter<Level> {
  const LevelConverter();

  @override
  Level? fromParam(String value) => switch (value) { '1' => Level.low, '2' => Level.high, _ => null };

  @override
  String toParam(Level value) => '${value.index + 1}';
}

const levelConverter = LevelConverter();
''',
        'lib/user_page.dart': _userPage("@QueryParam('level', levelConverter) this.level", 'final Level? level;'),
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      final source = _flat(result);
      expect(source, contains("level:queryParams.optTyped<Level>('level',levelConverter)"));
      expect(source, isNot(contains('asNameMap')));
    });

    test('for another type fails the build naming both', () async {
      final result = await generateRouter({
        'lib/user_id.dart': _kUserId,
        'lib/user_page.dart': _userPage("@PathParam('id', userIdConverter) required this.id", 'final int id;'),
      });
      expect(result.errors.join(), contains('The converter on id converts UserId, but id is a int.'));
    });

    test('written in the annotation fails the build asking for a top-level constant', () async {
      final result = await generateRouter({
        'lib/user_id.dart': _kUserId,
        'lib/user_page.dart': _userPage("@PathParam('id', UserIdConverter()) required this.id", 'final UserId id;'),
      });
      expect(result.errors.join(), contains('The converter on id must be a top-level const variable'));
    });

    test('missing on a type a url can not give fails the build asking for one', () async {
      final result = await generateRouter({
        'lib/user_id.dart': _kUserId,
        'lib/user_page.dart': _userPage("@PathParam('id') required this.id", 'final UserId id;'),
      });
      expect(result.errors.join(), contains('give @PathParam a ParamConverter<UserId>'));
    });
  });
}
