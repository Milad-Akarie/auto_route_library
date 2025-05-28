import 'package:auto_route_generator/src/models/router_config.dart';
import 'package:lean_builder/builder.dart';
import 'package:lean_builder/element.dart';

/// Extracts and holds router configs
class LeanRouterConfigResolver {
  /// Default constructor
  LeanRouterConfigResolver();

  /// Resolves a [ClassElement] into a consumable [RouterConfig]
  RouterConfig resolve(
    ConstObject autoRouter,
    Asset input,
    ClassElement clazz, {
    bool usesPartBuilder = false,
  }) {
    final deferredLoading = autoRouter.getBool('deferredLoading')?.value ?? false;
    final replaceInRouteName = autoRouter.getString('replaceInRouteName')?.value;
    final argsEquality = autoRouter.getBool('argsEquality')?.value ?? false;
    final generateForDir = autoRouter.getList('generateForDir')?.literalValue.cast<String>() ?? [];

    return RouterConfig(
      routerClassName: clazz.name,
      replaceInRouteName: replaceInRouteName,
      deferredLoading: deferredLoading,
      usesPartBuilder: usesPartBuilder,
      path: input.shortUri.toString(),
      cacheHash: 0,
      generateForDir: List.of(generateForDir),
      argsEquality: argsEquality,
    );
  }
}
