// lib/utils/gerador_pdf.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:fall_calc_final/models/relatoriofq_zlq.dart';
import 'package:fall_calc_final/utils/imagem_local.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// --- DEFINIÇÃO DOS ASSETS ---
const String _assetZlq = 'assets/imagens/ZLQ.png';
const String _assetZlqDof = 'assets/imagens/ZLQ_DOF.png';
const String _assetTalabarte = 'assets/imagens/Talabarte.png';
const String _assetLTravaquedas = 'assets/imagens/L_travaquedas.png';
const String _assetDof = 'assets/imagens/DOF.png';
const String _assetZlqEf = 'assets/imagens/ZLQ_E_F.png';
const String _assetZlqLvh = 'assets/imagens/ZLQ_LVH.png';
const String _assetZlqDofLvh = 'assets/imagens/ZLQ_DOF_LVH.png';
const String _assetZlqEfLvh = 'assets/imagens/ZLQ_E_F_LVH.png';
const String _assetFlv = 'assets/imagens/FLV.png';
const String _assetFooterLogo = 'assets/icones/FallCalc.png';
const String _footerText = kIsWeb
    ? 'Relatório gerado pelo FallCalc35 (versão web) - Versão completa disponível para Android'
    : 'Relatório gerado pelo FallCalc35 - Disponível na Google Play Store';

// --- CORES PROFISSIONAIS ---
const PdfColor _corPrimaria = PdfColor.fromInt(0xFF1565C0); // Azul profissional
const PdfColor _corSecundaria = PdfColor.fromInt(0xFF37474F); // Cinza escuro
const PdfColor _corAlerta = PdfColor.fromInt(0xFFC62828); // Vermelho
const PdfColor _corFundoClaro = PdfColor.fromInt(0xFFF5F5F5); // Cinza claro
const PdfColor _corBorda = PdfColor.fromInt(0xFFBDBDBD); // Cinza médio

// --- ESTILOS DE TEXTO PADRONIZADOS ---
pw.TextStyle get _estiloLabel =>
    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700);

pw.TextStyle get _estiloValor => pw.TextStyle(
  fontSize: 10,
  fontWeight: pw.FontWeight.bold,
  color: PdfColors.black,
);

pw.TextStyle get _estiloTextoNormal =>
    const pw.TextStyle(fontSize: 9, color: PdfColors.black);

pw.TextStyle get _estiloTextoDestaque => pw.TextStyle(
  fontSize: 11,
  fontWeight: pw.FontWeight.bold,
  color: _corPrimaria,
);

/// Carrega uma imagem a partir dos assets da aplicação.
Future<pw.ImageProvider?> _loadAssetImage(String assetPath) async {
  try {
    final ByteData data = await rootBundle.load(assetPath);
    debugPrint(
      '[PDF] Asset carregado: $assetPath (${data.lengthInBytes} bytes)',
    );
    return pw.MemoryImage(data.buffer.asUint8List());
  } catch (e) {
    debugPrint('[PDF][ERRO] Falha ao carregar asset "$assetPath": $e');
    return null;
  }
}

/// Carrega uma imagem a partir de um caminho registrado em [ImagemLocal].
Future<pw.ImageProvider?> _loadFileImage(String? filePath) async {
  if (filePath == null || filePath.isEmpty) {
    debugPrint('[PDF] Caminho de imagem local nulo/vazio; nada a carregar.');
    return null;
  }
  try {
    final bytes = await ImagemLocal.lerBytes(filePath);
    if (bytes == null) {
      debugPrint('[PDF][ERRO] Imagem local não encontrada: $filePath');
      return null;
    }
    debugPrint(
      '[PDF] Imagem local carregada: $filePath (${bytes.length} bytes)',
    );
    return pw.MemoryImage(bytes);
  } catch (e) {
    debugPrint('[PDF][ERRO] Falha ao ler imagem local "$filePath": $e');
    return null;
  }
}

