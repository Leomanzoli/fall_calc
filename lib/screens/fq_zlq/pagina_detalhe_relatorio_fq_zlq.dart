// lib/screens/pagina_detalhe_relatorio.dart
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fall_calc_final/utils/gerador_pdf_fq_zlq.dart';
import 'package:fall_calc_final/models/relatoriofq_zlq.dart';
import 'package:fall_calc_final/screens/fq_zlq/pagina_calculadora_fq_zlq.dart';

class PaginaDetalheRelatorio extends StatefulWidget {
  final Relatorio relatorio;
  const PaginaDetalheRelatorio({super.key, required this.relatorio});

  @override
  State<PaginaDetalheRelatorio> createState() => _PaginaDetalheRelatorioState();
}

class _PaginaDetalheRelatorioState extends State<PaginaDetalheRelatorio> {
  late Relatorio relatorioAtual;
  bool _isSharing = false;
  bool _isLoadingPdf = false;
  bool _pdfExiste = false;

  @override
  void initState() {
    super.initState();
    relatorioAtual = widget.relatorio;
    _verificarExistenciaPdf();
  }

  Future<void> _verificarExistenciaPdf() async {
    final path = relatorioAtual.caminhoPdf;
    if (path == null || path.isEmpty) {
      if (mounted) setState(() => _pdfExiste = false);
      return;
    }
    final fileExists = await File(path).exists();
    if (mounted) setState(() => _pdfExiste = fileExists);
  }

