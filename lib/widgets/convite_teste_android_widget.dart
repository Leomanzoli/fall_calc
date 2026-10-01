// lib/widgets/convite_teste_android_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Convite para participar dos testes da versão completa Android.
/// Exibido apenas na versão web.
class ConviteTesteAndroidWidget extends StatelessWidget {
  const ConviteTesteAndroidWidget({super.key, this.compacto = false});

  /// Variante com menos destaque, para uso dentro de outras seções (ex.: Sobre).
  final bool compacto;

  static const email = 'leo.manzoli@hotmail.com';
  static const telefoneExibicao = '(27) 98133-7562';
  static const _telefoneInternacional = '5527981337562';
  static const _mensagem =
      'Olá, Leonardo! Tenho interesse em participar dos testes da versão '
      'completa do FallCalc35 para Android.';

  static final Uri _uriWhatsApp = Uri.parse(
    'https://wa.me/$_telefoneInternacional?text=${Uri.encodeComponent(_mensagem)}',
  );
  static final Uri _uriEmail = Uri(
    scheme: 'mailto',
    path: email,
    query: Uri(
      queryParameters: {
        'subject': 'FallCalc35 - Interesse em testar a versão Android',
        'body': _mensagem,
      },
    ).query,
  );

  Future<void> _abrir(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }

  Future<void> _copiar(
    BuildContext context,
    String texto,
    String rotulo,
  ) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$rotulo copiado!')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.phone_android,
                color: colorScheme.primary,
                size: compacto ? 22 : 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Quer testar a versão completa para Android?',
                style: (compacto ? textTheme.titleMedium : textTheme.titleLarge)
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'O aplicativo Android inclui histórico de relatórios e checklists, '
          'edição, duplicação, compartilhamento de PDFs, foto de perfil e '
          'muito mais. Estamos recrutando testadores: entre em contato e '
          'receba o convite para participar.',
          style: textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () => _abrir(context, _uriWhatsApp),
              icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
              label: const Text('WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _abrir(context, _uriEmail),
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text('E-mail'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ContatoLinha(
          icon: Icons.email_outlined,
          texto: email,
          onTap: () => _copiar(context, email, 'E-mail'),
        ),
        _ContatoLinha(
          icon: Icons.phone_outlined,
          texto: telefoneExibicao,
          onTap: () => _copiar(context, telefoneExibicao, 'Telefone'),
        ),
      ],
    );

    if (compacto) return conteudo;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.6),
            colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: conteudo,
    );
  }
}

class _ContatoLinha extends StatelessWidget {
  const _ContatoLinha({
    required this.icon,
    required this.texto,
    required this.onTap,
  });

  final IconData icon;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                texto,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Tooltip(
              message: 'Copiar',
              child: Icon(
                Icons.copy_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
