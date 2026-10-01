import 'dart:convert';
import 'dart:typed_data';

import 'package:fall_calc_final/models/checklist/checklist_inspecao_inicial_periodica.dart';
import 'package:fall_calc_final/models/checklist/checklist_pre_uso.dart';
import 'package:fall_calc_final/screens/fq_zlq/pagina_calculadora_fq_zlq.dart'
    show PaginaVisualizarPdf;
import 'package:fall_calc_final/utils/checklist/gerador_pdf_checklist_pre_uso.dart';
import 'package:fall_calc_final/utils/imagem_local.dart';
import 'package:fall_calc_final/widgets/bottom_navigation_widget.dart';
import 'package:fall_calc_final/widgets/checklist/signature_pad.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaginaInspecaoInicialPeriodica extends StatefulWidget {
  const PaginaInspecaoInicialPeriodica({super.key, this.checklistParaEditar});

  final ChecklistInspecaoInicialPeriodicaRegistro? checklistParaEditar;

  @override
  State<PaginaInspecaoInicialPeriodica> createState() =>
      _PaginaInspecaoInicialPeriodicaState();
}

class _PaginaInspecaoInicialPeriodicaState
    extends State<PaginaInspecaoInicialPeriodica> {
  static const _assetPath = 'assets/checklists/inspecao_inicial_periodica.json';
  static const _prefsKey = 'checklists_inspecao_inicial_periodica';

  static const List<String> _itensTravaQuedaDeslizanteIds = [
    'trava_queda_deslizante_01',
    'trava_queda_deslizante_02',
  ];

  ChecklistPreUsoTemplate? _template;
  bool _loading = true;
  String? _error;

  final Map<String, ChecklistResposta> _respostas = {};
  final Map<String, TextEditingController> _obsControllers = {};

  TipoInspecao _tipoInspecao = TipoInspecao.inicial;
  bool _travaQuedaDeslizante = false;

  final TextEditingController _tagController = TextEditingController();
  String? _equipamentoFotoPath;
  String? _selectedSectionId;

  final _signatureKey = GlobalKey<SignaturePadState>();
  Uint8List? _assinaturaPng;
  bool _assinando = false;

  final _picker = ImagePicker();

  DateTime _createdAt = DateTime.now();

  // ID do checklist sendo editado (null se for novo)
  String? _editandoId;

  bool get _isEditMode => _editandoId != null;

  ChecklistSection? get _selectedSection {
    final template = _template;
    final id = _selectedSectionId;
    if (template == null || id == null) return null;
    for (final s in template.sections) {
      if (s.id == id) return s;
    }
    return null;
  }

  bool get _interditado {
    final section = _selectedSection;
    if (section == null) return false;
    for (final item in _itensVisiveis(section)) {
      final r = _respostas[item.id];
      if (r?.opcao == ChecklistOpcao.naoConforme) return true;
    }
    return false;
  }

  bool get _isTravaQueda2bSelecionado => _selectedSectionId == 'trava_queda_2b';

  Iterable<ChecklistItem> _itensVisiveis(ChecklistSection section) {
    if (section.id == 'trava_queda_2b' && !_travaQuedaDeslizante) {
      return section.items.where(
        (i) => !_itensTravaQuedaDeslizanteIds.contains(i.id),
      );
    }
    return section.items;
  }

  void _setTravaQuedaDeslizante(bool enabled) {
    if (_travaQuedaDeslizante == enabled) return;

    setState(() {
      _travaQuedaDeslizante = enabled;

      if (!enabled) {
        // Evita ficar "interditado" por algo escondido.
        for (final id in _itensTravaQuedaDeslizanteIds) {
          _getObsController(id).text = '';
          final atual = _respostas[id] ?? const ChecklistResposta(opcao: null);
          _respostas[id] = atual.copyWith(
            opcao: ChecklistOpcao.naoSeAplica,
            clearObservacao: true,
            clearFoto: true,
          );
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _carregarTemplate();
  }

  void _preencherDadosEdicao() {
    final checklist = widget.checklistParaEditar;
    if (checklist == null || _template == null) return;

    _editandoId = checklist.id;
    _selectedSectionId = checklist.sectionId;
    _tagController.text = checklist.equipamentoTag ?? '';
    _equipamentoFotoPath = checklist.equipamentoFotoPath;
    _tipoInspecao = checklist.tipoInspecao;
    _travaQuedaDeslizante = checklist.travaQuedaDeslizante;
    _createdAt = DateTime.now(); // Atualiza data/hora ao editar

    // Preencher respostas e observações
    for (final entry in checklist.respostas.entries) {
      _respostas[entry.key] = entry.value;
      if (entry.value.observacao != null &&
          entry.value.observacao!.isNotEmpty) {
        _getObsController(entry.key).text = entry.value.observacao!;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _obsControllers.values) {
      c.dispose();
    }
    _tagController.dispose();
    super.dispose();
  }

  void _onSigningChanged(bool isSigning) {
    if (!mounted) return;
    setState(() {
      _assinando = isSigning;
    });
  }

  Future<void> _carregarTemplate() async {
    try {
      final jsonStr = await rootBundle.loadString(_assetPath);
      final template = ChecklistPreUsoTemplate.fromJsonString(jsonStr);

      setState(() {
        _template = template;
        _createdAt = DateTime.now();
        _selectedSectionId = null;
        _loading = false;
        _error = null;
      });

      // Se estiver editando, preencher os dados
      if (widget.checklistParaEditar != null) {
        _preencherDadosEdicao();
        setState(() {});
      }
    } catch (e) {
      setState(() {
        _error = 'Falha ao carregar checklist: $e';
        _loading = false;
      });
    }
  }

  TextEditingController _getObsController(String itemId) {
    return _obsControllers.putIfAbsent(itemId, () => TextEditingController());
  }

  void _onSelecionarChecklist(String? sectionId) {
    if (sectionId == null) return;

    final template = _template;
    final section = template?.sections
        .where((s) => s.id == sectionId)
        .cast<ChecklistSection?>()
        .first;

    for (final c in _obsControllers.values) {
      c.dispose();
    }

    setState(() {
      _selectedSectionId = sectionId;
      _respostas.clear();
      _obsControllers.clear();
      _assinaturaPng = null;
      _createdAt = DateTime.now();
      _travaQuedaDeslizante = false;

      // Por padrão, todos os itens começam como NA (não se aplica).
      // O usuário só altera o que for C ou NC.
      if (section != null) {
        for (final item in section.items) {
          _respostas[item.id] = const ChecklistResposta(
            opcao: ChecklistOpcao.naoSeAplica,
          );
        }
      }
    });

    _signatureKey.currentState?.clear();
  }

  void _setOpcao(String itemId, ChecklistOpcao opcao) {
    final atual = _respostas[itemId] ?? const ChecklistResposta(opcao: null);

    if (opcao != ChecklistOpcao.naoConforme) {
      _getObsController(itemId).text = '';
      setState(() {
        _respostas[itemId] = atual.copyWith(
          opcao: opcao,
          clearObservacao: true,
          clearFoto: true,
        );
      });
      return;
    }

    setState(() {
      _respostas[itemId] = atual.copyWith(opcao: opcao);
    });
  }

  Future<void> _tirarFoto(String itemId) async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (xfile == null) return;

      final caminho = await ImagemLocal.registrar(xfile);
      if (!mounted) return;
      final atual = _respostas[itemId] ?? const ChecklistResposta(opcao: null);
      setState(() {
        _respostas[itemId] = atual.copyWith(fotoPath: caminho);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir a câmera: $e')),
      );
    }
  }

  Future<void> _tirarFotoEquipamento() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (xfile == null) return;

      final caminho = await ImagemLocal.registrar(xfile);
      if (!mounted) return;
      setState(() {
        _equipamentoFotoPath = caminho;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir a câmera: $e')),
      );
    }
  }

  void _removerFotoEquipamento() {
    setState(() {
      _equipamentoFotoPath = null;
    });
  }

  Future<void> _capturarAssinatura() async {
    final png = await _signatureKey.currentState?.exportPng();
    setState(() {
      _assinaturaPng = png;
    });
  }

  bool _validarObservacoesNc() {
    final section = _selectedSection;
    if (section == null) return false;

    bool ok = true;
    for (final item in _itensVisiveis(section)) {
      final resp = _respostas[item.id];
      if (resp?.opcao == ChecklistOpcao.naoConforme) {
        final obs = _getObsController(item.id).text.trim();
        if (obs.isEmpty) ok = false;
      }
    }
    return ok;
  }

  bool _temChecklistSelecionado() {
    return _selectedSection != null;
  }

  Future<void> _salvar() async {
    if (_template == null) return;
    final section = _selectedSection;
    if (section == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione qual checklist deseja fazer.')),
      );
      return;
    }

    final equipamentoTag = _tagController.text.trim();
    if (equipamentoTag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha a TAG do equipamento.')),
      );
      return;
    }

    if (!_validarObservacoesNc()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha a observação obrigatória nos itens NC.'),
        ),
      );
      return;
    }

    await _capturarAssinatura();

    if (_assinaturaPng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A assinatura é obrigatória para salvar o checklist.'),
        ),
      );
      return;
    }

    final Set<String> itemIdsDaSecao = _itensVisiveis(
      section,
    ).map((i) => i.id).toSet();
    final respostasDaSecao = _respostas.entries
        .where((e) => itemIdsDaSecao.contains(e.key))
        .map((e) => MapEntry(e.key, e.value))
        .toList(growable: false);

    // Se estiver editando, usa o ID existente; caso contrário, gera novo
    final registroId =
        _editandoId ?? 'inspecao_${_createdAt.millisecondsSinceEpoch}';

    final registro = ChecklistInspecaoInicialPeriodicaRegistro(
      id: registroId,
      templateId: _template!.id,
      templateVersion: _template!.version,
      templateTitle: _template!.title,
      sectionId: section.id,
      sectionTitle: section.title,
      tipoInspecao: _tipoInspecao,
      travaQuedaDeslizante: _isTravaQueda2bSelecionado && _travaQuedaDeslizante,
      equipamentoTag: equipamentoTag.isEmpty ? null : equipamentoTag,
      equipamentoFotoPath: _equipamentoFotoPath,
      createdAt: _createdAt,
      interditado: _interditado,
      assinaturaBase64Png: _assinaturaPng == null
          ? null
          : encodePngToBase64(_assinaturaPng!),
      respostas: Map<String, ChecklistResposta>.fromEntries(
        respostasDaSecao.map((e) {
          final k = e.key;
          final v = e.value;
          final obsText = _getObsController(k).text.trim();
          if (v.opcao == ChecklistOpcao.naoConforme) {
            return MapEntry(k, v.copyWith(observacao: obsText));
          }
          return MapEntry(k, v);
        }),
      ),
      rascunho: false, // Ao salvar com assinatura, não é mais rascunho
    );

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];

    // Se estiver editando, remove o registro antigo antes de adicionar o novo
    if (_isEditMode) {
      list.removeWhere((jsonString) {
        try {
          final existente = ChecklistInspecaoInicialPeriodicaRegistro.fromJson(
            jsonDecode(jsonString),
          );
          return existente.id == _editandoId;
        } catch (e) {
          return false;
        }
      });
    }

    list.add(jsonEncode(registro.toJson()));
    await prefs.setStringList(_prefsKey, list);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditMode
              ? 'Inspeção atualizada com sucesso.'
              : 'Inspeção salva com sucesso.',
        ),
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _gerarPdf() async {
    if (_template == null) return;
    final section = _selectedSection;
    if (section == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione qual checklist deseja fazer.')),
      );
      return;
    }

    final equipamentoTag = _tagController.text.trim();
    if (equipamentoTag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha a TAG do equipamento.')),
      );
      return;
    }

    if (!_validarObservacoesNc()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha a observação obrigatória nos itens NC.'),
        ),
      );
      return;
    }

    await _capturarAssinatura();

    if (_assinaturaPng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A assinatura é obrigatória para gerar o PDF.'),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final nomeUsuario = prefs.getString('nome');
    final matriculaUsuario = prefs.getString('matricula');
    final empresaUsuario = prefs.getString('empresa');
    final emailUsuario = prefs.getString('email');
    final estadoUsuario = prefs.getString('estado');
    final municipioUsuario = prefs.getString('municipio');

    final Set<String> itemIdsDaSecao = _itensVisiveis(
      section,
    ).map((i) => i.id).toSet();
    final respostasComObs = <String, ChecklistResposta>{};
    for (final entry in _respostas.entries) {
      if (!itemIdsDaSecao.contains(entry.key)) continue;
      final k = entry.key;
      final v = entry.value;
      final obsText = _getObsController(k).text.trim();
      if (v.opcao == ChecklistOpcao.naoConforme) {
        respostasComObs[k] = v.copyWith(observacao: obsText);
      } else {
        respostasComObs[k] = v;
      }
    }

    final sectionVisivel = ChecklistSection(
      id: section.id,
      title: section.title,
      items: _itensVisiveis(section).toList(growable: false),
    );

    final bytes = await gerarPdfChecklistPreUso(
      template: _template!,
      section: sectionVisivel,
      respostas: respostasComObs,
      createdAt: _createdAt,
      assinaturaPng: _assinaturaPng,
      equipamentoTag: _tagController.text.trim(),
      equipamentoFotoPath: _equipamentoFotoPath,
      nomeUsuario: nomeUsuario,
      matriculaUsuario: matriculaUsuario,
      empresaUsuario: empresaUsuario,
      emailUsuario: emailUsuario,
      estadoUsuario: estadoUsuario,
      municipioUsuario: municipioUsuario,
      tipoInspecaoLabel: _tipoInspecao.label,
    );

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaginaVisualizarPdf(pdfBytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BottomNavigationWidget(currentIndex: 0),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inspeção Inicial e Periódica')),
        body: Center(child: Text(_error!)),
        bottomNavigationBar: const BottomNavigationWidget(currentIndex: 0),
      );
    }

    final template = _template!;
    final selectedSection = _selectedSection;
    final canActions = _temChecklistSelecionado();

    final appBarTitle = _isEditMode
        ? 'Editar Inspeção'
        : 'Inspeção Inicial e Periódica';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle), elevation: 4),
      body: Column(
        children: [
          if (_interditado)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: colorScheme.error,
              child: Text(
                'Equipamento Interditado - Não Iniciar Atividade',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onError,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView(
              physics: _assinando ? const NeverScrollableScrollPhysics() : null,
              padding: const EdgeInsets.all(16),
              children: [
                _SelecaoChecklistInspecaoCard(
                  sections: template.sections,
                  selectedId: _selectedSectionId,
                  tipoInspecao: _tipoInspecao,
                  onTipoInspecaoChanged: (t) {
                    if (t == null) return;
                    setState(() => _tipoInspecao = t);
                  },
                  tagController: _tagController,
                  equipamentoFotoPath: _equipamentoFotoPath,
                  onChanged: _onSelecionarChecklist,
                  onTirarFotoEquipamento: _tirarFotoEquipamento,
                  onRemoverFotoEquipamento: _removerFotoEquipamento,
                  isEditMode: _isEditMode,
                ),
                const SizedBox(height: 12),
                if (selectedSection == null) ...[
                  Text(
                    'Selecione qual checklist deseja preencher para começar.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  _SectionHeader(title: selectedSection.title),
                  const SizedBox(height: 8),
                  if (_isTravaQueda2bSelecionado) ...[
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: const Text('Trava-quedas deslizante?'),
                        subtitle: const Text(
                          'Ao ativar, exibe itens específicos do deslizante.',
                        ),
                        value: _travaQuedaDeslizante,
                        onChanged: (v) => _setTravaQuedaDeslizante(v),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  for (final item in _itensVisiveis(selectedSection)) ...[
                    _ChecklistItemCard(
                      item: item,
                      resposta: _respostas[item.id],
                      obsController: _getObsController(item.id),
                      onOpcaoChanged: (opcao) => _setOpcao(item.id, opcao),
                      onTirarFoto: () => _tirarFoto(item.id),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_isTravaQueda2bSelecionado && _travaQuedaDeslizante) ...[
                    _SectionHeader(
                      title:
                          'ITENS ESPECÍFICOS TRAVA QUEDA DESLIZANTE (incluindo itens acima)',
                    ),
                    const SizedBox(height: 8),
                    for (final item in selectedSection.items.where(
                      (i) => _itensTravaQuedaDeslizanteIds.contains(i.id),
                    )) ...[
                      _ChecklistItemCard(
                        item: item,
                        resposta: _respostas[item.id],
                        obsController: _getObsController(item.id),
                        onOpcaoChanged: (opcao) => _setOpcao(item.id, opcao),
                        onTirarFoto: () => _tirarFoto(item.id),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
                const SizedBox(height: 10),
                if (selectedSection != null)
                  SignaturePad(
                    key: _signatureKey,
                    height: 160,
                    onSigningChanged: _onSigningChanged,
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (!kIsWeb) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: canActions ? _salvar : null,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar/Continuar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: kIsWeb
                          ? ElevatedButton.icon(
                              onPressed: canActions ? _gerarPdf : null,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Gerar PDF'),
                            )
                          : OutlinedButton.icon(
                              onPressed: canActions ? _gerarPdf : null,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Gerar PDF'),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 0),
    );
  }
}

class _SelecaoChecklistInspecaoCard extends StatelessWidget {
  const _SelecaoChecklistInspecaoCard({
    required this.sections,
    required this.selectedId,
    required this.tipoInspecao,
    required this.onTipoInspecaoChanged,
    required this.tagController,
    required this.equipamentoFotoPath,
    required this.onChanged,
    required this.onTirarFotoEquipamento,
    required this.onRemoverFotoEquipamento,
    this.isEditMode = false,
  });

  final List<ChecklistSection> sections;
  final String? selectedId;
  final TipoInspecao tipoInspecao;
  final ValueChanged<TipoInspecao?> onTipoInspecaoChanged;
  final TextEditingController tagController;
  final String? equipamentoFotoPath;
  final ValueChanged<String?> onChanged;
  final VoidCallback onTirarFotoEquipamento;
  final VoidCallback onRemoverFotoEquipamento;
  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuração',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Tipo de inspeção',
                border: const OutlineInputBorder(),
                filled: isEditMode,
                fillColor: isEditMode
                    ? colorScheme.surfaceContainerHighest
                    : null,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Inicial'),
                    selected: tipoInspecao == TipoInspecao.inicial,
                    onSelected: isEditMode
                        ? null
                        : (v) => onTipoInspecaoChanged(
                            v ? TipoInspecao.inicial : tipoInspecao,
                          ),
                  ),
                  ChoiceChip(
                    label: const Text('Periódica'),
                    selected: tipoInspecao == TipoInspecao.periodica,
                    onSelected: isEditMode
                        ? null
                        : (v) => onTipoInspecaoChanged(
                            v ? TipoInspecao.periodica : tipoInspecao,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Selecione o checklist',
                border: const OutlineInputBorder(),
                filled: isEditMode,
                fillColor: isEditMode
                    ? colorScheme.surfaceContainerHighest
                    : null,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedId,
                  hint: const Text('Selecione...'),
                  items: [
                    for (final s in sections)
                      DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(s.title),
                      ),
                  ],
                  onChanged: isEditMode ? null : onChanged,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagController,
              decoration: const InputDecoration(
                labelText: 'TAG do equipamento (obrigatório)',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTirarFotoEquipamento,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Inserir foto do equipamento'),
                  ),
                ),
                const SizedBox(width: 10),
                if ((equipamentoFotoPath ?? '').isNotEmpty)
                  IconButton(
                    onPressed: onRemoverFotoEquipamento,
                    tooltip: 'Remover foto',
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            if ((equipamentoFotoPath ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ImagemLocal.widget(
                  equipamentoFotoPath!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) {
                    return Container(
                      height: 160,
                      alignment: Alignment.center,
                      color: colorScheme.surfaceContainerHighest,
                      child: Text(
                        'Não foi possível carregar a foto.',
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.checklist, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItemCard extends StatelessWidget {
  const _ChecklistItemCard({
    required this.item,
    required this.resposta,
    required this.obsController,
    required this.onOpcaoChanged,
    required this.onTirarFoto,
  });

  final ChecklistItem item;
  final ChecklistResposta? resposta;
  final TextEditingController obsController;
  final ValueChanged<ChecklistOpcao> onOpcaoChanged;
  final VoidCallback onTirarFoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final opcao = resposta?.opcao;
    final isNc = opcao == ChecklistOpcao.naoConforme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.text, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _opcaoChip(
                  context,
                  label: 'C',
                  selected: opcao == ChecklistOpcao.conforme,
                  onTap: () => onOpcaoChanged(ChecklistOpcao.conforme),
                ),
                _opcaoChip(
                  context,
                  label: 'NC',
                  selected: opcao == ChecklistOpcao.naoConforme,
                  onTap: () => onOpcaoChanged(ChecklistOpcao.naoConforme),
                ),
                _opcaoChip(
                  context,
                  label: 'NA',
                  selected: opcao == ChecklistOpcao.naoSeAplica,
                  onTap: () => onOpcaoChanged(ChecklistOpcao.naoSeAplica),
                ),
              ],
            ),
            if (isNc) ...[
              const SizedBox(height: 12),
              TextField(
                controller: obsController,
                decoration: const InputDecoration(
                  labelText: 'Observação (obrigatória)',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTirarFoto,
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Tirar Foto'),
                    ),
                  ),
                ],
              ),
              if ((resposta?.fotoPath ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ImagemLocal.widget(
                    resposta!.fotoPath!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      return Container(
                        height: 160,
                        alignment: Alignment.center,
                        color: colorScheme.surfaceContainerHighest,
                        child: Text(
                          'Não foi possível carregar a foto.',
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
            if (!isNc && opcao == null) ...[
              const SizedBox(height: 8),
              Text(
                'Selecione uma opção: C / NC / NA',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withAlpha(160),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _opcaoChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final bg = selected
        ? colorScheme.primary.withAlpha(25)
        : colorScheme.surfaceContainerHighest;
    final fg = selected ? colorScheme.primary : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colorScheme.outline.withAlpha(120)),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: fg),
        ),
      ),
    );
  }
}
