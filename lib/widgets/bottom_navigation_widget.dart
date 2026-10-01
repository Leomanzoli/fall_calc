// lib/widgets/bottom_navigation_widget.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fall_calc_final/screens/pagina_principal.dart';
import 'package:fall_calc_final/screens/pagina_relatorios.dart';
import 'package:fall_calc_final/screens/pagina_dados_utilizador.dart';
import 'package:fall_calc_final/screens/pagina_opcoes.dart';
import 'package:fall_calc_final/screens/pagina_sobre.dart';
import 'package:fall_calc_final/screens/pagina_videoteca.dart';
import 'package:fall_calc_final/screens/pagina_apoiadores.dart';

class BottomNavigationWidget extends StatelessWidget {
  /// Índice semântico: 0 Início, 1 Relatórios, 2 Vídeos, 3 Menu.
  final int currentIndex;

  const BottomNavigationWidget({super.key, required this.currentIndex});

  // Na web não há histórico de relatórios, então a aba é omitida.
  static const List<int> _abas = kIsWeb ? [0, 2, 3] : [0, 1, 2, 3];

  @override
  Widget build(BuildContext context) {
    final posicaoAtual = _abas.indexOf(currentIndex);
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.6),
        currentIndex: posicaoAtual < 0 ? 0 : posicaoAtual,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        onTap: (posicao) => _onItemTapped(context, _abas[posicao]),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            activeIcon: Icon(Icons.calculate, size: 28),
            label: 'Início',
          ),
          if (!kIsWeb)
            const BottomNavigationBarItem(
              icon: Icon(Icons.description),
              activeIcon: Icon(Icons.description, size: 28),
              label: 'Relatórios',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            activeIcon: Icon(Icons.play_circle, size: 28),
            label: 'Videos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            activeIcon: Icon(Icons.menu_open, size: 28),
            label: 'Menu',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Calculadoras - navegar para página principal se não estivermos lá
        if (currentIndex != 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const PaginaPrincipal()),
            (route) => false,
          );
        }
        break;
      case 1:
        // Relatórios
        if (currentIndex != 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PaginaRelatorios()),
          );
        }
        break;
      case 2:
        // Videos - navegar para página de videoteca
        if (currentIndex != 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PaginaVideoteca()),
          );
        }
        break;
      case 3:
        // Menu - mostrar opções
        _mostrarMenuOpcoes(context);
        break;
    }
  }

  void _mostrarMenuOpcoes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Menu de Opções',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _buildMenuTile(
                context,
                icon: Icons.person,
                title: 'Seus Dados',
                subtitle: 'Gerencie suas informações pessoais',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaginaDadosUtilizador(),
                    ),
                  );
                },
              ),
              _buildMenuTile(
                context,
                icon: Icons.settings,
                title: 'Opções',
                subtitle: 'Configurações do aplicativo',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaginaOpcoes(),
                    ),
                  );
                },
              ),
              _buildMenuTile(
                context,
                icon: Icons.info_outline,
                title: 'Sobre',
                subtitle: 'Informações sobre o aplicativo',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaginaSobre(),
                    ),
                  );
                },
              ),
              _buildMenuTile(
                context,
                icon: Icons.favorite,
                title: 'Apoiadores',
                subtitle: 'Empresas que apoiam o projeto',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaginaApoiadores(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
