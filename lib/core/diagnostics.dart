import 'dart:async';
import 'package:flutter/foundation.dart';

import 'api.dart';

class SfDiagnostics {
  SfDiagnostics._();

  static StockFlowApi? _api;

  static void configure(StockFlowApi api) {
    _api = api;
  }

  static void installGlobalHandlers() {
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutterHandler?.call(details);
      unawaited(capture(
        details.exception,
        stack: details.stack,
        code: 'SF-UI-500',
        context: {'library': details.library ?? 'flutter', 'silent': details.silent},
      ));
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(capture(error, stack: stack, code: 'SF-ASYNC-500'));
      return false;
    };
  }

  static Future<String?> capture(
    Object error, {
    StackTrace? stack,
    String code = 'SF-APP-500',
    Map<String, dynamic> context = const {},
    String severity = 'error',
  }) async {
    try {
      return await _api?.logClientIssue(
        severity: severity,
        code: code,
        message: '$error',
        context: {
          ...context,
          if (kDebugMode && stack != null) 'stack': stack.toString().split('\n').take(8).join('\n'),
        },
      );
    } catch (_) {
      return null;
    }
  }
}
