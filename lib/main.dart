import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'data/services/token_store.dart';
import 'providers/providers.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Firebase has to be ready before any phone-auth call.
  await Firebase.initializeApp();

  // Read the saved JWTs once so the first screen already knows if we are
  // logged in — no flash of the login screen on a warm start.
  final tokenStore = TokenStore();
  await tokenStore.load();

  runApp(
    ProviderScope(
      overrides: [tokenStoreProvider.overrideWithValue(tokenStore)],
      child: const PfcApp(),
    ),
  );
}

class PfcApp extends StatelessWidget {
  const PfcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Palnadu Fried Chicken',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
      builder: (context, child) {
        // Lock text scaling so the layout never breaks on huge font settings.
        final scale = MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.2,
            );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: child!,
        );
      },
    );
  }
}
