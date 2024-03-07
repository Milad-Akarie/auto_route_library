import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

import 'model_index.dart';

@RoutePage()
class TestPage {
  final String param1;
  final Offset param2;
  final Generice<int> generice2;

  TestPage(
    this.param1, {
    required String x,
    required this.generice,
    void Function()? onPop,
  });
}
