// lib/screens/pagina_opcoes.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fall_calc_final/providers/app_settings_provider.dart';
import 'package:fall_calc_final/widgets/bottom_navigation_widget.dart';

class PaginaOpcoes extends StatelessWidget {
  const PaginaOpcoes({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos o Consumer para aceder ao provider e reconstruir a tela quando há mudanças
    return Consumer<AppSettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Scaffold(
          // --- A MUDANÇA ESTÁ AQUI ---
          appBar: AppBar(
            title: const Text('Opções'),
            // REMOVIDO: As propriedades 'backgroundColor' e 'foregroundColor'.
            // Agora, a AppBar usa automaticamente o estilo definido no AppThemes.
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Controle de Modo Escuro
              Card(
                child: SwitchListTile(
                  title: const Text('Modo Escuro'),
                  subtitle: const Text('Alterna entre tema claro e escuro'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: settingsProvider.themeMode == ThemeMode.dark,
                  onChanged: (bool valor) {
                    settingsProvider.toggleTheme(valor);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Controle de Tamanho de Texto
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.text_fields),
                          const SizedBox(width: 16),
                          Text(
                            'Tamanho do Texto',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajuste o tamanho da fonte para melhor legibilidade',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Slider de tamanho de texto
                      Row(
                        children: [
                          const Icon(Icons.text_decrease, size: 20),
                          Expanded(
                            child: Slider(
                              value: settingsProvider.textScale,
                              min: 0.8,
                              max: 1.5,
                              divisions: 7,
                              label:
                                  '${(settingsProvider.textScale * 100).round()}%',
                              onChanged: (double valor) {
                                settingsProvider.setTextScale(valor);
                              },
                            ),
                          ),
                          const Icon(Icons.text_increase, size: 20),
                        ],
                      ),

                      // Botões de tamanho predefinido
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTextSizeButton(
                            context,
                            'Pequeno',
                            0.85,
                            settingsProvider,
                          ),
                          _buildTextSizeButton(
                            context,
                            'Normal',
                            1.0,
                            settingsProvider,
                          ),
                          _buildTextSizeButton(
                            context,
                            'Grande',
                            1.2,
                            settingsProvider,
                          ),
                          _buildTextSizeButton(
                            context,
                            'Muito Grande',
                            1.4,
                            settingsProvider,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Exemplo de texto
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.preview),
                          const SizedBox(width: 16),
                          Text(
                            'Pré-visualização',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Este é um exemplo de como o texto aparecerá no aplicativo com o tamanho selecionado.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fator de Queda: 2.5',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: const BottomNavigationWidget(currentIndex: 3),
        );
      },
    );
  }

  Widget _buildTextSizeButton(
    BuildContext context,
    String label,
    double scale,
    AppSettingsProvider provider,
  ) {
    final isSelected = (provider.textScale - scale).abs() < 0.05;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          onPressed: () => provider.setTextScale(scale),
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected
                ? Theme.of(context).colorScheme.primary
                : null,
            foregroundColor: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 8),
            textStyle: const TextStyle(fontSize: 11),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
