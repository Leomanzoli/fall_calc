import 'dart:io';
import 'dart:typed_data';

import 'package:fall_calc_final/models/checklist/checklist_inspecao_inicial_periodica.dart';
import 'package:fall_calc_final/models/checklist/checklist_pre_uso.dart';
import 'package:fall_calc_final/screens/checklist/pagina_inspecao_inicial_periodica.dart';
import 'package:fall_calc_final/screens/fq_zlq/pagina_calculadora_fq_zlq.dart'
    show PaginaVisualizarPdf;
import 'package:fall_calc_final/utils/checklist/gerador_pdf_checklist_pre_uso.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaginaDetalheInspecaoInicialPeriodica extends StatefulWidget {
  const PaginaDetalheInspecaoInicialPeriodica({
    super.key,
    required this.checklist,
  });

  final ChecklistInspecaoInicialPeriodicaRegistro checklist;

  @override
  State<PaginaDetalheInspecaoInicialPeriodica> createState() =>
      _PaginaDetalheInspecaoInicialPeriodicaState();
}

class _PaginaDetalheInspecaoInicialPeriodicaState
    extends State<PaginaDetalheInspecaoInicialPeriodica> {
  bool _isLoadingPdf = false;
  bool _isSharing = false;

  static const List<String> _itensTravaQuedaDeslizanteIds = [
    'trava_queda_deslizante_01',
    'trava_queda_deslizante_02',
  ];

  String get _sectionIdNormalizado {
    // Compatibilidade: versão inicial do template tinha a seção
    // "trava_queda_deslizante_itens" separada; agora faz parte de "trava_queda_2b".
    final id = widget.checklist.sectionId;
    if (id == 'trava_queda_deslizante_itens') return 'trava_queda_2b';
    return id;
  }

  ChecklistSection _filtrarSection(ChecklistSection section) {
    if (section.id == 'trava_queda_2b' &&
        widget.checklist.travaQuedaDeslizante != true) {
      return ChecklistSection(
        id: section.id,
        title: section.title,
        items: section.items
            .where((i) => !_itensTravaQuedaDeslizanteIds.contains(i.id))
            .toList(growable: false),
      );
    }
    return section;
  }

  Future<ChecklistSection> _carregarSection() async {
    final jsonStr = await rootBundle.loadString(
      'assets/checklists/inspecao_inicial_periodica.json',
    );
    final template = ChecklistPreUsoTemplate.fromJsonString(jsonStr);
    final section = template.sections.firstWhere(
      (s) => s.id == _sectionIdNormalizado,
      orElse: () => template.sections.first,
    );

    return _filtrarSection(section);
  }

  Color _corOpcao(ChecklistOpcao? opcao, ColorScheme colorScheme) {
    switch (opcao) {
      case ChecklistOpcao.conforme:
        return colorScheme.primary;
      case ChecklistOpcao.naoConforme:
        return colorScheme.error;
      case ChecklistOpcao.naoSeAplica:
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _labelOpcao(ChecklistOpcao? opcao) {
    return (opcao ?? ChecklistOpcao.naoSeAplica).code;
  }

  Future<String> _gerarPdfParaArquivoTemp() async {
    final prefs = await SharedPreferences.getInstance();
    final nomeUsuario = prefs.getString('nome');
    final matriculaUsuario = prefs.getString('matricula');
    final empresaUsuario = prefs.getString('empresa');
    final emailUsuario = prefs.getString('email');
    final estadoUsuario = prefs.getString('estado');
    final municipioUsuario = prefs.getString('municipio');

    final jsonStr = await rootBundle.loadString(
      'assets/checklists/inspecao_inicial_periodica.json',
    );
    final template = ChecklistPreUsoTemplate.fromJsonString(jsonStr);

    final sectionOriginal = template.sections.firstWhere(
      (s) => s.id == _sectionIdNormalizado,
      orElse: () => template.sections.first,
    );

    final section = _filtrarSection(sectionOriginal);

    final Uint8List? assinaturaPng =
        widget.checklist.assinaturaBase64Png != null
        ? decodePngFromBase64(widget.checklist.assinaturaBase64Png!)
        : null;

    final pdfBytes = await gerarPdfChecklistPreUso(
      template: template,
      section: section,
      respostas: widget.checklist.respostas,
      createdAt: widget.checklist.createdAt,
      assinaturaPng: assinaturaPng,
      equipamentoTag: widget.checklist.equipamentoTag,
      equipamentoFotoPath: widget.checklist.equipamentoFotoPath,
      nomeUsuario: nomeUsuario,
      matriculaUsuario: matriculaUsuario,
      empresaUsuario: empresaUsuario,
      emailUsuario: emailUsuario,
      estadoUsuario: estadoUsuario,
      municipioUsuario: municipioUsuario,
      tipoInspecaoLabel: widget.checklist.tipoInspecao.label,
    );

    final tempDir = await getTemporaryDirectory();
    final filename =
        'inspecao_${widget.checklist.createdAt.millisecondsSinceEpoch}.pdf';
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  Future<void> _visualizarPdf() async {
    final assinatura = (widget.checklist.assinaturaBase64Png ?? '').trim();
    if (assinatura.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Checklist sem assinatura: não é possível gerar/visualizar o PDF.',
          ),
        ),
      );
      return;
    }

    if (_isLoadingPdf) return;
    setState(() => _isLoadingPdf = true);

    try {
      final caminhoPdf = await _gerarPdfParaArquivoTemp();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaginaVisualizarPdf(caminhoPdf: caminhoPdf),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingPdf = false);
    }
  }

  Future<void> _encaminharPdf() async {
    final assinatura = (widget.checklist.assinaturaBase64Png ?? '').trim();
    if (assinatura.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Checklist sem assinatura: não é possível gerar/encaminhar o PDF.',
          ),
        ),
      );
      return;
    }

    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final caminhoPdf = await _gerarPdfParaArquivoTemp();
      if (!mounted) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      final xFile = XFile(
        caminhoPdf,
        mimeType: 'application/pdf',
        name: 'inspecao_inicial_periodica.pdf',
      );

      final tag = (widget.checklist.equipamentoTag ?? '').trim();
      final assunto = tag.isNotEmpty
          ? '${widget.checklist.tipoInspecao.label} - $tag'
          : widget.checklist.tipoInspecao.label;

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: assunto,
          subject: assunto,
          sharePositionOrigin: renderBox != null
              ? (renderBox.localToGlobal(Offset.zero) & renderBox.size)
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checklist = widget.checklist;
    final colorScheme = theme.colorScheme;

    final formatadorData = DateFormat('dd/MM/yyyy HH:mm');
    final dataFormatada = formatadorData.format(checklist.createdAt);
    final tag = (checklist.equipamentoTag ?? '').trim();
    final hasFotoEquipamento =
        checklist.equipamentoFotoPath != null &&
        checklist.equipamentoFotoPath!.trim().isNotEmpty &&
        File(checklist.equipamentoFotoPath!).existsSync();
    final hasAssinatura =
        checklist.assinaturaBase64Png != null &&
        checklist.assinaturaBase64Png!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          checklist.rascunho ? 'Rascunho da Inspeção' : 'Detalhe da Inspeção',
        ),
        actions: [
          if (checklist.rascunho)
            IconButton(
              tooltip: 'Editar Rascunho',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaginaInspecaoInicialPeriodica(
                      checklistParaEditar: checklist,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            tooltip: 'Encaminhar',
            onPressed: _isSharing ? null : _encaminharPdf,
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          top: 16,
          right: 16,
          // Espaçamento fixo - evita rebuild ao abrir/fechar teclado
          bottom: 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (checklist.rascunho) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Este é um rascunho. Assine para finalizar o relatório.',
                        style: TextStyle(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _isLoadingPdf ? null : _visualizarPdf,
              icon: _isLoadingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: const Text('Visualizar PDF'),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checklist.tipoInspecao.label,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Data: $dataFormatada'),
                    const SizedBox(height: 4),
                    Text('Checklist: ${checklist.sectionTitle}'),
                    const SizedBox(height: 4),
                    Text('TAG: ${tag.isEmpty ? "Sem TAG" : tag}'),
                    const SizedBox(height: 4),
                    if (checklist.rascunho)
                      Row(
                        children: [
                          Icon(Icons.edit_note, color: colorScheme.tertiary),
                          const SizedBox(width: 8),
                          Text(
                            'Status: RASCUNHO',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(
                            checklist.interditado
                                ? Icons.warning_amber
                                : Icons.check_circle_outline,
                            color: checklist.interditado
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            checklist.interditado
                                ? 'Status: INTERDITADO'
                                : 'Status: Conforme',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: checklist.interditado
                                  ? colorScheme.error
                                  : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            if (hasFotoEquipamento) ...[
              const SizedBox(height: 16),
              Text('Foto do equipamento', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(checklist.equipamentoFotoPath!),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) {
                    return Container(
                      height: 220,
                      alignment: Alignment.center,
                      color: colorScheme.surfaceContainerHighest,
                      child: const Text('Não foi possível carregar a imagem.'),
                    );
                  },
                ),
              ),
            ],

            if (hasAssinatura) ...[
              const SizedBox(height: 16),
              Text('Assinatura', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  try {
                    final bytes = decodePngFromBase64(
                      checklist.assinaturaBase64Png!,
                    );
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: colorScheme.surface,
                        padding: const EdgeInsets.all(12),
                        child: Image.memory(
                          bytes,
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  } catch (_) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Assinatura inválida.'),
                    );
                  }
                },
              ),
            ],

            const SizedBox(height: 16),
            Text('Itens preenchidos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<ChecklistSection>(
              future: _carregarSection(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Erro ao carregar seção: ${snapshot.error}');
                }

                final section = snapshot.data;
                if (section == null) {
                  return const Text('Seção não encontrada no template.');
                }

                return Column(
                  children: [
                    for (final item in section.items)
                      _buildItemCard(item, checklist.respostas[item.id]),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(ChecklistItem item, ChecklistResposta? resposta) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final opcao = resposta?.opcao ?? ChecklistOpcao.naoSeAplica;
    final cor = _corOpcao(opcao, colorScheme);
    final label = _labelOpcao(opcao);

    final observacao = (resposta?.observacao ?? '').trim();
    final fotoPath = (resposta?.fotoPath ?? '').trim();
    final hasFoto = fotoPath.isNotEmpty && File(fotoPath).existsSync();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.text, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
            if (opcao == ChecklistOpcao.naoConforme) ...[
              const SizedBox(height: 10),
              if (observacao.isNotEmpty)
                Text('Obs: $observacao', style: theme.textTheme.bodySmall),
              if (hasFoto) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(fotoPath),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Text(
                          'Não foi possível carregar a imagem.',
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (!hasFoto && fotoPath.isNotEmpty)
                Text(
                  'Foto não encontrada no dispositivo.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
