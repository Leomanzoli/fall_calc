// lib/screens/pagina_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fall_calc_final/screens/fq_zlq/pagina_calculadora_fq_zlq.dart';
import 'package:fall_calc_final/screens/pagina_dados_utilizador.dart';
import 'package:fall_calc_final/screens/pagina_relatorios.dart';
import 'package:fall_calc_final/screens/pagina_opcoes.dart';
import 'package:fall_calc_final/screens/pagina_sobre.dart';
import 'package:fall_calc_final/screens/pagina_videoteca.dart';
import 'package:fall_calc_final/screens/pagina_apoiadores.dart'; // <<< ADICIONADO

class PaginaMenu extends StatelessWidget {
  const PaginaMenu({super.key});

  Future<void> _mostrarDialogoSair(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        // O AlertDialog por padrão já usa as cores do tema,
        // como a cor de superfície (surface) para o fundo e onSurface para o texto.
        return AlertDialog(
          title: const Text('Confirmar Saída'),
          content: const Text(
            'Tem a certeza de que deseja fechar o aplicativo?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              // O TextButton também usa a cor primária (primary) do tema no texto.
              child: const Text('Sair'),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Vamos guardar as referências de cores e estilos para usar mais facilmente
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // O Scaffold já usa a cor 'background' do tema automaticamente.
      appBar: AppBar(
        // Ícone de capacete à esquerda
        leading: const Icon(Icons.engineering), // A cor já vem do appBarTheme
        title: const Text('FallCalc35'),
        centerTitle: true,
        elevation: 4,
        // REMOVIDO: backgroundColor e foregroundColor para usar o appBarTheme
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botão NOVO CÁLCULO (Destaque)
              Container(
                margin: const EdgeInsets.only(bottom: 40.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calculate, size: 28),
                  label: Text(
                    'NOVO CÁLCULO',
                    // ATUALIZADO: Usando um estilo de texto do tema
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          colorScheme.onPrimary, // Garante o contraste correto
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaginaCalculadora(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    // ATUALIZADO: Usando as cores do tema
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 6,
                  ),
                ),
              ),

              // Seção de Navegação Rápida
              _buildMenuItem(
                context,
                icon: Icons.description,
                text: 'MEUS RELATÓRIOS',
                page: const PaginaRelatorios(),
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                context,
                icon: Icons.person,
                text: 'SEUS DADOS',
                page: const PaginaDadosUtilizador(),
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                context,
                icon: Icons.videocam,
                text: 'VIDEOTECA',
                page: const PaginaVideoteca(),
              ),
              const SizedBox(height: 12),

              // --- BOTÃO ADICIONADO ---
              _buildMenuItem(
                context,
                icon: Icons.favorite,
                text: 'APOIADORES',
                page: const PaginaApoiadores(),
              ),
              const SizedBox(height: 12),

              // --- FIM DA ADIÇÃO ---
              _buildMenuItem(
                context,
                icon: Icons.settings,
                text: 'OPÇÕES',
                page: const PaginaOpcoes(),
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                text: 'SOBRE',
                page: const PaginaSobre(),
              ),

              const SizedBox(height: 20),

              // Botão SAIR (Inferior)
              ElevatedButton.icon(
                icon: const Icon(Icons.exit_to_app),
                label: Text(
                  'SAIR',
                  // ATUALIZADO: Usando um estilo de texto do tema
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onError,
                  ),
                ),
                onPressed: () => _mostrarDialogoSair(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  // ATUALIZADO: Usando as cores de "erro" do tema para dar ênfase
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
              const SizedBox(height: 16),
              // Edge-to-edge: espaçamento dinâmico para barras de navegação do sistema
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para construir os itens do menu
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Widget page,
  }) {
    // ATUALIZADO: Buscando as cores e estilos do tema atual
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      // O Card já usa a cor 'surface' do tema, que se adapta ao modo claro/escuro
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Icon(
              icon,
              // ATUALIZADO: Usando a cor primária do tema para os ícones
              color: colorScheme.primary,
              size: 28,
            ),
            title: Text(
              text,
              // ATUALIZADO: Usando um estilo de texto do tema
              style: textTheme.titleMedium?.copyWith(
                // E a cor de texto correta para a superfície do Card
                color: colorScheme.onSurface,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              // ATUALIZADO: Usando uma cor mais sutil do tema
              color: colorScheme.onSurface.withAlpha(153),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ),
    );
  }
}
