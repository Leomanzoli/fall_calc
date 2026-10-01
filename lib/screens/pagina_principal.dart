// lib/screens/pagina_principal.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fall_calc_final/screens/fq_zlq/pagina_calculadora_fq_zlq.dart';
import 'package:fall_calc_final/screens/checklist/pagina_checklist_pre_uso.dart';
import 'package:fall_calc_final/screens/checklist/pagina_inspecao_inicial_periodica.dart';
import 'package:fall_calc_final/widgets/bottom_navigation_widget.dart';
import 'package:fall_calc_final/widgets/convite_teste_android_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({super.key});

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  static bool _startupProfileCheckRanThisLaunch = false;

  @override
  void initState() {
    super.initState();

    if (_startupProfileCheckRanThisLaunch) return;
    _startupProfileCheckRanThisLaunch = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarDadosUsuarioNoStartup();
    });
  }

  Future<void> _verificarDadosUsuarioNoStartup() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    bool isBlank(String? value) => (value ?? '').trim().isEmpty;

    final nome = prefs.getString('nome');
    final matricula = prefs.getString('matricula');
    final empresa = prefs.getString('empresa');
    final email = prefs.getString('email');
    final estado = prefs.getString('estado');
    final municipio = prefs.getString('municipio');

    final faltandoDados = kIsWeb
        ? (isBlank(nome) || isBlank(matricula) || isBlank(email))
        : (isBlank(nome) ||
              isBlank(matricula) ||
              isBlank(empresa) ||
              isBlank(email) ||
              isBlank(estado) ||
              isBlank(municipio));

    if (!faltandoDados) return;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Atenção'),
          content: const Text(
            'Seus dados ainda não foram preenchidos. Caso você gere relatórios, esses campos ficarão em branco nos relatórios.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.surface,
              Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar customizada
              _buildCustomAppBar(context),

              // Conteúdo principal
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Logo com animação
                        _buildAnimatedLogo(),

                        const SizedBox(height: 30),

                        // Título de boas-vindas
                        _buildWelcomeSection(context),

                        const SizedBox(height: 40),

                        // Grid de botões principais
                        _buildMainButtonsGrid(context),

                        if (kIsWeb) ...[
                          const SizedBox(height: 30),
                          const ConviteTesteAndroidWidget(),
                        ],

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 0),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.engineering,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FallCalc35',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              height: 140,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/icones/FallCalc.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Bem-vindo ao FallCalc35',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMainButtonsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAnimatedButton(
          context,
          icon: Icons.calculate,
          title: 'Fator de Queda',
          subtitle: 'e ZLQ',
          gradient: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaginaCalculadora(),
              ),
            );
          },
          delay: 0,
        ),
        const SizedBox(height: 16),
        _buildAnimatedButton(
          context,
          icon: Icons.checklist,
          title: 'Checklist de Pré-Uso',
          subtitle: '(Inspeção Diária)',
          gradient: [
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
          ],
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaginaChecklistPreUso(),
              ),
            );
          },
          delay: 120,
        ),
        const SizedBox(height: 16),
        _buildAnimatedButton(
          context,
          icon: Icons.fact_check,
          title: 'Inspeção Inicial',
          subtitle: 'e Periódica',
          gradient: [
            Theme.of(context).colorScheme.tertiary,
            Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.7),
          ],
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaginaInspecaoInicialPeriodica(),
              ),
            );
          },
          delay: 240,
        ),
      ],
    );
  }

  Widget _buildAnimatedButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onPressed,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onPressed,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(icon, size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
