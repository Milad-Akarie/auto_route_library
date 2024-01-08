import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';

extension DirectiveX on Directive {
  bool get isExport => this is ExportDirective;
  bool get isImport => this is ImportDirective;

  List<Combinator> get combinators => (this as NamespaceDirective).combinators;

  Iterable<String> get show => {
        ...?combinators.whereType<ShowCombinator>().firstOrNull?.shownNames.map(
              (e) => e.name,
            )
      };

  Iterable<String> get hide => {
        ...?combinators.whereType<HideCombinator>().firstOrNull?.hiddenNames.map(
              (e) => e.name,
            )
      };

  String get path => childEntities.firstTypeOrNull<SimpleStringLiteral>()?.value ?? '';

  bool get isPackage => path.startsWith('package:');
  bool get isDart => path.startsWith('dart:');
}

extension IterableX<E> on Iterable<E> {
  E? firstTypeOrNull<E>() => this.firstWhereOrNull((e) => e is E) as E?;
}

extension CompilationUnitX on CompilationUnit{
  Iterable<String> get exportedNames => declarations.whereType<NamedCompilationUnitMember>().map((e) => e.name.lexeme);
}