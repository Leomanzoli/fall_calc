// lib/screens/pagina_sobre.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fall_calc_final/widgets/bottom_navigation_widget.dart';
import 'package:fall_calc_final/widgets/convite_teste_android_widget.dart';

class PaginaSobre extends StatelessWidget {
  const PaginaSobre({super.key});

  static const _linkedinBlue = Color(0xFF0A66C2);

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $url')),
        );
      }
    }
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return '';
    final primeira = partes.first.isNotEmpty ? partes.first[0] : '';
    final ultima = partes.length > 1 && partes.last.isNotEmpty
        ? partes.last[0]
        : '';
    return (primeira + ultima).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    const urlJuliana =
        'https://www.linkedin.com/in/juliana-bello-ju-8a810b116/';
    const imgJuliana = 'assets/imagens/juliana.jpg';

    const urlLeo = 'https://www.linkedin.com/in/leostoco/';
    const imgLeo = 'assets/imagens/leonardo.jpg';

    const contactEmail = 'fallcalc35@gmail.com';

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o Aplicativo'), elevation: 4),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionCard(
                context: context,
                icon: Icons.info_outline,
                title: 'Sobre o FallCalc35',
                children: [
                  Text(
                    'Este aplicativo foi desenvolvido como uma ferramenta de apoio para estudantes, profissionais de Segurança do Trabalho e trabalhadores envolvidos em atividades em altura, assim como para aqueles interessados em aprimorar seus conhecimentos sobre o tema.',
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'O principal objetivo é tornar a tecnologia acessível, contribuindo efetivamente para a prevenção de acidentes relacionados ao trabalho em altura, especialmente aqueles com potencial de fatalidade.',
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Os cálculos realizados são baseados na norma regulamentadora NR-35 e seguem as diretrizes da ABNT NBR e PRO-040866-Procedimento Integrado da VP Operações para Trabalho em Altura - RAC01 (Vale). Ressaltamos que o aplicativo é uma ferramenta de apoio e não substitui a necessidade de um profissional qualificado.',
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A aplicação foi desenvolvida utilizando softwares gratuitos, como VS Code, Flutter e Dart.',
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                context: context,
                icon: Icons.people_outline,
                title: 'Desenvolvido por',
                children: [
                  _perfilItem(
                    context: context,
                    nome: 'Leonardo Manzoli Stoco',
                    cargo: 'Engenheiro de Segurança do Trabalho',
                    fotoUrl: imgLeo,
                    linkedinUrl: urlLeo,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                context: context,
                icon: Icons.handshake_outlined,
                title: 'Idealização e colaboração',
                children: [
                  _perfilItem(
                    context: context,
                    nome: 'Juliana Bello',
                    cargo: 'Técnica em Segurança do Trabalho',
                    fotoUrl: imgJuliana,
                    linkedinUrl: urlJuliana,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (kIsWeb) ...[
                _buildSectionCard(
                  context: context,
                  icon: Icons.phone_android,
                  title: 'Teste a versão Android',
                  children: const [ConviteTesteAndroidWidget(compacto: true)],
                ),
                const SizedBox(height: 16),
              ],
              _buildSectionCard(
                context: context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacidade e LGPD',
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: colorScheme.secondary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Este aplicativo não coleta, não armazena em servidores e não compartilha dados pessoais com terceiros.',
                          style: textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Todas as informações inseridas (dados do usuário, relatórios, checklists, fotos e assinaturas) ficam armazenadas exclusivamente no seu dispositivo e são utilizadas apenas para gerar os relatórios em PDF. O compartilhamento ocorre somente quando você decide exportar ou enviar um relatório.',
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dessa forma, o FallCalc35 respeita os princípios da Lei Geral de Proteção de Dados Pessoais (LGPD - Lei nº 13.709/2018). Ao desinstalar o aplicativo, todos os dados são removidos do dispositivo.',
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                context: context,
                icon: Icons.segment,
                title: 'Informações Adicionais',
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: const Text('Versão'),
                    subtitle: const Text('1.0.2'),
                    dense: true,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.email_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: const Text('Contato'),
                    subtitle: Text(
                      contactEmail,
                      style: TextStyle(
                        color: colorScheme.secondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    // ATUALIZADO: Passando o 'context' para a função
                    onTap: () => _launchURL(context, 'mailto:$contactEmail'),
                    dense: true,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: const Text('Local'),
                    subtitle: const Text('Espírito Santo, Brasil - 2025'),
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 3),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _perfilItem({
    required BuildContext context,
    required String nome,
    required String cargo,
    required String fotoUrl,
    required String linkedinUrl,
  }) {
    final iniciais = _iniciais(nome);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withAlpha(128)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _avatarRedondo(context, fotoUrl: fotoUrl, iniciais: iniciais),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(cargo, style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ATUALIZADO: Passando o 'context' para a função
                _botaoLinkedIn(() => _launchURL(context, linkedinUrl)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarRedondo(
    BuildContext context, {
    required String fotoUrl,
    required String iniciais,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipOval(
      child: SizedBox(
        width: 56,
        height: 56,
        child: Image.asset(
          fotoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) {
            return Container(
              color: colorScheme.secondaryContainer,
              alignment: Alignment.center,
              child: Text(
                iniciais,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _botaoLinkedIn(VoidCallback onTap) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const FaIcon(FontAwesomeIcons.linkedin, size: 18),
        label: const Text('LinkedIn'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _linkedinBlue,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          elevation: 2,
        ),
      ),
    );
  }
}
