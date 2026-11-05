// Summarizes benchmark runs: the `RESULT <case> <value>` lines that
// url_benchmark.dart and the example app's navigation benchmark print.
//
//   dart run test/benchmark/summarize.dart <run files>
//     prints each case's median, lowest and highest value, and its spread:
//     (highest - lowest) / median.
//   dart run test/benchmark/summarize.dart <before files> --vs <after files>
//     prints each case's median before and after, the change, and the larger
//     of the two spreads. A change smaller than that spread is noise.
//
// Plain Dart, so it runs without Flutter.

import 'dart:io';

// A command-line tool kept with the benchmarks, not a test.
void main(List<String> args) {
  final split = args.indexOf('--vs');
  if (split < 0) {
    _printRuns(_read(args));
  } else {
    _printComparison(
      _read(args.sublist(0, split)),
      _read(args.sublist(split + 1)),
    );
  }
}

final _resultLine = RegExp(r'^\s*(?:flutter: )?RESULT (\S+) (\S+)\s*$');

/// Each case's values, one per file, in the order the files print the cases.
Map<String, List<double>> _read(List<String> paths) {
  if (paths.isEmpty) throw ArgumentError('Name at least one run file.');
  final values = <String, List<double>>{};
  for (final path in paths) {
    for (final line in File(path).readAsLinesSync()) {
      final match = _resultLine.firstMatch(line);
      if (match == null) continue;
      values.putIfAbsent(match[1]!, () => []).add(double.parse(match[2]!));
    }
  }
  return values;
}

class _Stats {
  new(List<double> values)
    : median = _median(values),
      lowest = values.reduce((a, b) => a < b ? a : b),
      highest = values.reduce((a, b) => a > b ? a : b),
      count = values.length;

  final double median;
  final double lowest;
  final double highest;
  final int count;

  double get spread => median == 0 ? 0 : (highest - lowest) / median;

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    final centre = sorted
        .skip(sorted.length.isOdd ? middle : middle - 1)
        .take(sorted.length.isOdd ? 1 : 2);
    return centre.fold<double>(0, (sum, value) => sum + value) / centre.length;
  }
}

void _printRuns(Map<String, List<double>> runs) {
  stdout
    ..writeln('| case | median | lowest | highest | spread | runs |')
    ..writeln('|---|---:|---:|---:|---:|---:|');
  for (final MapEntry(:key, :value) in runs.entries) {
    final stats = _Stats(value);
    stdout.writeln(
      '| $key | ${_number(stats.median)} | ${_number(stats.lowest)} | '
      '${_number(stats.highest)} '
      '| ${_percent(stats.spread)} | ${stats.count} |',
    );
  }
}

void _printComparison(
  Map<String, List<double>> before,
  Map<String, List<double>> after,
) {
  stdout
    ..writeln('| case | before | after | change | spread |')
    ..writeln('|---|---:|---:|---:|---:|');
  for (final MapEntry(:key, :value) in before.entries) {
    final afterValues = after[key];
    if (afterValues == null) continue;
    final old = _Stats(value);
    final now = _Stats(afterValues);
    final change = old.median == 0
        ? 0.0
        : (now.median - old.median) / old.median;
    final spread = old.spread > now.spread ? old.spread : now.spread;
    stdout.writeln(
      '| $key | ${_number(old.median)} | ${_number(now.median)} | '
      '${change >= 0 ? '+' : ''}${_percent(change)} '
      '| ${_percent(spread)} |',
    );
  }
}

String _number(double value) =>
    value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';
