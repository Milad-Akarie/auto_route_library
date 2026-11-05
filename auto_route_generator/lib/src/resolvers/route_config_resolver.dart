import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route_generator/build_utils.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/route_parameter_config.dart';
import 'package:auto_route_generator/src/models/url_param_type.dart';
import 'package:auto_route_generator/src/resolvers/route_parameter_resolver.dart';
import 'package:auto_route_generator/src/resolvers/type_resolver.dart';
import 'package:source_gen/source_gen.dart';

/// extracts route configs from class fields and their meta data
class RouteConfigResolver {
  /// Default constructor
  RouteConfigResolver(this._typeResolver);
  final TypeResolver _typeResolver;

  /// Resolves a [ClassElement] into a consumable [RouteConfig]
  RouteConfig resolve(Element element, ConstantReader routePage) {
    final isDeferred = routePage.peek('deferredLoading')?.boolValue;
    throwIf(element is! ClassElement, '${element.displayName} is not a class element', element: element);

    final classElement = element as ClassElement;
    final page = classElement.thisType;
    final hasWrappedRoute = classElement.allSupertypes.any((e) => e.nameWithoutSuffix == 'AutoRouteWrapper');
    final pageType = _typeResolver.resolveType(page);
    // The name alone: the type's display name has the type parameters.
    final className = classElement.displayName;
    final typeParameters = [
      for (final t in classElement.typeParameters)
        RouteTypeParameter(name: t.displayName, bound: t.bound == null ? null : _typeResolver.resolveType(t.bound!)),
    ];

    final name = routePage.peek('name')?.stringValue;
    final constructor = classElement.unnamedConstructor;
    throwIf(constructor == null, 'Route pages must have an unnamed constructor');
    var hasConstConstructor = false;
    final params = constructor!.formalParameters;
    final parameters = <ParamConfig>[];
    if (params.isNotEmpty) {
      // A generic page is built by its args, which carry its type arguments.
      if (constructor.isConst &&
          typeParameters.isEmpty &&
          params.length == 1 &&
          params.first.type.nameWithoutSuffix == 'Key') {
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

    final pathParameters = parameters.where((candidate) => candidate.isPathParam);

    if (parameters.any((p) => p.isPathParam || p.isQueryParam)) {
      final unParsableRequiredArgs = parameters.where(
        (p) => (p.isRequired || p.isPositional) && !p.isPathParam && !p.isQueryParam,
      );
      if (unParsableRequiredArgs.isNotEmpty) {
        // build_runner shows a builder's print as its output.
        // ignore: avoid_print
        print(
          '\nWARNING => Because [$className] has required parameters ${unParsableRequiredArgs.map((e) => e.paramName)} '
          'that can not be parsed from path,\n@PathParam() and @QueryParam() annotations will be ignored.\n',
        );
      }
    }

    // A query param is read from the url unless a required argument keeps
    // the page from being opened by one, so its type must be one the url
    // gives; any other was read as `dynamic` and threw when a link opened
    // the page.
    final readsUrl = !parameters.any((p) => (p.isRequired || p.isPositional) && !p.isPathParam && !p.isQueryParam);
    for (final qParam in parameters.where((p) => p.isQueryParam && readsUrl)) {
      final type = qParam.type;
      throwIf(
        qParam.urlType == null,
        'Parameter [${qParam.name}] is a @QueryParam of type ${type.name}, which a url can not give.\n'
        'valid types: ${UrlParamType.pathTypeNames}, Object, an enum, or a ${kUrlCollectionTypes.join(', ')} of those',
      );
    }

    for (final pParam in pathParameters) {
      throwIf(
        !(pParam.urlType?.inPath ?? false),
        "Parameter [${pParam.name}] must be of a type that can be parsed from a [String] because it will also obtain it's value from a path\nvalid types: ${UrlParamType.pathTypeNames}\n"
        'For any other type, give @PathParam a ParamConverter<${pParam.type.name}>, '
        "as in @PathParam('${pParam.paramName}', ${_lowerFirst(pParam.type.name)}Converter).",
      );
    }
    return RouteConfig(
      className: className,
      name: name,
      hasWrappedRoute: hasWrappedRoute,
      parameters: parameters,
      hasConstConstructor: hasConstConstructor,
      pageType: pageType,
      deferredLoading: isDeferred,
      typeParameters: typeParameters,
    );
  }
}

String _lowerFirst(String text) => text.isEmpty ? text : text[0].toLowerCase() + text.substring(1);
