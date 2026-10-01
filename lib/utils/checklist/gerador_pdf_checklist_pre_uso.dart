import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fall_calc_final/models/checklist/checklist_pre_uso.dart';
import 'package:fall_calc_final/utils/imagem_local.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const String _assetFooterLogo = 'assets/icones/FallCalc.png';
const String _footerText = kIsWeb
    ? 'Relatório realizado usando o FallCalc35 (versão web) - Versão completa disponível para Android'
    : 'Relatório realizado usando o FallCalc35 - Disponível na Google Play Store';

Future<pw.ImageProvider?> _loadAssetImage(String assetPath) async {
  try {
    final ByteData data = await rootBundle.load(assetPath);
    return pw.MemoryImage(data.buffer.asUint8List());
  } catch (e) {
    debugPrint(
      '[PDF Checklist][ERRO] Falha ao carregar asset "$assetPath": $e',
    );
    return null;
  }
}

Future<pw.ImageProvider?> _loadFileImage(String? filePath) async {
  if (filePath == null || filePath.isEmpty) return null;
  try {
    final bytes = await ImagemLocal.lerBytes(filePath);
    if (bytes == null) return null;
    return pw.MemoryImage(bytes);
  } catch (e) {
    debugPrint('[PDF Checklist][ERRO] Falha ao ler imagem "$filePath": $e');
    return null;
  }
}

pw.Widget _statusBadge(bool interditado) {
  if (interditado) {
    // Quando há não conformidades - mostrar aviso de proibição mais enfático
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.red100,
        border: pw.Border.all(color: PdfColors.red700, width: 2),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'EQUIPAMENTO INTERDITADO',
            style: pw.TextStyle(
              color: PdfColors.red900,
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.red700,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'USO PROIBIDO',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Foram identificadas NÃO CONFORMIDADES neste equipamento.\n'
            'O EQUIPAMENTO NÃO PODE SER UTILIZADO até que as irregularidades '
            'sejam corrigidas e uma nova inspeção seja realizada com resultado CONFORME.',
            style: const pw.TextStyle(color: PdfColors.red900, fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Quando conforme - mostrar liberação
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: pw.BoxDecoration(
      color: PdfColors.green50,
      border: pw.Border.all(color: PdfColors.green700, width: 1),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Text(
      'CONFORME - LIBERADO PARA INICIAR ATIVIDADE',
      style: pw.TextStyle(
        color: PdfColors.green800,
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
      textAlign: pw.TextAlign.center,
    ),
  );
}

pw.Widget _linhaResposta({
  required String pergunta,
  required ChecklistResposta? resposta,
}) {
  final opcao = resposta?.opcao?.code ?? '—';
  final obs = (resposta?.observacao ?? '').trim();

  // Layout mais compacto para reduzir páginas/consumo de papel.
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 26,
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            decoration: pw.BoxDecoration(
              color: opcao == 'NC' ? PdfColors.red50 : PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(
                color: opcao == 'NC' ? PdfColors.red400 : PdfColors.grey400,
              ),
            ),
            child: pw.Text(
              opcao,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: opcao == 'NC' ? PdfColors.red800 : PdfColors.black,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              pergunta,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
      if (obs.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 34),
          child: pw.Text('Obs: $obs', style: const pw.TextStyle(fontSize: 8)),
        ),
      ],
    ],
  );
}

Future<Uint8List?> _flattenPngOnWhite(Uint8List? pngBytes) async {
  if (pngBytes == null || pngBytes.isEmpty) return null;
  try {
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    );

    // Fundo branco para evitar que transparência vire preto no PDF.
    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      bgPaint,
    );
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());

    final picture = recorder.endRecording();
    final flattened = await picture.toImage(image.width, image.height);
    final byteData = await flattened.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } catch (e) {
    debugPrint('[PDF Checklist][ERRO] Falha ao tratar assinatura: $e');
    return pngBytes;
  }
}

pw.Widget _dadosUsuario({
  required String? nome,
  required String? matricula,
  required String? empresa,
  required String? email,
  required String? estado,
  required String? municipio,
}) {
  final rows = <pw.Widget>[];

  String line(String label, String? value) {
    final v = (value ?? '').trim();
    return v.isEmpty ? '' : '$label: $v';
  }

  final l1 = line('Nome', nome);
  final l2 = line('Matrícula', matricula);
  final l3 = line('Empresa', empresa);
  final l4 = line('Email', email);
  final l5 = line('UF', estado);
  final l6 = line('Município', municipio);

  for (final l in [l1, l2, l3, l4, l5, l6]) {
    if (l.isNotEmpty) {
      rows.add(pw.Text(l, style: const pw.TextStyle(fontSize: 8)));
    }
  }

  if (rows.isEmpty) return pw.SizedBox.shrink();

  return pw.Container(
    padding: const pw.EdgeInsets.all(6),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Dados do usuário',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        ...rows,
      ],
    ),
  );
}

