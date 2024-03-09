
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'model_index.dart';

// ignore_for_file: public_member_api_docs
@RoutePage<Generice<List<String>>>()
class TestPage {
  final Key query;
  final Generice<DemoModel> model;
  TestPage({
    required this.query,
    required this.model,
    Generice<DemoModel> Function(String x, [int y])? x,
  });
}
