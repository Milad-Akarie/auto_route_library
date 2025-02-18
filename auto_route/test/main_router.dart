import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'test_page.dart';

part 'main_router.gr.dart';

@AutoRouterConfig(generateForDir: ['test'])
abstract class MainRouter extends RootStackRouter {}