Future<Uint8List> gerarPdfChecklistPreUso({
  required ChecklistPreUsoTemplate template,
  required ChecklistSection section,
  required Map<String, ChecklistResposta> respostas,
  required DateTime createdAt,
  required Uint8List? assinaturaPng,
  String? tipoInspecaoLabel,
  String? equipamentoTag,
  String? equipamentoFotoPath,
  String? nomeUsuario,
  String? matriculaUsuario,
  String? empresaUsuario,
  String? emailUsuario,
  String? estadoUsuario,
  String? municipioUsuario,
}) async {
  final interditado = respostas.values.any(
    (r) => r.opcao == ChecklistOpcao.naoConforme,
  );

  final equipamentoImg = await _loadFileImage(equipamentoFotoPath);

  final Map<String, pw.ImageProvider> imagensNc = {};
  for (final entry in respostas.entries) {
    final resp = entry.value;
    if (resp.opcao != ChecklistOpcao.naoConforme) continue;
    final img = await _loadFileImage(resp.fotoPath);
    if (img != null) {
      imagensNc[entry.key] = img;
    }
  }

  final pdf = pw.Document(
    compress: true,
    version: PdfVersion.pdf_1_5,
    title: 'Checklist de Pré-Uso',
    author: 'FallCalc',
    creator: 'FallCalc',
    subject: '${template.title} - ${section.title}',
    keywords: 'checklist, inspeção diária, pré-uso',
  );

  final formatador = DateFormat('dd/MM/yyyy HH:mm');
  final dataStr = formatador.format(createdAt);
  final tipoInspecaoStr = (tipoInspecaoLabel ?? '').trim();

  final assinaturaTratada = await _flattenPngOnWhite(assinaturaPng);
  final footerLogo = await _loadAssetImage(_assetFooterLogo);

  // Exibir todas as perguntas (inclusive NA), mas com layout compacto.
  final itensParaExibir = section.items;

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(18),
      footer: (context) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (footerLogo != null) ...[
                pw.Image(footerLogo, height: 14),
                pw.SizedBox(width: 8),
              ],
              pw.Expanded(
                child: pw.Text(
                  _footerText,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.left,
                ),
              ),
            ],
          ),
        );
      },
      build: (context) {
        return <pw.Widget>[
          pw.Header(
            level: 0,
            child: pw.Text(
              template.title,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Modelo: ${template.title} (v${template.version})',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Checklist: ${section.title}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          if (tipoInspecaoStr.isNotEmpty)
            pw.Text(
              'Tipo: $tipoInspecaoStr',
              style: const pw.TextStyle(fontSize: 9),
            ),
          if ((equipamentoTag ?? '').trim().isNotEmpty)
            pw.Text(
              'TAG: ${equipamentoTag!.trim()}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          pw.Text(
            'Data/Hora: $dataStr',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 8),
          _dadosUsuario(
            nome: nomeUsuario,
            matricula: matriculaUsuario,
            empresa: empresaUsuario,
            email: emailUsuario,
            estado: estadoUsuario,
            municipio: municipioUsuario,
          ),
          pw.SizedBox(height: 8),
          if (equipamentoImg != null) ...[
            pw.Text(
              'Foto do equipamento:',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Image(
                equipamentoImg,
                height: 90,
                fit: pw.BoxFit.contain,
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          _statusBadge(interditado),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, child: pw.Text('Itens')),
          pw.SizedBox(height: 6),
          for (final item in itensParaExibir) ...[
            _linhaResposta(pergunta: item.text, resposta: respostas[item.id]),
            if (respostas[item.id]?.opcao == ChecklistOpcao.naoConforme &&
                imagensNc[item.id] != null) ...[
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Foto NC:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Image(
                      imagensNc[item.id]!,
                      height: 110,
                      fit: pw.BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ],
            pw.SizedBox(height: 6),
          ],
          pw.SizedBox(height: 10),
          pw.Header(level: 1, child: pw.Text('Assinatura')),
          pw.SizedBox(height: 6),
          if (assinaturaTratada != null) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Image(
                pw.MemoryImage(assinaturaTratada),
                height: 70,
                fit: pw.BoxFit.contain,
              ),
            ),
          ] else ...[
            pw.Container(
              height: 70,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Center(
                child: pw.Text(
                  'Sem assinatura',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ),
          ],
        ];
      },
    ),
  );

  return pdf.save();
}

String encodePngToBase64(Uint8List png) => base64Encode(png);

Uint8List decodePngFromBase64(String b64) => base64Decode(b64);
