library auto_route;

import 'package:flutter/material.dart';

export 'src/auto_router_module.dart';
export 'src/common/common.dart';
export 'src/matcher/route_match.dart';
export 'src/navigation_failure.dart';
export 'src/route/auto_route_config.dart' hide DummyRootRoute;
export 'src/route/page_info.dart';
export 'src/route/page_route_info.dart';
export 'src/route/route_data_scope.dart';
export 'src/route/route_type.dart';
export 'src/router/auto_route_page.dart';
export 'src/router/auto_router_x.dart';
export 'src/router/controller/controller_scope.dart';
export 'src/router/controller/pageless_routes_observer.dart';
export 'src/router/controller/routing_controller.dart';
export 'src/router/parser/route_information_parser.dart';
export 'src/router/provider/auto_route_information_provider.dart';
export 'src/router/widgets/auto_leading_button.dart';
export 'src/router/widgets/auto_page_view.dart';
export 'src/router/widgets/auto_route_navigator.dart';
export 'src/router/widgets/auto_router.dart';
export 'src/router/widgets/auto_tabs_router.dart';
export 'src/router/widgets/auto_tabs_scaffold.dart';
export 'src/router/widgets/custom_cupertino_transitions_builder.dart';
export 'src/router/widgets/deferred_widget.dart';

extension IterableX<T> on Iterable<T>? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}

extension BoolX on bool? {
  bool get isTrue => this == true;

  bool get isFalse => this == false;
}


extension StringGuardX on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  T let<T>(T Function(String str) block, T Function() orElse) => isNullOrEmpty ? orElse() : block(this!);
}

void worker() {
  String? name;
  print(name.isNullOrBlank);
  Widget nameWidget = name.let(Text.new, SizedBox.new);
}

