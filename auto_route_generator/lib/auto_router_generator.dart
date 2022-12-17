import 'dart:convert';
import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route_generator/src/code_builder/library_builder.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'src/resolvers/router_config_resolver.dart';
import 'utils.dart';
import 'package:auto_route/annotations.dart';

class AutoRouterGenerator extends GeneratorForAnnotation<AutoRouterConfig> {
  @override
  dynamic generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // throw if annotation is used for a none class element
    throwIf(
      element is! ClassElement,
      '${element.name} is not a class element',
      element: element,
    );
    final clazz = element as ClassElement;
    final usesPartBuilder = _hasPartDirective(clazz);
    final router = RouterConfigResolver().resolve(
      annotation,
      clazz,
      usesPartBuilder: usesPartBuilder,
    );

    final routes = <RouteConfig>[];
    await for (final asset in buildStep.findAssets(Glob('**.route.json'))) {
      routes.add(RouteConfig.fromJson(jsonDecode(await buildStep.readAsString(asset))));
    }

    final registeredRoutes = await _extractRegisteredRoutes(clazz, buildStep);
    if (registeredRoutes != null) {
      File('.dart_tool/build/generated/router_config.json').writeAsStringSync(
        jsonEncode(registeredRoutes.toJson()),
      );
    }

    return generateLibrary(router, routes: routes);
  }

  bool _hasPartDirective(ClassElement clazz) {
    final fileName = clazz.source.uri.pathSegments.last;
    final part = fileName.replaceAll(
      '.dart',
      '.gr.dart',
    );
    return clazz.library.parts.any(
      (e) => e.toString().endsWith(part),
    );
  }

  Future<RegisteredRouteList?> _extractRegisteredRoutes(ClassElement clazz, BuildStep buildStep) async {
    try {
      final routesGetter = clazz.getGetter('routes')!.variable;
      final routesNode = await buildStep.resolver.astNodeFor(routesGetter, resolve: true) as VariableDeclaration?;
      if (routesNode != null) {
        final list = routesNode.childEntities.last as ListLiteral;

        Future<List<RegisteredRoute>> extractRoutes(ListLiteral list, {SpreadListInfo? spreadListInfo}) async {
          final registeredRoutes = <RegisteredRoute>[];
          bool routeHasTrailingComma = false;
          for (final element in list.elements) {
            if (element is SpreadElement && element.expression is Identifier) {
              final list = await _getIdentifiedList(buildStep, element.expression as Identifier);
              if (list != null) {
                registeredRoutes.addAll(
                  await extractRoutes(
                    list.entries,
                    spreadListInfo: SpreadListInfo(
                        path: list.path,
                        offset: list.entries.rightBracket.offset,
                        hasTrailingComma: list.entries.rightBracket.previous?.toString() == ','),
                  ),
                );
              }
            } else if (element is InstanceCreationExpression) {
              final argsList = element.argumentList.arguments.whereType<NamedExpression>();
              final nameArg = argsList.firstOrNull((e) => e.name.label.name == 'name');
             routeHasTrailingComma =  element.argumentList.rightParenthesis.previous?.toString() == ',';
              if (nameArg != null) {
                final name = nameArg.childEntities.last.toString();
                final childrenList = argsList.firstOrNull((e) => e.name.label.name == 'children');
                var childList = <RegisteredRoute>[];
                var path = buildStep.inputId.path;
                final childrenListExpression = childrenList?.expression;
                if (childrenListExpression is ListLiteral) {
                  childList.addAll(await extractRoutes(childrenListExpression));
                } else if (childrenListExpression is Identifier && childrenListExpression.staticElement != null) {
                  final list = await _getIdentifiedList(buildStep, childrenListExpression);
                  if (list != null) {
                    childList.addAll(await extractRoutes(list.entries));
                    path = list.path;
                  }
                }
                registeredRoutes.add(
                  RegisteredRoute(
                    name,
                    offset: element.offset,
                    hasTrailingComma: routeHasTrailingComma,
                    spreadListInfo: spreadListInfo,
                    children: childList.isEmpty
                        ? null
                        : RegisteredRouteList(
                            childList,
                            path: path,
                            hasTrailingComma: list.rightBracket.previous?.toString() == ',',
                            offset: list.rightBracket.offset,
                          ),
                  ),
                );
              }
            }
          }
          return registeredRoutes;
        }

        return RegisteredRouteList(
          await extractRoutes(list),
          offset: list.rightBracket.offset,
          hasTrailingComma: list.rightBracket.previous?.toString() == ',',
          path: buildStep.inputId.path,
        );
      }
    } catch (e) {}
    return null;
  }

  Future<IdentifiedList?> _getIdentifiedList(BuildStep buildStep, Identifier childrenListExpression) async {
    final staticElement = childrenListExpression.staticElement;
    if (staticElement == null) return null;
    final childRoutes = await buildStep.resolver
        .astNodeFor((staticElement as PropertyAccessorElement).variable, resolve: true) as VariableDeclaration?;
    final list = childRoutes?.childEntities.last as ListLiteral?;
    if (list == null) return null;
    final asset = await buildStep.resolver.assetIdForElement(staticElement);
    return IdentifiedList(asset.path, list);
  }
}

class IdentifiedList {
  final String path;
  final ListLiteral entries;

  IdentifiedList(this.path, this.entries);
}

class RegisteredRouteList {
  final List<RegisteredRoute> names;
  final int offset;
  final bool hasTrailingComma;
  final String path;

  const RegisteredRouteList(
    this.names, {
    this.offset = 0,
    this.hasTrailingComma = false,
    required this.path,
  });

  Map<String, dynamic> toJson() {
    return {
      'names': names.map((e) => e.toJson()).toList(),
      'offset': offset,
      'path': path,
      'hasTrailingComma': hasTrailingComma,
    };
  }
}

class SpreadListInfo {
  final int offset;
  final bool hasTrailingComma;
  final String path;

  SpreadListInfo({
    required this.path,
    required this.offset,
    required this.hasTrailingComma,
  });

  Map<String, dynamic> toJson() {
    return {
      'offset': offset,
      'hasTrailingComma': hasTrailingComma,
      'path': path,
    };
  }
}

class RegisteredRoute {
  final String name;
  final int offset;
  final bool hasTrailingComma;
  final RegisteredRouteList? children;
  final SpreadListInfo? spreadListInfo;

  RegisteredRoute(
    this.name, {
    this.children,
    this.spreadListInfo,
    required this.offset,
    required this.hasTrailingComma,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'offset': offset,
      'hasTrailingComma': hasTrailingComma,
      if (children != null) 'children': children?.toJson(),
      if (spreadListInfo != null) 'spreadListPath': spreadListInfo?.toJson(),
    };
  }
}
