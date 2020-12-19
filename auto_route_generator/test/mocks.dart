import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route_generator/auto_route_generator.dart';
import 'package:build/build.dart';

const pkg = '_test_';

class AutoRouteGeneratorMock extends AutoRouteGenerator {
  @override
  Resolver getResolver(_) => ResolverMock();
}

class ResolverMock implements Resolver {
  @override
  Future<AssetId> assetIdForElement(Element element) async {
    if (element.source != null) {
      return AssetId(pkg, element.source.uri.pathSegments.last);
    } else {
      return null;
    }
  }

  @override
  Future<LibraryElement> findLibraryByName(String libraryName) {
    return null;
  }

  Future<bool> isLibrary(AssetId assetId) async {
    return false;
  }

  @override
  Stream<LibraryElement> get libraries => null;

  @override
  Future<LibraryElement> libraryFor(AssetId assetId, {bool allowSyntaxErrors = false}) {
    throw UnimplementedError();
  }

  @override
  Future<CompilationUnit> compilationUnitFor(AssetId assetId, {bool allowSyntaxErrors = false}) {
    // TODO: implement compilationUnitFor
    throw UnimplementedError();
  }

  @override
  Future<AstNode> astNodeFor(Element element, {bool resolve = false}) {
    // TODO: implement astNodeFor
    throw UnimplementedError();
  }
}
