import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../models/router_config.dart';

/// Extracts and holds router configs

class RouterConfigResolver {
  const RouterConfigResolver();

  RouterConfig resolve(
    ConstantReader autoRouter,
    AssetId input,
    ClassElement clazz, {
    bool usesPartBuilder = false,
  }) {
    // /// ensure router config classes are prefixed with $
    // /// to use the stripped name for the generated class
    // throwIf(
    //   !usesPartBuilder && !clazz.displayName.startsWith(r'$'),
    //   'Router class name must be prefixed with \$',
    //   element: clazz,
    // );

    final deferredLoading =
        autoRouter.peek('deferredLoading')?.boolValue ?? false;
    var replaceInRouteName = autoRouter.peek('replaceInRouteName')?.stringValue;

    return RouterConfig(
      routerClassName: clazz.displayName,
      replaceInRouteName: replaceInRouteName,
      deferredLoading: deferredLoading,
      usesPartBuilder: usesPartBuilder,
      path: input.path,
    );
  }
}
