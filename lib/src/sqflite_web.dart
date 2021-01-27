import 'dart:async';
import 'dart:html' as html;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:sqflite_common/sqlite_api.dart';

import 'database_factory.dart';

/// The database factory to use for Web.
///
/// Check support documentation.
DatabaseFactory get databaseFactoryWeb => databaseFactoryWebImpl;

/// The Web plugin registration.
class SqflitePluginWeb extends PlatformInterface {
  static final _readyCompleter = Completer<bool>();

  /// Shows if the Sql.js library has been loaded
  static Future<bool> isReady;

  /// Registers the Web database factory.
  static void registerWith(Registrar registrar) {
    isReady = _readyCompleter.future;
    html.window.addEventListener(
        'sqflite_web_ready', (_) => _readyCompleter.complete(true));

    final body = html.window.document.querySelector('body');

    // Add 'sqflite_web.js' (and 'require.js') dynamically if not already imported
    // (this is needed to prevent hot reload or refresh to import it again and again)
    var foundRequireJs = false;
    var foundSqfliteWebJs = false;
    for (html.ScriptElement script in body.querySelectorAll('script')) {
      if (script.src
          .contains('assets/packages/sqflite_web/assets/require.js')) {
        foundRequireJs = true;
      }
      if (script.src
          .contains('assets/packages/sqflite_web/assets/sqflite_web.js')) {
        foundSqfliteWebJs = true;
      }
    }

    if (!foundRequireJs) {
      print(
          "<!> WARNING: Importing 'require.js' from sqlite_web, considere importing it directlty from your html file like this: '<script src=\"assets/packages/sqflite_web/assets/require.js\" type=\"application/javascript\"></script>'");
      body.append(html.ScriptElement()
        ..src = 'assets/packages/sqflite_web/assets/require.js'
        ..type = 'application/javascript');
    }
    if (!foundSqfliteWebJs) {
      body.append(html.ScriptElement()
        ..src = 'assets/packages/sqflite_web/assets/sqflite_web.js'
        ..type = 'application/javascript');
    }
  }
}
