import 'package:flutter/material.dart';

import 'app.dart';
import 'core/diagnostics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SfDiagnostics.installGlobalHandlers();
  runApp(const StockFlowApp());
}
