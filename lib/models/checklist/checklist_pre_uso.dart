import 'dart:convert';

enum ChecklistOpcao { conforme, naoConforme, naoSeAplica }

extension ChecklistOpcaoX on ChecklistOpcao {
  String get code {
    switch (this) {
      case ChecklistOpcao.conforme:
        return 'C';
      case ChecklistOpcao.naoConforme:
        return 'NC';
      case ChecklistOpcao.naoSeAplica:
        return 'NA';
    }
  }

  static ChecklistOpcao? fromCode(String? code) {
    switch (code) {
      case 'C':
        return ChecklistOpcao.conforme;
      case 'NC':
        return ChecklistOpcao.naoConforme;
      case 'NA':
        return ChecklistOpcao.naoSeAplica;
      default:
        return null;
    }
  }
}

class ChecklistPreUsoTemplate {
  final String id;
  final String title;
  final int version;
  final List<ChecklistSection> sections;

  const ChecklistPreUsoTemplate({
    required this.id,
    required this.title,
    required this.version,
    required this.sections,
  });

  factory ChecklistPreUsoTemplate.fromJson(Map<String, dynamic> json) {
    return ChecklistPreUsoTemplate(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      version: (json['version'] ?? 1) as int,
      sections: ((json['sections'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map(ChecklistSection.fromJson)
          .toList(),
    );
  }

  static ChecklistPreUsoTemplate fromJsonString(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return ChecklistPreUsoTemplate.fromJson(map);
  }

  List<ChecklistItem> get allItems {
    return [for (final s in sections) ...s.items];
  }
}

class ChecklistSection {
  final String id;
  final String title;
  final List<ChecklistItem> items;

  const ChecklistSection({
    required this.id,
    required this.title,
    required this.items,
  });

  factory ChecklistSection.fromJson(Map<String, dynamic> json) {
    return ChecklistSection(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      items: ((json['items'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map(ChecklistItem.fromJson)
          .toList(),
    );
  }
}

class ChecklistItem {
  final String id;
  final String text;

  const ChecklistItem({required this.id, required this.text});

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: (json['id'] ?? '') as String,
      text: (json['text'] ?? '') as String,
    );
  }
}

class ChecklistResposta {
  final ChecklistOpcao? opcao;
  final String? observacao;
  final String? fotoPath;

  const ChecklistResposta({
    required this.opcao,
    this.observacao,
    this.fotoPath,
  });

  bool get isNc => opcao == ChecklistOpcao.naoConforme;

  ChecklistResposta copyWith({
    ChecklistOpcao? opcao,
    String? observacao,
    String? fotoPath,
    bool clearObservacao = false,
    bool clearFoto = false,
  }) {
    return ChecklistResposta(
      opcao: opcao ?? this.opcao,
      observacao: clearObservacao ? null : (observacao ?? this.observacao),
      fotoPath: clearFoto ? null : (fotoPath ?? this.fotoPath),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opcao': opcao?.code,
      'observacao': observacao,
      'fotoPath': fotoPath,
    };
  }

  factory ChecklistResposta.fromJson(Map<String, dynamic> json) {
    return ChecklistResposta(
      opcao: ChecklistOpcaoX.fromCode(json['opcao'] as String?),
      observacao: json['observacao'] as String?,
      fotoPath: json['fotoPath'] as String?,
    );
  }
}

class ChecklistPreUsoRegistro {
  final String id; // Identificador único do registro
  final String templateId;
  final int templateVersion;
  final String templateTitle;
  final String sectionId;
  final String sectionTitle;
  final String? equipamentoTag;
  final String? equipamentoFotoPath;
  final DateTime createdAt;
  final bool interditado;
  final Map<String, ChecklistResposta> respostas;
  final String? assinaturaBase64Png;
  final bool rascunho; // true = rascunho editável, false = relatório finalizado

  const ChecklistPreUsoRegistro({
    required this.id,
    required this.templateId,
    required this.templateVersion,
    required this.templateTitle,
    required this.sectionId,
    required this.sectionTitle,
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
      'equipamentoTag': equipamentoTag,
      'equipamentoFotoPath': equipamentoFotoPath,
      'createdAt': createdAt.toIso8601String(),
      'interditado': interditado,
      'assinaturaBase64Png': assinaturaBase64Png,
      'respostas': respostas.map((k, v) => MapEntry(k, v.toJson())),
      'rascunho': rascunho,
    };
  }

  factory ChecklistPreUsoRegistro.fromJson(Map<String, dynamic> json) {
    final respostasRaw =
        (json['respostas'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    // Gera ID a partir do createdAt para compatibilidade com registros antigos
    final createdAt =
        DateTime.tryParse((json['createdAt'] ?? '') as String) ??
        DateTime.now();
    final id =
        (json['id'] as String?) ??
        'checklist_${createdAt.millisecondsSinceEpoch}';

    return ChecklistPreUsoRegistro(
      id: id,
      templateId: (json['templateId'] ?? '') as String,
      templateVersion: (json['templateVersion'] ?? 1) as int,
      templateTitle: (json['templateTitle'] ?? '') as String,
      sectionId: (json['sectionId'] ?? '') as String,
      sectionTitle: (json['sectionTitle'] ?? '') as String,
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

  /// Cria uma cópia do registro com os campos especificados alterados
  ChecklistPreUsoRegistro copyWith({
    String? id,
    String? templateId,
    int? templateVersion,
    String? templateTitle,
    String? sectionId,
    String? sectionTitle,
    String? equipamentoTag,
    String? equipamentoFotoPath,
    DateTime? createdAt,
    bool? interditado,
    Map<String, ChecklistResposta>? respostas,
    String? assinaturaBase64Png,
    bool? rascunho,
    bool clearAssinatura = false,
  }) {
    return ChecklistPreUsoRegistro(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      templateVersion: templateVersion ?? this.templateVersion,
      templateTitle: templateTitle ?? this.templateTitle,
      sectionId: sectionId ?? this.sectionId,
      sectionTitle: sectionTitle ?? this.sectionTitle,
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
