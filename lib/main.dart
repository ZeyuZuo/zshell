import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'core/themes/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/pages/main_page.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/ssh_host_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化SQLite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ZShellApp());
}

class ZShellApp extends StatelessWidget {
  const ZShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SSHHostProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const MainPage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}


