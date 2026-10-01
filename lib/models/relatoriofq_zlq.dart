// lib/models/relatorio.dart
import 'package:intl/intl.dart';

class Relatorio {
  final String id;
  final String nomeUtilizador;
  final String matriculaUtilizador;
  final String empresaUtilizador;
  final String emailUtilizador;
  final String localAtividade;
  final String? caminhoImagem;
  final String? caminhoImagem2; // Segunda imagem opcional
  final DateTime dataHora;
  String? caminhoPdf;

  // Campos para os parâmetros de cálculo
  final double alturaAncoragem;
  final double compTalabarte;
  final double estAbsorvedor;
  final double distPes;
  final bool usaTravaQuedas;
  final bool incluiDeformacaoCinto;
  final bool usaLinhaVidaHorizontal; // Linha de vida horizontal
  final double flechaProjeto; // Flecha de projeto da linha de vida

  // Campos para os resultados do cálculo
  final double fq;
  final double zlqAncoragem;
  final double zlqPes;
  final String mensagemAlertaFQ;
  final String observacoes; // Campo opcional de observações
  final String? assinaturaBase64Png; // Assinatura digital em base64

  Relatorio({
    required this.id,
    required this.nomeUtilizador,
    required this.matriculaUtilizador,
    required this.empresaUtilizador,
    required this.emailUtilizador,
    required this.localAtividade,
    this.caminhoImagem,
    this.caminhoImagem2,
    required this.dataHora,
    this.caminhoPdf,
    required this.alturaAncoragem,
    required this.compTalabarte,
    required this.estAbsorvedor,
    required this.distPes,
    required this.usaTravaQuedas,
    required this.incluiDeformacaoCinto,
    this.usaLinhaVidaHorizontal = false,
    this.flechaProjeto = 0.0,
    required this.fq,
    required this.zlqAncoragem,
    required this.zlqPes,
    required this.mensagemAlertaFQ,
    this.observacoes = '', // Campo opcional de observações
    this.assinaturaBase64Png, // Assinatura digital
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomeUtilizador': nomeUtilizador,
      'matriculaUtilizador': matriculaUtilizador,
      'empresaUtilizador': empresaUtilizador,
      'emailUtilizador': emailUtilizador,
      'localAtividade': localAtividade,
      'caminhoImagem': caminhoImagem,
      'caminhoImagem2': caminhoImagem2,
      'dataHora': dataHora.toIso8601String(),
      'caminhoPdf': caminhoPdf,
      'alturaAncoragem': alturaAncoragem,
      'compTalabarte': compTalabarte,
      'estAbsorvedor': estAbsorvedor,
      'distPes': distPes,
      'usaTravaQuedas': usaTravaQuedas,
      'incluiDeformacaoCinto': incluiDeformacaoCinto,
      'usaLinhaVidaHorizontal': usaLinhaVidaHorizontal,
      'flechaProjeto': flechaProjeto,
      'fq': fq,
      'zlqAncoragem': zlqAncoragem,
      'zlqPes': zlqPes,
      'mensagemAlertaFQ': mensagemAlertaFQ,
      'observacoes': observacoes,
      'assinaturaBase64Png': assinaturaBase64Png,
    };
  }

  // Função auxiliar para parse flexível de data (Ordem otimizada)
  static DateTime _parseDataFlexivel(String? dataString) {
    if (dataString == null) return DateTime.now();
    try {
      // Tentativa 1: Parsear o formato novo (ISO 8601)
      return DateTime.parse(dataString);
    } catch (e) {
      try {
        // Tentativa 2: Parsear o formato antigo (ex: "dd/MM/yyyy HH:mm") como fallback.
        return DateFormat('dd/MM/yyyy HH:mm').parse(dataString);
      } catch (e2) {
        // Fallback final se ambos falharem
        return DateTime.now();
      }
    }
  }

  factory Relatorio.fromJson(Map<String, dynamic> map) {
    return Relatorio(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nomeUtilizador: map['nomeUtilizador'] ?? 'N/A',
      matriculaUtilizador: map['matriculaUtilizador'] ?? 'N/A',
      empresaUtilizador: map['empresaUtilizador'] ?? 'N/A',
      emailUtilizador: map['emailUtilizador'] ?? '',
      localAtividade: map['localAtividade'] ?? 'Atividade Desconhecida',
      dataHora: _parseDataFlexivel(map['dataHora'] as String?),
      caminhoImagem: map['caminhoImagem'],
      caminhoImagem2: map['caminhoImagem2'],
      caminhoPdf: map['caminhoPdf'],
      alturaAncoragem: (map['alturaAncoragem'] as num?)?.toDouble() ?? 0.0,
      compTalabarte: (map['compTalabarte'] as num?)?.toDouble() ?? 0.0,
      estAbsorvedor: (map['estAbsorvedor'] as num?)?.toDouble() ?? 0.0,
      distPes: (map['distPes'] as num?)?.toDouble() ?? 0.0,
      fq: (map['fq'] as num?)?.toDouble() ?? 0.0,
      zlqAncoragem: (map['zlqAncoragem'] as num?)?.toDouble() ?? 0.0,
      zlqPes: (map['zlqPes'] as num?)?.toDouble() ?? 0.0,
      usaTravaQuedas: map['usaTravaQuedas'] ?? false,
      incluiDeformacaoCinto: map['incluiDeformacaoCinto'] ?? false,
      usaLinhaVidaHorizontal: map['usaLinhaVidaHorizontal'] ?? false,
      flechaProjeto: (map['flechaProjeto'] as num?)?.toDouble() ?? 0.0,
      mensagemAlertaFQ: map['mensagemAlertaFQ'] ?? '',
      observacoes: map['observacoes'] ?? '',
      assinaturaBase64Png: map['assinaturaBase64Png'],
    );
  }
}
