// lib/main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:fall_calc_final/screens/pagina_principal.dart';
import 'package:fall_calc_final/providers/app_settings_provider.dart';
import 'package:fall_calc_final/theme/app_themes.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // Edge-to-edge: permite que o conteúdo se estenda atrás das barras do sistema
  // Compatível com Android 15 (SDK 35) e versões anteriores
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Apenas brilho dos ícones - as cores são geridas pelo enableEdgeToEdge() nativo
  // para evitar APIs descontinuadas (setStatusBarColor, setNavigationBarColor)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppSettingsProvider(),
      child: const CalculadoraApp(),
    ),
  );
}

class CalculadoraApp extends StatelessWidget {
  const CalculadoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settingsProvider, child) {
        // --- CORREÇÃO DA LÓGICA DO TEMA ---

        // 1. Criamos um tema claro com a configuração de som
        final lightThemeWithSound = AppThemes.lightTheme.copyWith(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(enableFeedback: settingsProvider.soundEnabled),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: ButtonStyle(enableFeedback: settingsProvider.soundEnabled),
          ),
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(enableFeedback: settingsProvider.soundEnabled),
          ),
        );

        // 2. Criamos um tema escuro com a configuração de som
        final darkThemeWithSound = AppThemes.darkTheme.copyWith(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(enableFeedback: settingsProvider.soundEnabled),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: ButtonStyle(enableFeedback: settingsProvider.soundEnabled),
          ),
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(enableFeedback: settingsProvider.soundEnabled),
          ),
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FallCalc35 - Fator de Queda e ZLQ',

          // 3. Atribuímos cada tema à sua propriedade correta
          theme: lightThemeWithSound,
          darkTheme: darkThemeWithSound,
          themeMode: settingsProvider.themeMode,

          builder: (context, child) {
            Widget conteudo = MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(settingsProvider.textScale),
              ),
              child: child!,
            );
            if (kIsWeb) {
              // Em telas largas, mantém o layout "mobile" centralizado.
              conteudo = ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: conteudo,
                  ),
                ),
              );
            }
            return conteudo;
          },

          home: const PaginaPrincipal(),
        );
      },
    );
  }
}
