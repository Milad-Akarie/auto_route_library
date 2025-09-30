import 'package:analyzer/dart/element/element2.dart';
import 'package:source_gen/source_gen.dart';

import '../../build_utils.dart';
import '../models/route_config.dart';
import '../models/route_parameter_config.dart';
import '../resolvers/route_parameter_resolver.dart';
import '../resolvers/type_resolver.dart';

/// extracts route configs from class fields and their meta data
class RouteConfigResolver {
  final TypeResolver _typeResolver;

  /// Default constructor
  RouteConfigResolver(this._typeResolver);

  /// Resolves a [ClassElement2] into a consumable [RouteConfig]
  RouteConfig resolve(Element2 element, ConstantReader routePage) {
    var isDeferred = routePage.peek('deferredLoading')?.boolValue;
    throwIf(
      element is! ClassElement2,
      '${element.displayName} is not a class element',
      element: element,
    );

    final classElement = element as ClassElement2;
    final page = classElement.thisType;
    final hasWrappedRoute = classElement.allSupertypes.any((e) => e.nameWithoutSuffix == 'AutoRouteWrapper');
    var pageType = _typeResolver.resolveType(page);
    var className = page.nameWithoutSuffix;

    var name = routePage.peek('name')?.stringValue;
    final constructor = classElement.unnamedConstructor2;
    throwIf(
      constructor == null,
      'Route pages must have an unnamed constructor',
    );
    var hasConstConstructor = false;
    var params = constructor!.formalParameters;
    var parameters = <ParamConfig>[];
    if (params.isNotEmpty) {
      if (constructor.isConst && params.length == 1 && params.first.type.nameWithoutSuffix == 'Key') {
        hasConstConstructor = true;
      } else {
        final paramResolver = RouteParameterResolver(_typeResolver);
        for (final p in params) {
          parameters.add(paramResolver.resolve(p));
        }
      }
    }

    throwIf(
      parameters.where((e) => e.isUrlFragment).length > 1,
      'Only one parameter can be annotated with @urlFragment',
      element: element,
    );

    var pathParameters = parameters.where((element) => element.isPathParam);

    if (parameters.any((p) => p.isPathParam || p.isQueryParam)) {
      var unParsableRequiredArgs =
          parameters.where((p) => (p.isRequired || p.isPositional) && !p.isPathParam && !p.isQueryParam);
      if (unParsableRequiredArgs.isNotEmpty) {
        print(
            '\nWARNING => Because [$className] has required parameters ${unParsableRequiredArgs.map((e) => e.paramName)} '
            'that can not be parsed from path,\n@PathParam() and @QueryParam() annotations will be ignored.\n');
      }
    }

    if (pathParameters.isNotEmpty) {
      for (var pParam in pathParameters) {
        throwIf(
          !validPathParamTypes.contains(pParam.type.name),
          "Parameter [${pParam.name}] must be of a type that can be parsed from a [String] because it will also obtain it's value from a path\nvalid types: $validPathParamTypes",
        );
      }
    }

    return RouteConfig(
      className: className,
      name: name,
      hasWrappedRoute: hasWrappedRoute,
      parameters: parameters,
      hasConstConstructor: hasConstConstructor,
      pageType: pageType,
      deferredLoading: isDeferred,
    );
  }
}
