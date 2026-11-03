import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'test_page.dart';

part 'main_router.gr.dart';

// Only test_page.dart: the test routers of other folders, such as
// enum_query_param, name their routes with their own settings.
@AutoRouterConfig(generateForDir: ['test/test_page'])
abstract class MainRouter extends RootStackRouter {}