/// Cria um cabeçalho de seção padronizado
pw.Widget _buildSecaoHeader(String titulo) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    decoration: pw.BoxDecoration(
      color: _corPrimaria,
      borderRadius: const pw.BorderRadius.only(
        topLeft: pw.Radius.circular(4),
        topRight: pw.Radius.circular(4),
      ),
    ),
    child: pw.Text(
      titulo.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        letterSpacing: 0.5,
      ),
    ),
  );
}

/// Cria uma linha de parâmetro com label e valor
pw.Widget _buildLinhaParametro(
  String label,
  String valor, {
  bool destaque = false,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 10),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(flex: 3, child: pw.Text(label, style: _estiloLabel)),
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            valor,
            style: destaque ? _estiloTextoDestaque : _estiloValor,
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

/// Cria um card com borda e fundo
pw.Widget _buildCard({required List<pw.Widget> children, String? titulo}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _corBorda, width: 0.5),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [if (titulo != null) _buildSecaoHeader(titulo), ...children],
    ),
  );
}

/// Helper para informações do responsável
pw.Widget _buildLinhaInfoPessoa(String label, String valor) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 60, child: pw.Text('$label:', style: _estiloLabel)),
        pw.Expanded(child: pw.Text(valor, style: _estiloValor)),
      ],
    ),
  );
}

/// Notas técnicas com layout profissional
pw.Widget _buildNotasTecnicas() {
  pw.Widget buildNotaItem(String titulo, String descricao) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 3, right: 6),
            decoration: const pw.BoxDecoration(
              color: _corPrimaria,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey800,
                ),
                children: [
                  pw.TextSpan(
                    text: '$titulo: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.TextSpan(text: descricao),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 15),
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: _corFundoClaro,
      border: pw.Border.all(color: _corBorda, width: 0.5),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'NOTAS TÉCNICAS IMPORTANTES',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _corSecundaria,
            letterSpacing: 0.3,
          ),
        ),
        pw.Divider(height: 8, color: _corBorda),
        buildNotaItem(
          'Ferramenta de Apoio',
          'Este relatório auxilia a Análise de Risco (AR) e não substitui a própria análise técnica.',
        ),
        buildNotaItem(
          'Responsabilidade',
          'A precisão dos resultados depende da exatidão dos dados inseridos pelo usuário.',
        ),
        buildNotaItem(
          'Consulte o Fabricante',
          'É obrigatório consultar o manual do EPIQ para valores exatos de EA ou DOF.',
        ),
        buildNotaItem(
          'Limitações',
          'Cálculos consideram queda vertical, sem efeito pêndulo ou planos inclinados.',
        ),
        buildNotaItem(
          'Margem de Segurança',
          'ZLQ inclui MS de 1,0m que deve estar livre de obstáculos.',
        ),
      ],
    ),
  );
}

