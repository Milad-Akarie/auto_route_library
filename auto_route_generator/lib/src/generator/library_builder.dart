import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/src/generator/route_info_class_builder.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

String generateCode(RouterConfig config) {
  final library = Library(
    (b) => b
      ..body.addAll([
        ...config.routes.map(buildRouteInfo),
      ]),
  );

  final emitter = DartEmitter(Allocator.simplePrefixing());
  return DartFormatter().format('${library.accept(emitter)}');
}

void main() {
  final library = Library(
    (b) => b
      ..body.addAll([
        Class((b) => b
          ..name = "NavController"
          ..extend = refer("NavigationController")
          ..fields.addAll([
            Field((b) => b
              ..modifier = FieldModifier.constant
              ..name = 'key'
              ..static = true
              ..type = refer("String")
              ..assignment = Code("'/home'")),
            Field((b) => b
              ..modifier = FieldModifier.constant
              ..name = 'routes'
              ..static = true
              ..type = TypeReference(
                (b) => b
                  ..symbol = 'List'
                  ..types.add(
                    refer('route', 'package/es/es.dart'),
                  ),
              )
              ..assignment = literalList([
                refer("route").newInstance([
                  refer("HomeScreen").property('key'),
                ]),
              ]).code),
            Field((b) => b
              ..modifier = FieldModifier.final$
              ..name = 'pagesMap'
              ..annotations.add(refer('override'))
              ..static = true
              ..type = TypeReference(
                (b) => b
                  ..symbol = 'Map'
                  ..types.addAll([
                    refer('String'),
                    refer('PageFactory'),
                  ]),
              )
              ..assignment = literalMap({
                refer('HomeScreen').property('key'): Method(
                  (b) => b
                    ..requiredParameters.add(
                      Parameter((b) => b.name = "data"),
                    )
                    ..body = TypeReference((b) => b
                      ..symbol = 'XMaterialPage'
                      ..types.add(refer('dynamic'))).newInstance([], {
                      'data': refer('data'),
                      'child': refer('PageOne', 'package/pageOne/pageOne.dart').newInstance([
                        refer('data.args.id'),
                      ]),
                    }).code,
                ).closure,
              }).code)
          ])
          ..constructors.add(
            Constructor(
              (b) => b
                ..requiredParameters.add(Parameter((b) => b
                  ..name = "path"
                  ..type = refer('String')))
                ..initializers.add(refer('super').call([
                  refer('routes'),
                ]).code),
            ),
          ))
      ]),
  );
  final emitter = DartEmitter(Allocator.simplePrefixing());
  print(DartFormatter().format('${library.accept(emitter)}'));
}
