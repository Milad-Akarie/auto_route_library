import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route_generator/build_utils.dart';
import 'package:auto_route_generator/src/models/router_config.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Extracts and holds router configs
class RouterConfigResolver {
  /// Default constructor
  const new();

  /// Resolves a [ClassElement] into a consumable [RouterConfig]
  RouterConfig resolve(
    ConstantReader autoRouter,
    AssetId input,
    ClassElement clazz, {
    required bool isPartOfLibrary,
    required int cacheHash,
  }) {
    final deferredLoading =
        autoRouter.peek('deferredLoading')?.boolValue ?? false;
    final replaceInRouteName = autoRouter
        .peek('replaceInRouteName')
        ?.stringValue;
    if (replaceInRouteName != null) {
      _checkReplaceInRouteName(replaceInRouteName, clazz);
    }
    final argsEquality = autoRouter.peek('argsEquality')?.boolValue ?? false;
    final generateForDir = autoRouter
        .read('generateForDir')
        .listValue
        .map((e) => e.toStringValue()!);

    return RouterConfig(
      routerClassName: clazz.displayName,
      replaceInRouteName: replaceInRouteName,
      deferredLoading: deferredLoading,
      isPartOfLibrary: isPartOfLibrary,
      path: input.path,
      cacheHash: cacheHash,
      generateForDir: List.of(generateForDir),
      argsEquality: argsEquality,
    );
  }

  /// Throws unless [value] is a pattern and a replacement split by one
  /// comma, the replacement being something a route name can hold, so a
  /// wrong value fails the build with a message instead of giving routes
  /// that don't compile or quietly keep their `Route` suffix.
  void _checkReplaceInRouteName(String value, ClassElement clazz) {
    final parts = value.split(',');
    if (parts case [final pattern, final replacement]
        when pattern.trim().isNotEmpty) {
      if (!RegExp(r'^[A-Za-z0-9_$]*$').hasMatch(replacement.trim())) {
        throwError(
          r"The replacement in replaceInRouteName must be letters, digits, '_' or '$' to make a route name, "
          "but ${clazz.displayName} has '${replacement.trim()}' in '$value'.",
          element: clazz,
        );
      }
      return;
    }
    throwError(
      "replaceInRouteName must be a pattern and its replacement split by one comma, like 'Page|Screen,Route', "
      "but ${clazz.displayName} has '$value'.",
      element: clazz,
    );
  }
}