  Future<void> _navegarParaEdicao() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaginaCalculadora(relatorioParaEditar: relatorioAtual),
      ),
    );
    if (resultado == true && mounted) {
      _recarregarRelatorioAtualizado();
    }
  }

  Future<void> _recarregarRelatorioAtualizado() async {
    final prefs = await SharedPreferences.getInstance();
    final relatoriosJson = prefs.getStringList('relatorios') ?? [];
    final jsonStringRelatorio = relatoriosJson.firstWhere((jsonString) {
      try {
        return Relatorio.fromJson(jsonDecode(jsonString)).id ==
            relatorioAtual.id;
      } catch (e) {
        return false;
      }
    }, orElse: () => '');
    if (jsonStringRelatorio.isNotEmpty && mounted) {
      setState(() {
        relatorioAtual = Relatorio.fromJson(jsonDecode(jsonStringRelatorio));
      });
      await _verificarExistenciaPdf();
    }
  }

  Future<String> _garantirPdfExiste() async {
    await _verificarExistenciaPdf();
    if (_pdfExiste && relatorioAtual.caminhoPdf != null) {
      return relatorioAtual.caminhoPdf!;
    }

    final pdfBytes = await gerarPdfRelatorio(relatorioAtual);
    final tempDir = await getTemporaryDirectory();
    final caminhoPdfFinal =
        '${tempDir.path}/relatorio_${relatorioAtual.id}.pdf';
    final file = File(caminhoPdfFinal);
    await file.writeAsBytes(pdfBytes);

    final prefs = await SharedPreferences.getInstance();
    final relatoriosJson = prefs.getStringList('relatorios') ?? [];
    relatoriosJson.removeWhere((jsonString) {
      final relatorioMap = jsonDecode(jsonString);
      return relatorioMap['id'] == relatorioAtual.id;
    });

    setState(() {
      relatorioAtual.caminhoPdf = caminhoPdfFinal;
      _pdfExiste = true;
    });

    relatoriosJson.add(jsonEncode(relatorioAtual.toJson()));
    await prefs.setStringList('relatorios', relatoriosJson);

    return caminhoPdfFinal;
  }

  Future<void> _visualizarPdf() async {
    if (_isLoadingPdf) return;
    if (mounted) setState(() => _isLoadingPdf = true);

    try {
      final caminhoPdf = await _garantirPdfExiste();
      if (!mounted) return;
      // Navega para a tela de visualização de PDF que está em pagina_calculadora.dart
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

  Future<void> _partilharPdf() async {
    if (_isSharing) return;
    if (mounted) setState(() => _isSharing = true);

    try {
      final caminhoPdfFinal = await _garantirPdfExiste();

      if (!mounted) return;

      final renderBox = context.findRenderObject() as RenderBox?;

      final xFile = XFile(
        caminhoPdfFinal,
        mimeType: 'application/pdf',
        name: 'relatorio_${relatorioAtual.id}.pdf',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'Relatório NR-35 - ${relatorioAtual.localAtividade}',
          subject: 'Relatório de Cálculo de ZLQ e FQ',
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          relatorioAtual.localAtividade.isNotEmpty
              ? 'Relatório: ${relatorioAtual.localAtividade}'
              : 'Detalhe do Relatório',
        ),
        actions: [
          IconButton(
            icon: _isSharing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.share_outlined),
            tooltip: 'Partilhar Relatório',
            onPressed: _isSharing ? null : _partilharPdf,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar Relatório',
            onPressed: _navegarParaEdicao,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ElevatedButton.icon(
                icon: _isLoadingPdf
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        _pdfExiste
                            ? Icons.visibility
                            : Icons.picture_as_pdf_outlined,
                      ),
                label: Text(
                  _pdfExiste ? 'Visualizar Relatório' : 'Gerar e Visualizar',
                ),
                onPressed: _isLoadingPdf ? null : _visualizarPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pdfExiste
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const Divider(height: 30),
            if (relatorioAtual.caminhoImagem != null &&
                relatorioAtual.caminhoImagem?.isNotEmpty == true) ...[
              Text('Imagem do Local:', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(File(relatorioAtual.caminhoImagem!)),
              ),
              const SizedBox(height: 16),
            ],
            if (relatorioAtual.caminhoImagem2 != null &&
                relatorioAtual.caminhoImagem2?.isNotEmpty == true) ...[
              Text('Segunda Imagem:', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(File(relatorioAtual.caminhoImagem2!)),
              ),
              const SizedBox(height: 16),
            ],
            Text('Parâmetros Utilizados:', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildParametrosCard(),
            const SizedBox(height: 16),
            Text(
              'Resultados e Informações Gerais:',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildInfoGeraisCard(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildParametrosCard() {
    final bool usaTravaQuedas = relatorioAtual.usaTravaQuedas;
    final bool incluiDeformacao = relatorioAtual.incluiDeformacaoCinto;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildParametroLinha(
              label: 'Altura da Ancoragem (AA):',
              valor: '${relatorioAtual.alturaAncoragem.toStringAsFixed(2)}m',
            ),
            if (usaTravaQuedas) ...[
              _buildParametroLinha(
                label: 'Equipamento:',
                valor: 'Trava-quedas Retrátil',
                isHighlight: true,
              ),
              _buildParametroLinha(
                label: 'Distância de Operação de Freio (DOF):',
                valor: '${relatorioAtual.estAbsorvedor.toStringAsFixed(2)}m',
              ),
            ] else ...[
              _buildParametroLinha(
                label: 'Equipamento:',
                valor: 'Talabarte com Absorvedor',
                isHighlight: true,
              ),
              _buildParametroLinha(
                label: 'Comprimento do Talabarte (L):',
                valor: '${relatorioAtual.compTalabarte.toStringAsFixed(2)}m',
              ),
              _buildParametroLinha(
                label: 'Estiramento do Absorvedor (EA):',
                valor: '${relatorioAtual.estAbsorvedor.toStringAsFixed(2)}m',
              ),
            ],
            _buildParametroLinha(
              label: 'Distância do Anel-D aos Pés (C):',
              valor: '${relatorioAtual.distPes.toStringAsFixed(2)}m',
            ),
            const Divider(height: 20, thickness: 0.5),
            _buildParametroLinha(
              label: 'Fator Deformação Cinto (+0.3m):',
              valor: incluiDeformacao ? 'Sim' : 'Não',
            ),
            _buildParametroLinha(
              label: 'Ancoragem:',
              valor: relatorioAtual.usaLinhaVidaHorizontal
                  ? 'Linha de Vida Horizontal'
                  : 'Ancoragem Rígida',
              isHighlight: relatorioAtual.usaLinhaVidaHorizontal,
            ),
            if (relatorioAtual.usaLinhaVidaHorizontal)
              _buildParametroLinha(
                label: 'Flecha de Projeto (FLV):',
                valor: '${relatorioAtual.flechaProjeto.toStringAsFixed(2)}m',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGeraisCard() {
    final theme = Theme.of(context);
    // ===== ATUALIZAÇÃO DA LÓGICA DA LABEL AQUI =====
    final String fqLabel = relatorioAtual.usaTravaQuedas
        ? 'Potencial de Queda Livre (m):'
        : 'Fator de Queda (FQ):';
    // ===============================================
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          ListTile(
            title: const Text('Local da Atividade'),
            subtitle: Text(
              relatorioAtual.localAtividade,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          ListTile(
            title: const Text('Data e Hora'),
            subtitle: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(relatorioAtual.dataHora),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          ListTile(
            title: Text(fqLabel),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relatorioAtual.fq.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (relatorioAtual.mensagemAlertaFQ.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      relatorioAtual.mensagemAlertaFQ,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ListTile(
            title: const Text('ZLQ (desde a ancoragem)'),
            subtitle: Text(
              '${relatorioAtual.zlqAncoragem.toStringAsFixed(2)} metros',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          ListTile(
            title: const Text('F (distância livre desde os pés)'),
            subtitle: Text(
              '${relatorioAtual.zlqPes.toStringAsFixed(2)} metros',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          if (relatorioAtual.observacoes.isNotEmpty)
            ListTile(
              title: const Text('Observações'),
              subtitle: Text(
                relatorioAtual.observacoes,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // Mostrar assinatura digital se existir
          if (relatorioAtual.assinaturaBase64Png != null &&
              relatorioAtual.assinaturaBase64Png!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assinatura Digital',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha(128),
                      ),
                    ),
                    child: Center(
                      child: Image.memory(
                        base64Decode(relatorioAtual.assinaturaBase64Png!),
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParametroLinha({
    required String label,
    required String valor,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isHighlight ? theme.colorScheme.primary : null,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isHighlight ? theme.colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
