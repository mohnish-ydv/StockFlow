import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api.dart';
import 'core/diagnostics.dart';
import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'screens/not_found_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/sf_ui.dart';

class StockFlowApp extends StatefulWidget {
  const StockFlowApp({super.key});

  @override
  State<StockFlowApp> createState() => _StockFlowAppState();
}

class _StockFlowAppState extends State<StockFlowApp> {
  final api = StockFlowApi();
  final navigatorKey = GlobalKey<NavigatorState>();

  bool loading = true;
  bool welcomeSeen = false;

  @override
  void initState() {
    super.initState();
    SfDiagnostics.configure(api);
    _boot();
  }

  Future<void> _boot() async {
    final prefs = await SharedPreferences.getInstance();
    await api.init();
    if (!mounted) return;
    setState(() {
      welcomeSeen = prefs.getBool('sf_welcome_v3_seen') ?? false;
      loading = false;
    });
  }

  Future<void> _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sf_welcome_v3_seen', true);
    if (mounted) setState(() => welcomeSeen = true);
  }

  Future<void> _openWelcomeAuth(AuthMode mode) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    await navigator.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AuthScreen(
          api: api,
          initialMode: mode,
          onDone: () async {
            await _completeWelcome();
            navigatorKey.currentState?.pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: navigatorKey,
        title: 'StockFlow',
        debugShowCheckedModeBanner: false,
        theme: StockFlowTheme.light(),
        themeMode: ThemeMode.light,
        onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const NotFoundScreen()),
        home: loading
            ? const _Splash()
            : welcomeSeen
                ? HomeShell(
                    api: api,
                    onSessionChanged: () => setState(() {}),
                  )
                : WelcomeScreen(
                    api: api,
                    onExplore: _completeWelcome,
                    onCreateAccount: () => _openWelcomeAuth(AuthMode.register),
                    onSignIn: () => _openWelcomeAuth(AuthMode.signIn),
                  ),
      );
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: StockFlowTheme.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SfBrandMark(size: 62),
              SizedBox(height: 18),
              Text(
                'StockFlow',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.65,
                ),
              ),
              SizedBox(height: 22),
              SizedBox(
                width: 24,
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ],
          ),
        ),
      );
}
