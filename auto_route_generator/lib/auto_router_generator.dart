import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/resolvers/router_config_resolver.dart';
import 'utils.dart';
import 'package:auto_route/annotations.dart';

class AutoRouterGenerator extends GeneratorForAnnotation<AutoRouterAnnotation> {
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
    return jsonEncode(router.toJson());
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
}
