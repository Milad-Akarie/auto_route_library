import 'dart:io';
import 'package:args/args.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:xml/xml.dart';

void main(List<String> args) async {
  // final file = File('ios/runner/infox.plist');
  // final document = XmlDocument.parse(file.readAsStringSync());
  // final dict = document.findElements('plist').first.findElements('dict').first;
  // final linkKeys = dict.findElements('key').where((e) => e.text == 'com.apple.developer.associated-domains');
  // final builder = XmlBuilder();
  //
  // if (linkKeys.isEmpty) {
  //   builder.element('key', nest: 'com.apple.developer.associated-domains');
  //   builder.element('array', nest: () {
  //     builder.element('string', nest: 'applinks:www.google.com');
  //   });
  //   dict.children.add(builder.buildFragment());
  // }else{
  //   final array = linkKeys.first.following.first;
  //
  // }
  //
  // final outputFile = File('ios/runner/infox.plist');
  // outputFile.writeAsStringSync(document.toString());
  // print(document);

  final parser = _setupArgParser();
  final result = parser.parse(args);
  if (result.wasParsed('help')) {
    print(parser.usage);
  } else {
    if ((result['platform'] as List).contains('android')) {
      _handleAndroidConfig(result);
    }
  }
}



void _handleAndroidConfig(ArgResults args) {
  final enableMode = args.wasParsed('enable');
  final disableMode = args.wasParsed('disable');
  final host = args['enable'] ?? args['disable'];
  assert(host != null, 'Host is not specified');

  if (!disableMode && !enableMode) {
    throw Exception('Invalid Action, valid action example: --enable www.example.com');
  }

  final manifestPath = args['manifest-path'] ?? 'android/app/src/main/AndroidManifest.xml';
  final file = File(manifestPath);
  if(!file.existsSync()){
    throw Exception('Could not find AndroidManifest.xml file at $manifestPath');
  }

  final document = XmlDocument.parse(file.readAsStringSync());
  final application = document.rootElement.findElements('application').first;
  final activities = application.findElements('activity');
  final launchActivity = activities.firstWhere((a) => a.childElements.any(_isLaunchIntentFilter));
  final intentFilters = launchActivity.findElements('intent-filter');
  final deepLinkIntentFilters = _getDeeplinkIntents(intentFilters);

  final builder = XmlBuilder();
  final deepLinkMetaData = launchActivity.findElements('meta-data').firstOrNull(
        (e) => e.attributes.any((p0) {
          return p0.value == 'flutter_deeplinking_enabled';
        }),
      );

  if (enableMode && deepLinkMetaData == null) {
    builder.element(
      'meta-data',
      attributes: {
        'android:name': 'flutter_deeplinking_enabled',
        'android:value': 'true',
      },
    );
  }

  if (disableMode) {
    for (final intent in List.of(deepLinkIntentFilters)) {
      final intentHost = _getIntentHost(intent);
      if (host == 'all' || intentHost == host) {
        launchActivity.children.remove(intent);
        print('Host $intentHost was removed from enabled hosts');
      }
    }

    // if there are no deeplink intent filters left
    // remove the deeplink meta data tag
    if (_getDeeplinkIntents(intentFilters).isEmpty) {
      launchActivity.children.remove(deepLinkMetaData);
    }
  } else {
    for (final intent in deepLinkIntentFilters) {
      if (_getIntentHost(intent) == host) {
        print('Host $host is already enabled');
        return;
      }
    }

    builder.element('intent-filter', attributes: {'android:autoVerify': 'true'}, nest: () {
      builder.element('action', nest: () {
        builder.attribute('android:name', 'android.intent.action.VIEW');
      });
      builder.element('category', nest: () {
        builder.attribute('android:name', 'android.intent.category.DEFAULT');
      });
      builder.element('category', nest: () {
        builder.attribute('android:name', 'android.intent.category.BROWSABLE');
      });
      builder.element('data', nest: () {
        builder.attribute('android:scheme', 'http');
        builder.attribute('android:host', host);
      });
      builder.element('data', nest: () {
        builder.attribute('android:scheme', 'https');
      });
    });
  }
  launchActivity.children.add(builder.buildFragment());
  file.writeAsStringSync(document.toXmlString(
    pretty: true,
    indent: '    ',
    indentAttribute: (attr) => !['android:name', 'android:scheme', 'android:host', 'xmlns:android'].contains(
      attr.name.toString(),
    ),
  ));

  // Process.runSync(executable, [])
}

String _getIntentHost(XmlElement intent) {
  return intent
      .findElements('data')
      .map(
        (data) => data.attributes.firstWhere((p0) {
          return p0.name.toString() == 'android:host';
        }).value,
      )
      .first;
}

Iterable<XmlElement> _getDeeplinkIntents(Iterable<XmlElement> intentFilters) {
  return intentFilters.where(
    (i) => i.findElements('data').any(
          (data) => data.attributes.any((p0) {
            return p0.name.toString() == 'android:host';
          }),
        ),
  );
}

bool _isLaunchIntentFilter(XmlElement element) {
  if (element.name.toString() != 'intent-filter') return false;
  return element.childElements.any(
    (e) => e.attributes.any(
      (attr) => attr.value == 'android.intent.category.LAUNCHER',
    ),
  );
}
ArgParser _setupArgParser() {
  return ArgParser()
    ..addOption('enable', abbr: 'e', help: 'Enable specified host', valueHelp: 'www.example.com')
    ..addOption(
      'disable',
      abbr: 'd',
      help: 'Disable host if specified or disable all if "all" is passed',
      valueHelp: 'www.example.com | all',
      defaultsTo: 'all',
    )
    ..addMultiOption(
      'platform',
      abbr: 'p',
      help: 'Specify a platform to configure',
      valueHelp: 'android, ios',
      allowed: ['android', 'ios'],
      defaultsTo: ['android', 'ios'],
    )
    ..addOption('manifest-path', abbr: 'm', help: 'Specifies AndroidManifest.xml file path')
    ..addFlag('help', abbr: 'h', negatable: false);
}