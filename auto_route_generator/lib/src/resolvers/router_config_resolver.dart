import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../models/router_config.dart';

/// Extracts and holds router configs
class RouterConfigResolver {
  /// Default constructor
  RouterConfigResolver();

  /// Resolves a [ClassElement2] into a consumable [RouterConfig]
  RouterConfig resolve(
    ConstantReader autoRouter,
    AssetId input,
    ClassElement2 clazz, {
    bool usesPartBuilder = false,
    int? cacheHash,
  }) {
    final deferredLoading = autoRouter.peek('deferredLoading')?.boolValue ?? false;
    final replaceInRouteName = autoRouter.peek('replaceInRouteName')?.stringValue;
    final argsEquality = autoRouter.peek('argsEquality')?.boolValue ?? false;
    final generateForDir = autoRouter.read('generateForDir').listValue.map((e) => e.toStringValue()!);

    return RouterConfig(
      routerClassName: clazz.displayName,
      replaceInRouteName: replaceInRouteName,
      deferredLoading: deferredLoading,
      usesPartBuilder: usesPartBuilder,
      path: input.path,
      cacheHash: cacheHash,
      generateForDir: List.of(generateForDir),
      argsEquality: argsEquality,
    );
  }
}