/// Gera a memória de cálculo detalhada para o PDF
pw.Widget _buildMemoriaCalculo(Relatorio relatorio) {
  final List<String> linhasCalculo = [];
  const double ms = 1.0; // Margem de segurança padrão
  final double deformacao = relatorio.incluiDeformacaoCinto ? 0.3 : 0.0;
  final double flecha = relatorio.usaLinhaVidaHorizontal
      ? relatorio.flechaProjeto
      : 0.0;

  if (relatorio.usaTravaQuedas) {
    // Modo Trava-quedas
    final double dof = relatorio.estAbsorvedor;
    final double aa = relatorio.alturaAncoragem;
    final double c = relatorio.distPes;
    double potencialQuedaLivre = 0.0;

    if (aa < c) {
      potencialQuedaLivre = c - aa;
    }

    linhasCalculo.add('MODO: Trava-quedas Retrátil');
    linhasCalculo.add('');
    linhasCalculo.add('Potencial de Queda Livre (PQL):');
    if (aa >= c) {
      linhasCalculo.add(
        '  AA (${aa.toStringAsFixed(2)}m) >= C (${c.toStringAsFixed(2)}m)',
      );
      linhasCalculo.add('  PQL = 0,00 m (ancoragem acima do anel-D)');
    } else {
      linhasCalculo.add(
        '  PQL = C - AA = ${c.toStringAsFixed(2)} - ${aa.toStringAsFixed(2)} = ${potencialQuedaLivre.toStringAsFixed(2)} m',
      );
    }

    linhasCalculo.add('');
    linhasCalculo.add('ZLQ (desde ancoragem):');
    String formula = '  ZLQ = PQL + DOF';
    String valores =
        '  ZLQ = ${potencialQuedaLivre.toStringAsFixed(2)} + ${dof.toStringAsFixed(2)}';

    if (deformacao > 0) {
      formula += ' + Deformação';
      valores += ' + ${deformacao.toStringAsFixed(2)}';
    }
    if (flecha > 0) {
      formula += ' + Flecha';
      valores += ' + ${flecha.toStringAsFixed(2)}';
    }
    formula += ' + MS';
    valores += ' + ${ms.toStringAsFixed(2)}';

    linhasCalculo.add(formula);
    linhasCalculo.add(valores);
    linhasCalculo.add('  ZLQ = ${relatorio.zlqAncoragem.toStringAsFixed(2)} m');

    linhasCalculo.add('');
    linhasCalculo.add('F (distância livre desde os pés):');
    linhasCalculo.add(
      '  F = ZLQ - AA = ${relatorio.zlqAncoragem.toStringAsFixed(2)} - ${aa.toStringAsFixed(2)} = ${(relatorio.zlqAncoragem - aa).toStringAsFixed(2)} m',
    );
    if (relatorio.zlqPes < ms) {
      linhasCalculo.add('  F < 1,00 m → F = 1,00 m (mínimo)');
    }
  } else {
    // Modo Talabarte com Absorvedor
    final double l = relatorio.compTalabarte;
    final double ea = relatorio.estAbsorvedor;
    final double aa = relatorio.alturaAncoragem;
    final double c = relatorio.distPes;

    final double alturaAncoragemCinto = aa - c;
    double alturaDaQueda = l - alturaAncoragemCinto;
    if (alturaDaQueda < 0) alturaDaQueda = 0;

    final double fq = l > 0 ? alturaDaQueda / l : 0;

    linhasCalculo.add('MODO: Talabarte com Absorvedor de Energia');
    linhasCalculo.add('');

    // Fator de Queda
    linhasCalculo.add('Fator de Queda (FQ):');
    linhasCalculo.add('  Altura da Queda (Hq) = L - (AA - C)');
    linhasCalculo.add(
      '  Hq = ${l.toStringAsFixed(2)} - (${aa.toStringAsFixed(2)} - ${c.toStringAsFixed(2)}) = ${alturaDaQueda.toStringAsFixed(2)} m',
    );
    linhasCalculo.add(
      '  FQ = Hq / L = ${alturaDaQueda.toStringAsFixed(2)} / ${l.toStringAsFixed(2)} = ${fq.toStringAsFixed(2)}',
    );

    linhasCalculo.add('');
    linhasCalculo.add('ZLQ (desde ancoragem):');

    // Fórmula direta - ZLQ é sempre medida da ancoragem para baixo
    // Independente de onde está a ancoragem em relação ao anel-D
    linhasCalculo.add('  (ZLQ é medida da ancoragem para baixo)');
    String formula = '  ZLQ = L + EA + C';
    String valores =
        '  ZLQ = ${l.toStringAsFixed(2)} + ${ea.toStringAsFixed(2)} + ${c.toStringAsFixed(2)}';

    if (deformacao > 0) {
      formula += ' + Deformação';
      valores += ' + ${deformacao.toStringAsFixed(2)}';
    }
    if (flecha > 0) {
      formula += ' + Flecha';
      valores += ' + ${flecha.toStringAsFixed(2)}';
    }
    formula += ' + MS';
    valores += ' + ${ms.toStringAsFixed(2)}';

    linhasCalculo.add(formula);
    linhasCalculo.add(valores);

    linhasCalculo.add('  ZLQ = ${relatorio.zlqAncoragem.toStringAsFixed(2)} m');

    linhasCalculo.add('');
    linhasCalculo.add('F (distância livre desde os pés):');
    linhasCalculo.add(
      '  F = ZLQ - AA = ${relatorio.zlqAncoragem.toStringAsFixed(2)} - ${aa.toStringAsFixed(2)} = ${(relatorio.zlqAncoragem - aa).toStringAsFixed(2)} m',
    );
    if (relatorio.zlqPes < ms) {
      linhasCalculo.add('  F < 1,00 m → F = 1,00 m (mínimo)');
    }
  }

  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 10),
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFFFFDE7), // Amarelo claro
      border: pw.Border.all(color: PdfColor.fromInt(0xFFFFD54F), width: 0.5),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'MEMÓRIA DE CÁLCULO',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _corSecundaria,
            letterSpacing: 0.3,
          ),
        ),
        pw.Divider(height: 8, color: PdfColor.fromInt(0xFFFFD54F)),
        pw.Text(
          linhasCalculo.join('\n'),
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
        ),
      ],
    ),
  );
}

