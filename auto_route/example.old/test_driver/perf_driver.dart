import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';

// Host side of integration_test/navigation_benchmark.dart. Summarizes each
// case's timeline into build/navigation_benchmark.json and prints one
// `RESULT <case>.<measure> <value>` line per number, the lines
// auto_route/test/benchmark/summarize.dart reads.
// The host side of `flutter drive`, not a test.
// ignore: prefer-correct-test-file-name
Future<void> main() => integrationDriver(responseDataCallback: _summarize);

Future<void> _summarize(Map<String, dynamic>? data) async {
  if (data == null) throw StateError('The benchmark reported nothing.');
  final syncMicros =
      (data.remove('sync_micros') as Map<String, dynamic>?) ?? const {};
  final summary = <String, Map<String, num>>{};
  for (final MapEntry(:key, :value) in data.entries) {
    final timeline = TimelineSummary.summarize(
      Timeline.fromJson(value as Map<String, dynamic>),
    ).summaryJson;
    final buildTimes = (timeline['frame_build_times'] as List<dynamic>)
        .cast<int>();
    final rasterTimes = (timeline['frame_rasterizer_times'] as List<dynamic>)
        .cast<int>();
    summary[key] = {
      'frames': timeline['frame_count'] as int,
      'build_total_ms': _sum(buildTimes) / 1000,
      'build_avg_ms': timeline['average_frame_build_time_millis'] as num,
      'build_p90_ms':
          timeline['90th_percentile_frame_build_time_millis'] as num,
      'build_worst_ms': timeline['worst_frame_build_time_millis'] as num,
      'raster_total_ms': _sum(rasterTimes) / 1000,
      'raster_avg_ms': timeline['average_frame_rasterizer_time_millis'] as num,
      'raster_p90_ms':
          timeline['90th_percentile_frame_rasterizer_time_millis'] as num,
      'call_median_us': syncMicros[key] as num? ?? double.nan,
    };
  }
  final file = File('build/navigation_benchmark.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(summary));
  for (final MapEntry(key: name, value: measures) in summary.entries) {
    for (final MapEntry(:key, :value) in measures.entries) {
      stdout.writeln('RESULT $name.$key $value');
    }
  }
}

int _sum(List<int> values) => values.fold(0, (total, value) => total + value);
