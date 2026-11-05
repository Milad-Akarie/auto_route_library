import 'package:test/test.dart';

import 'support/generate.dart';

void main() {
  // Issue 1348 of Milad-Akarie/auto_route_library, also #1356 and #1438.
  // Steps were a page whose constructor takes types that it
  // imports with a prefix such as model_brand, two of them
  // named Data, one inside a List, a Color and a function type. Then build
  // the router.
  // The report was that the generated route class named the types without their
  // prefix, or typed them dynamic, so the router didn't compile.
  // The build should give no error and the generated library should compile
  // with each Data from its own import.
  test('types imported with a prefix are generated with their own import', () async {
    final result = await generateRouter({
      'lib/brand_model.dart': 'class Data { const Data(); }',
      'lib/treatment_model.dart': 'class Data { const Data(); }',
      'lib/booking_page.dart': '''
import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'brand_model.dart' as model_brand;
import 'treatment_model.dart' as model_treatment;

@RoutePage()
class BookingPage extends StatelessWidget {
  const BookingPage({
    super.key,
    required this.brand,
    required this.treatments,
    required this.color,
    required this.onPressed,
  });

  final model_brand.Data brand;
  final List<model_treatment.Data> treatments;
  final Color color;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''',
    });
    expect(result.errors, isEmpty);
    expect(result.compileErrors, isEmpty);
    final source = result.source!;
    expect(source, isNot(contains('dynamic')));
    expect(source, matches(RegExp(r'required (_i\d+\.)?Color color')));
    // Each Data is imported from its own library, under its own prefix.
    expect(source, contains('brand_model.dart'));
    expect(source, contains('treatment_model.dart'));
    expect(source, matches(RegExp(r'_i\d+\.Data brand')));
    expect(source, matches(RegExp(r'List<_i\d+\.Data> treatments')));
  });
}