/// Função principal que gera o documento PDF a partir de um objeto [Relatorio].
Future<Uint8List> gerarPdfRelatorio(Relatorio relatorio) async {
  final pdf = pw.Document(
    title: 'Relatório de Análise de Risco de Queda',
    author: relatorio.nomeUtilizador,
    creator: 'FallCalc35',
  );

  // Carregar imagens
  final imagemLocal = await _loadFileImage(relatorio.caminhoImagem);
  final imagemLocal2 = await _loadFileImage(relatorio.caminhoImagem2);
  // Escolher diagrama ZLQ correto baseado nas opções
  String assetDiagramaZlq;
  if (relatorio.usaTravaQuedas && relatorio.usaLinhaVidaHorizontal) {
    assetDiagramaZlq = _assetZlqDofLvh;
  } else if (relatorio.usaTravaQuedas) {
    assetDiagramaZlq = _assetZlqDof;
  } else if (relatorio.usaLinhaVidaHorizontal) {
    assetDiagramaZlq = _assetZlqLvh;
  } else {
    assetDiagramaZlq = _assetZlq;
  }
  final diagramaZlq = await _loadAssetImage(assetDiagramaZlq);
  final imagemTalabarte = await _loadAssetImage(_assetTalabarte);
  final imagemLTravaquedas = await _loadAssetImage(_assetLTravaquedas);
  final imagemDof = await _loadAssetImage(_assetDof);
  final imagemFlv = await _loadAssetImage(_assetFlv);
  // Usar imagem de ZLQ E F com ou sem LVH
  final imagemZlqEf = await _loadAssetImage(
    relatorio.usaLinhaVidaHorizontal ? _assetZlqEfLvh : _assetZlqEf,
  );
  final footerLogo = await _loadAssetImage(_assetFooterLogo);

  // Carregar assinatura digital
  pw.ImageProvider? assinaturaImg;
  if (relatorio.assinaturaBase64Png != null &&
      relatorio.assinaturaBase64Png!.isNotEmpty) {
    try {
      final assinaturaBytes = base64Decode(relatorio.assinaturaBase64Png!);
      assinaturaImg = pw.MemoryImage(assinaturaBytes);
    } catch (e) {
      debugPrint('[PDF][ERRO] Falha ao decodificar assinatura: $e');
    }
  }

  // Formatação de data e hora
  final formatadorData = DateFormat('dd/MM/yyyy', 'pt_BR');
  final formatadorHora = DateFormat('HH:mm', 'pt_BR');
  final dataFormatada = formatadorData.format(relatorio.dataHora);
  final horaFormatada = formatadorHora.format(relatorio.dataHora);

  final double fExibida = relatorio.zlqPes < 1.0 ? 1.0 : relatorio.zlqPes;
  final String fqLabel = relatorio.usaTravaQuedas
      ? 'Potencial de Queda Livre'
      : 'Fator de Queda (FQ)';
  final String equipamentoTipo = relatorio.usaTravaQuedas
      ? 'Trava-quedas Retrátil'
      : 'Talabarte c/ Absorvedor';
  final String tipoAncoragem = relatorio.usaLinhaVidaHorizontal
      ? 'Linha de Vida Horizontal'
      : 'Ancoragem Rígida';

  const pageFormat = PdfPageFormat.a4;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.all(40),
      header: (context) {
        if (context.pageNumber == 1) return pw.SizedBox.shrink();
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.only(bottom: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _corPrimaria, width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Relatório de Análise de Risco de Queda',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: _corSecundaria,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Local: ${relatorio.localAtividade}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        );
      },
      footer: (context) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 10),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  if (footerLogo != null) ...[
                    pw.Image(footerLogo, height: 12),
                    pw.SizedBox(width: 6),
                  ],
                  pw.Text(
                    _footerText,
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        );
      },
      build: (pw.Context context) {
        return <pw.Widget>[
          // === CABEÇALHO PRINCIPAL ===
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: _corPrimaria,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RELATÓRIO DE ANÁLISE DE RISCO DE QUEDA',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        equipamentoTipo.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _corPrimaria,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      '$dataFormatada às $horaFormatada',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          // === INFORMAÇÕES DO LOCAL ===
          _buildCard(
            titulo: 'Informações do Local',
            children: [
              _buildLinhaParametro(
                'Local da Atividade',
                relatorio.localAtividade,
              ),
              _buildLinhaParametro('Data', dataFormatada),
              _buildLinhaParametro('Hora', horaFormatada),
            ],
          ),
          pw.SizedBox(height: 15),

          // === IMAGENS ===
          if (imagemLocal != null || imagemLocal2 != null) ...[
            _buildSecaoHeader('Registro Fotográfico'),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _corBorda, width: 0.5),
                borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(4),
                  bottomRight: pw.Radius.circular(4),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (imagemLocal != null)
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.ClipRRect(
                            horizontalRadius: 4,
                            verticalRadius: 4,
                            child: pw.Image(
                              imagemLocal,
                              height: imagemLocal2 != null
                                  ? 5 * PdfPageFormat.cm
                                  : 7 * PdfPageFormat.cm,
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Imagem 1', style: _estiloLabel),
                        ],
                      ),
                    ),
                  if (imagemLocal != null && imagemLocal2 != null)
                    pw.SizedBox(width: 15),
                  if (imagemLocal2 != null)
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.ClipRRect(
                            horizontalRadius: 4,
                            verticalRadius: 4,
                            child: pw.Image(
                              imagemLocal2,
                              height: imagemLocal != null
                                  ? 5 * PdfPageFormat.cm
                                  : 7 * PdfPageFormat.cm,
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Imagem 2', style: _estiloLabel),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
          ],

          // === IMAGENS DO EQUIPAMENTO ===
          _buildSecaoHeader('Equipamento de Proteção'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _corBorda, width: 0.5),
              borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(4),
                bottomRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Imagens de Trava-quedas ou Talabarte
                if (relatorio.usaTravaQuedas) ...[
                  if (imagemLTravaquedas != null)
                    pw.Column(
                      children: [
                        pw.Image(
                          imagemLTravaquedas,
                          height: 4 * PdfPageFormat.cm,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Trava-quedas', style: _estiloLabel),
                      ],
                    ),
                  if (imagemDof != null)
                    pw.Column(
                      children: [
                        pw.Image(imagemDof, height: 4 * PdfPageFormat.cm),
                        pw.SizedBox(height: 4),
                        pw.Text('DOF', style: _estiloLabel),
                      ],
                    ),
                ] else ...[
                  if (imagemTalabarte != null)
                    pw.Column(
                      children: [
                        pw.Image(imagemTalabarte, height: 4 * PdfPageFormat.cm),
                        pw.SizedBox(height: 4),
                        pw.Text('Talabarte c/ Absorvedor', style: _estiloLabel),
                      ],
                    ),
                ],
                // Imagem de Linha de Vida Horizontal (se aplicável)
                if (relatorio.usaLinhaVidaHorizontal && imagemFlv != null)
                  pw.Column(
                    children: [
                      pw.Image(imagemFlv, height: 4 * PdfPageFormat.cm),
                      pw.SizedBox(height: 4),
                      pw.Text('Linha de Vida Horizontal', style: _estiloLabel),
                    ],
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          // === PARÂMETROS E DIAGRAMA ===
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Parâmetros
              pw.Expanded(
                flex: 3,
                child: _buildCard(
                  titulo: 'Parâmetros Utilizados',
                  children: [
                    _buildLinhaParametro(
                      'Altura Ancoragem (AA)',
                      '${relatorio.alturaAncoragem.toStringAsFixed(2)} m',
                    ),
                    _buildLinhaParametro(
                      'Distância Anel-D aos Pés (C)',
                      '${relatorio.distPes.toStringAsFixed(2)} m',
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      color: _corFundoClaro,
                      child: pw.Row(
                        children: [
                          pw.Text('Equipamento: ', style: _estiloLabel),
                          pw.Text(equipamentoTipo, style: _estiloValor),
                        ],
                      ),
                    ),
                    if (relatorio.usaTravaQuedas) ...[
                      _buildLinhaParametro(
                        'Distância Operação Freio (DOF)',
                        '${relatorio.estAbsorvedor.toStringAsFixed(2)} m',
                      ),
                    ] else ...[
                      _buildLinhaParametro(
                        'Comprimento Talabarte (L)',
                        '${relatorio.compTalabarte.toStringAsFixed(2)} m',
                      ),
                      _buildLinhaParametro(
                        'Estiramento Absorvedor (EA)',
                        '${relatorio.estAbsorvedor.toStringAsFixed(2)} m',
                      ),
                    ],
                    _buildLinhaParametro(
                      'Deformação Cinto (+0.3m)',
                      relatorio.incluiDeformacaoCinto
                          ? 'Incluído'
                          : 'Não incluído',
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      color: _corFundoClaro,
                      child: pw.Row(
                        children: [
                          pw.Text('Ancoragem: ', style: _estiloLabel),
                          pw.Text(tipoAncoragem, style: _estiloValor),
                        ],
                      ),
                    ),
                    if (relatorio.usaLinhaVidaHorizontal)
                      _buildLinhaParametro(
                        'Flecha de Projeto (FLV)',
                        '${relatorio.flechaProjeto.toStringAsFixed(2)} m',
                      ),
                    _buildLinhaParametro('Margem de Segurança (MS)', '1,00 m'),
                    pw.SizedBox(height: 5),
                  ],
                ),
              ),
              pw.SizedBox(width: 15),
              // Diagrama
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _corBorda, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      if (diagramaZlq != null)
                        pw.Image(diagramaZlq, height: 5.5 * PdfPageFormat.cm)
                      else
                        pw.Container(
                          height: 5.5 * PdfPageFormat.cm,
                          color: _corFundoClaro,
                          child: pw.Center(
                            child: pw.Text(
                              'Diagrama indisponível',
                              style: _estiloLabel,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),

          // === RESULTADOS ===
          _buildCard(
            titulo: 'Resultados do Cálculo',
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Fator de Queda / Potencial
                          pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            margin: const pw.EdgeInsets.only(bottom: 8),
                            decoration: pw.BoxDecoration(
                              color:
                                  relatorio.fq > 2 ||
                                      (relatorio.usaTravaQuedas &&
                                          relatorio.fq > 0.01)
                                  ? PdfColor.fromInt(0xFFFFEBEE)
                                  : _corFundoClaro,
                              borderRadius: pw.BorderRadius.circular(4),
                              border: pw.Border.all(
                                color:
                                    relatorio.fq > 2 ||
                                        (relatorio.usaTravaQuedas &&
                                            relatorio.fq > 0.01)
                                    ? _corAlerta
                                    : _corBorda,
                                width: 0.5,
                              ),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(fqLabel, style: _estiloLabel),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  relatorio.fq.toStringAsFixed(2),
                                  style: pw.TextStyle(
                                    fontSize: 20,
                                    fontWeight: pw.FontWeight.bold,
                                    color:
                                        relatorio.fq > 2 ||
                                            (relatorio.usaTravaQuedas &&
                                                relatorio.fq > 0.01)
                                        ? _corAlerta
                                        : _corPrimaria,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Alerta se houver
                          if (relatorio.mensagemAlertaFQ.isNotEmpty)
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              margin: const pw.EdgeInsets.only(bottom: 8),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFFFFEBEE),
                                border: pw.Border.all(
                                  color: _corAlerta,
                                  width: 1,
                                ),
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    '⚠ ',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _corAlerta,
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      relatorio.mensagemAlertaFQ,
                                      style: pw.TextStyle(
                                        fontSize: 8,
                                        color: _corAlerta,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // ZLQ
                          pw.Row(
                            children: [
                              pw.Expanded(
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.all(8),
                                  decoration: pw.BoxDecoration(
                                    color: _corFundoClaro,
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'ZLQ (desde ancoragem)',
                                        style: _estiloLabel,
                                      ),
                                      pw.Text(
                                        '${relatorio.zlqAncoragem.toStringAsFixed(2)} m',
                                        style: _estiloTextoDestaque,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Expanded(
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.all(8),
                                  decoration: pw.BoxDecoration(
                                    color: _corFundoClaro,
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'F (livre desde os pés)',
                                        style: _estiloLabel,
                                      ),
                                      pw.Text(
                                        '${fExibida.toStringAsFixed(2)} m',
                                        style: _estiloTextoDestaque,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 15),
                    // Diagrama E e F
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        children: [
                          if (imagemZlqEf != null)
                            pw.Image(imagemZlqEf, height: 5 * PdfPageFormat.cm)
                          else
                            pw.Container(
                              height: 5 * PdfPageFormat.cm,
                              color: _corFundoClaro,
                              child: pw.Center(
                                child: pw.Text(
                                  'Diagrama indisponível',
                                  style: _estiloLabel,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // === MEMÓRIA DE CÁLCULO ===
          _buildMemoriaCalculo(relatorio),

          // === OBSERVAÇÕES ===
          if (relatorio.observacoes.isNotEmpty) ...[
            pw.SizedBox(height: 15),
            _buildCard(
              titulo: 'Observações',
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Text(
                    relatorio.observacoes,
                    style: _estiloTextoNormal,
                  ),
                ),
              ],
            ),
          ],

          // === NOTAS TÉCNICAS ===
          _buildNotasTecnicas(),

          // === ASSINATURA ===
          pw.SizedBox(height: 20),
          _buildCard(
            titulo: 'Responsável pelo Relatório',
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildLinhaInfoPessoa(
                            'Nome',
                            relatorio.nomeUtilizador,
                          ),
                          _buildLinhaInfoPessoa(
                            'Matrícula',
                            relatorio.matriculaUtilizador,
                          ),
                          if (relatorio.empresaUtilizador.trim().isNotEmpty)
                            _buildLinhaInfoPessoa(
                              'Empresa',
                              relatorio.empresaUtilizador,
                            ),
                          _buildLinhaInfoPessoa(
                            kIsWeb ? 'Contato' : 'Email',
                            relatorio.emailUtilizador,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Assinatura Digital',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          if (assinaturaImg != null) ...[
                            pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: _corBorda),
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Image(
                                assinaturaImg,
                                height: 60,
                                fit: pw.BoxFit.contain,
                              ),
                            ),
                          ] else ...[
                            pw.Container(
                              height: 60,
                              width: 180,
                              decoration: pw.BoxDecoration(
                                color: _corFundoClaro,
                                border: pw.Border.all(color: _corBorda),
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  'Sem assinatura',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ];
      },
    ),
  );

  return pdf.save();
}
