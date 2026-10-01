import 'dart:convert';

import 'package:fall_calc_final/models/checklist/checklist_pre_uso.dart'
    show ChecklistResposta;

enum TipoInspecao { inicial, periodica }

extension TipoInspecaoX on TipoInspecao {
  String get code {
    switch (this) {
      case TipoInspecao.inicial:
        return 'INICIAL';
      case TipoInspecao.periodica:
        return 'PERIÓDICA';
    }
  }

  String get label {
    switch (this) {
      case TipoInspecao.inicial:
        return 'Inspeção Inicial';
      case TipoInspecao.periodica:
        return 'Inspeção Periódica';
    }
  }

  static TipoInspecao fromJson(dynamic value) {
    final v = (value ?? '').toString().trim().toLowerCase();
    if (v == 'periodica' || v == 'periódica') return TipoInspecao.periodica;
    if (v == 'inicial') return TipoInspecao.inicial;

    // fallback: aceita códigos antigos/variantes
    if (v.contains('per')) return TipoInspecao.periodica;
    return TipoInspecao.inicial;
  }

  String toJson() {
    switch (this) {
      case TipoInspecao.inicial:
        return 'inicial';
      case TipoInspecao.periodica:
        return 'periodica';
    }
  }
}

class ChecklistInspecaoInicialPeriodicaRegistro {
  final String id; // Identificador único do registro
  final String templateId;
  final int templateVersion;
  final String templateTitle;
  final String sectionId;
  final String sectionTitle;
  final TipoInspecao tipoInspecao;
  final bool travaQuedaDeslizante;
  final String? equipamentoTag;
  final String? equipamentoFotoPath;
  final DateTime createdAt;
  final bool interditado;
  final Map<String, ChecklistResposta> respostas;
  final String? assinaturaBase64Png;
  final bool rascunho; // true = rascunho editável, false = relatório finalizado

  const ChecklistInspecaoInicialPeriodicaRegistro({
    required this.id,
    required this.templateId,
    required this.templateVersion,
    required this.templateTitle,
    required this.sectionId,
    required this.sectionTitle,
    required this.tipoInspecao,
    required this.travaQuedaDeslizante,
    required this.equipamentoTag,
    required this.equipamentoFotoPath,
    required this.createdAt,
    required this.interditado,
    required this.respostas,
    required this.assinaturaBase64Png,
    this.rascunho = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'templateVersion': templateVersion,
      'templateTitle': templateTitle,
      'sectionId': sectionId,
      'sectionTitle': sectionTitle,
      'tipoInspecao': tipoInspecao.toJson(),
      'travaQuedaDeslizante': travaQuedaDeslizante,
      'equipamentoTag': equipamentoTag,
      'equipamentoFotoPath': equipamentoFotoPath,
      'createdAt': createdAt.toIso8601String(),
      'interditado': interditado,
      'assinaturaBase64Png': assinaturaBase64Png,
      'respostas': respostas.map((k, v) => MapEntry(k, v.toJson())),
      'rascunho': rascunho,
    };
  }

  factory ChecklistInspecaoInicialPeriodicaRegistro.fromJson(
    Map<String, dynamic> json,
  ) {
    final respostasRaw =
        (json['respostas'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    // Gera ID a partir do createdAt para compatibilidade com registros antigos
    final createdAt =
        DateTime.tryParse((json['createdAt'] ?? '') as String) ??
        DateTime.now();
    final id =
        (json['id'] as String?) ??
        'inspecao_${createdAt.millisecondsSinceEpoch}';

    return ChecklistInspecaoInicialPeriodicaRegistro(
      id: id,
      templateId: (json['templateId'] ?? '') as String,
      templateVersion: (json['templateVersion'] ?? 1) as int,
      templateTitle: (json['templateTitle'] ?? '') as String,
      sectionId: (json['sectionId'] ?? '') as String,
      sectionTitle: (json['sectionTitle'] ?? '') as String,
      tipoInspecao: TipoInspecaoX.fromJson(json['tipoInspecao']),
      travaQuedaDeslizante: (json['travaQuedaDeslizante'] ?? false) as bool,
      equipamentoTag: json['equipamentoTag'] as String?,
      equipamentoFotoPath: json['equipamentoFotoPath'] as String?,
      createdAt: createdAt,
      interditado: (json['interditado'] ?? false) as bool,
      assinaturaBase64Png: json['assinaturaBase64Png'] as String?,
      respostas: respostasRaw.map(
        (k, v) => MapEntry(
          k,
          ChecklistResposta.fromJson((v as Map).cast<String, dynamic>()),
        ),
      ),
      rascunho: (json['rascunho'] ?? false) as bool,
    );
  }

  static ChecklistInspecaoInicialPeriodicaRegistro fromJsonString(
    String jsonString,
  ) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return ChecklistInspecaoInicialPeriodicaRegistro.fromJson(map);
  }

  /// Cria uma cópia do registro com os campos especificados alterados
  ChecklistInspecaoInicialPeriodicaRegistro copyWith({
    String? id,
    String? templateId,
    int? templateVersion,
    String? templateTitle,
    String? sectionId,
    String? sectionTitle,
    TipoInspecao? tipoInspecao,
    bool? travaQuedaDeslizante,
    String? equipamentoTag,
    String? equipamentoFotoPath,
    DateTime? createdAt,
    bool? interditado,
    Map<String, ChecklistResposta>? respostas,
    String? assinaturaBase64Png,
    bool? rascunho,
    bool clearAssinatura = false,
  }) {
    return ChecklistInspecaoInicialPeriodicaRegistro(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      templateVersion: templateVersion ?? this.templateVersion,
      templateTitle: templateTitle ?? this.templateTitle,
      sectionId: sectionId ?? this.sectionId,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      tipoInspecao: tipoInspecao ?? this.tipoInspecao,
      travaQuedaDeslizante: travaQuedaDeslizante ?? this.travaQuedaDeslizante,
      equipamentoTag: equipamentoTag ?? this.equipamentoTag,
      equipamentoFotoPath: equipamentoFotoPath ?? this.equipamentoFotoPath,
      createdAt: createdAt ?? this.createdAt,
      interditado: interditado ?? this.interditado,
      respostas: respostas ?? this.respostas,
      assinaturaBase64Png: clearAssinatura
          ? null
          : (assinaturaBase64Png ?? this.assinaturaBase64Png),
      rascunho: rascunho ?? this.rascunho,
    );
  }
}
