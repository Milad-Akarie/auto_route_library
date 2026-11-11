import 'package:test/test.dart';

import 'support/generate.dart';

/// A router library that imports the profile page and nothing else of the app,
/// in a part file when [isPart], else with its routes in their own library.
String _router({required bool isPart}) =>
    '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'profile_page.dart';

${isPart ? "part 'router.gr.dart';" : "import 'router.gr.dart';"}

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [AutoRoute(page: ProfileRoute.page)];
}
''';

const _kUserFile = '''
class User {
  const User(this.name);

  final String name;
}
''';

const _kProfilePage = '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'models/user.dart';

@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) => Text(user.name);
}
''';

void main() {
  // #776: with the router in a part file, a route argument whose type the
  // page imports but the router file does not, `User` from
  // `models/user.dart`, left a router that does not compile. A part shares
  // its library's imports and can add none, so the router file must import
  // the type: that is how Dart parts work, not a generator bug. Generated as
  // its own library, the default, the router imports the type itself.
  group('a route argument type the router file does not import (#776)', () {
    test('compiles when the router is its own library', () async {
      final result = await generateRouter({
        'lib/router.dart': _router(isPart: false),
        'lib/models/user.dart': _kUserFile,
        'lib/profile_page.dart': _kProfilePage,
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
      expect(
        result.source,
        contains("import 'package:app/models/user.dart' as _i"),
      );
    });

    test('in a part file needs the router file to import it', () async {
      final result = await generateRouter({
        'lib/router.dart': _router(isPart: true),
        'lib/models/user.dart': _kUserFile,
        'lib/profile_page.dart': _kProfilePage,
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors.join('\n'), contains('User'));
    });

    test('compiles in a part file once the router file imports it', () async {
      final result = await generateRouter({
        'lib/router.dart': _router(isPart: true)
            .replaceFirst("import 'profile_page.dart';", '''
import 'models/user.dart';
import 'profile_page.dart';'''),
        'lib/models/user.dart': _kUserFile,
        'lib/profile_page.dart': _kProfilePage,
      });
      expect(result.errors, isEmpty);
      expect(result.compileErrors, isEmpty);
    });
  });
}
