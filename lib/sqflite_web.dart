import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_web/src/database_factory.dart';

/// The database factory to use for Web.
///
/// Check support documentation.
DatabaseFactory get databaseFactoryWeb => databaseFactoryWebImpl;

/// The Web plugin registration.
///
/// Define a default `DatabaseFactory`
class SqflitePluginWeb extends PlatformInterface {
  static final _readyCompleter = Completer<bool>();
  /// Shows if the Sql.js library has been loaded
  static Future<bool> isReady;

  /// Registers the default database factory.
  static void registerWith(Registrar registrar) {
    isReady = _readyCompleter.future;
    html.window.addEventListener('sqflite_web_ready', (_) => _readyCompleter.complete(true));

    final body = html.window.document.querySelector('body');
    // Hot reload would add it again
    // ignore: omit_local_variable_types
    for (html.ScriptElement script in body.querySelectorAll('script')) {
      if (script.src.contains('sqflite_web')) {
        script.remove();
      }
    }

    if (kReleaseMode) {
      // https://github.com/flutter/flutter/issues/56659
      body.append(html.ScriptElement()
        ..src = 'assets/packages/sqflite_web/assets/require.js'
        ..type = 'application/javascript');
    }
    body.append(html.ScriptElement()
      ..src = 'assets/packages/sqflite_web/assets/sqflite_web.js'
      ..type = 'application/javascript');
  }
}
