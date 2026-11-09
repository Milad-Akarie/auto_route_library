import 'package:test/test.dart';

import 'support/generate.dart';

String _page(String name) =>
    '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

@RoutePage()
class $name extends StatelessWidget {
  const $name({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

void main() {
  // #1995: some pages in a deeply nested directory got no route. The report
  // has no steps and the maintainer's question went unanswered. Assumed
  // cause, from the reporter's guess: a long path. Steps: pages at the top
  // of lib/, at a depth of 12 folders with long names, and in a folder of
  // another package, then build the router. When the bug is real the router
  // holds no route (or a missing page) for the deep ones.
  test('pages in a deeply nested directory get routes', () async {
    const deep =
        'lib/features/administration/organization_management/'
        'user_accounts/permissions_and_roles/access_control/audit_logging/'
        'reports_and_exports/scheduled_jobs/notifications/templates/editor';
    final result = await generateRouter({
      'lib/home_page.dart': _page('HomePage'),
      '$deep/template_editor_page.dart': _page('TemplateEditorPage'),
      '$deep/preview/template_preview_page.dart': _page('TemplatePreviewPage'),
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    expect(result.source, contains('class HomeRoute'));
    expect(result.source, contains('class TemplateEditorRoute'));
    expect(result.source, contains('class TemplatePreviewRoute'));
  });
}
