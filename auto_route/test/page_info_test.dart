import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("PageInfo equality test", () {
    expect(const PageInfo('Name') == const PageInfo('Name'), true);
  });
}
