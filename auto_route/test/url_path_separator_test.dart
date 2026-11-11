// Reads the package's own sources, which only the VM can.
@TestOn('vm')
library;

import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // flutter/flutter#102710: on Windows, go_router_builder joined a route's
  // location with a backslash. auto_route built urls, and normalized the
  // links it matched, with package:path's platform context, which joins with
  // '\' on Windows: '/' became '\' and matched no route, and a match's
  // fullPath came out as '/shelf\item'. A url's separator is '/' on every
  // platform, so lib/ may use package:path only through its posix context.
  // CI runs no Windows, so this reads the sources: every import of
  // package:path in lib/ must show posix alone.
  test('lib/ uses package:path only through its posix context', () {
    final imports = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File && file.path.endsWith('.dart'))
          for (final line in file.readAsLinesSync())
            if (line.contains("'package:path/path.dart'"))
              '${file.path}: $line',
    ];
    expect(imports, isNotEmpty);
    expect(
      imports.where((line) => !line.endsWith(' as p show posix;')),
      isEmpty,
    );
  });

  // flutter/flutter#102710, what a user reads: a nested match's fullPath and
  // the url of a deep link are joined with '/'.
  // Steps: '/shelf' holds 'item/:id'; match '/shelf/item/7'.
  // Should: the match's fullPath is '/shelf/item/7'.
  test('A nested match joins its fullPath with "/"', () {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'ShelfRoute',
          path: '/shelf',
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(
              name: 'ItemRoute',
              path: 'item/:id',
              builder: (_, _) => const AutoRouter(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    expect(
      router.matcher.match('/shelf/item/7')?.singleOrNull?.fullPath,
      '/shelf/item/7',
    );
  });
}
