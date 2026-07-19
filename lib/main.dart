import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TnebBillSplitterApp());
}

/// Root widget: sets up the [AppState] provider (loaded from shared
/// preferences on start) and the Material 3 light/dark theme.
class TnebBillSplitterApp extends StatefulWidget {
  const TnebBillSplitterApp({super.key});

  @override
  State<TnebBillSplitterApp> createState() => _TnebBillSplitterAppState();
}

class _TnebBillSplitterAppState extends State<TnebBillSplitterApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: _appState,
      child: Consumer<AppState>(
        builder: (context, state, _) {
          if (!state.isLoaded) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          return MaterialApp(
            title: 'TNEB Bill Splitter',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
