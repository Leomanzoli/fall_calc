// lib/screens/pagina_relatorios.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'package:fall_calc_final/models/relatoriofq_zlq.dart';
import 'package:fall_calc_final/models/checklist/checklist_pre_uso.dart';
import 'package:fall_calc_final/models/checklist/checklist_inspecao_inicial_periodica.dart';
import 'package:fall_calc_final/screens/checklist/pagina_detalhe_checklist_pre_uso.dart';
import 'package:fall_calc_final/screens/checklist/pagina_detalhe_inspecao_inicial_periodica.dart';
import 'package:fall_calc_final/screens/fq_zlq/pagina_calculadora_fq_zlq.dart'
    show PaginaCalculadora, PaginaVisualizarPdf;
import 'package:fall_calc_final/screens/fq_zlq/pagina_detalhe_relatorio_fq_zlq.dart';
import 'package:fall_calc_final/utils/checklist/gerador_pdf_checklist_pre_uso.dart';
import 'package:fall_calc_final/widgets/bottom_navigation_widget.dart';

class PaginaRelatorios extends StatefulWidget {
  const PaginaRelatorios({super.key});

  @override
  State<PaginaRelatorios> createState() => _PaginaRelatoriosState();
}

class _PaginaRelatoriosState extends State<PaginaRelatorios> {
  List<Relatorio> _relatorios = [];
  List<ChecklistPreUsoRegistro> _checklists = [];
  List<ChecklistInspecaoInicialPeriodicaRegistro> _inspecoes = [];
  Map<String, List<dynamic>> _groupedFilteredRelatorios = {};
  bool _isSelectionMode = false;
  final Set<String> _selectedReportIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  Set<String> _getAllSelectableIdsInCurrentView() {
    final ids = <String>{};
    for (final items in _groupedFilteredRelatorios.values) {
      for (final item in items) {
        final id = _getItemId(item);
        if (id.isNotEmpty) ids.add(id);
      }
    }
    return ids;
  }

  bool _matchesRelatorioQuery(Relatorio relatorio, String queryLower) {
    final formatadorData = DateFormat('dd/MM/yyyy HH:mm');
    final dataStr = formatadorData.format(relatorio.dataHora).toLowerCase();

    final haystack = <String>[
      relatorio.localAtividade,
      relatorio.nomeUtilizador,
      relatorio.matriculaUtilizador,
      relatorio.empresaUtilizador,
      relatorio.emailUtilizador,
      dataStr,
      relatorio.usaTravaQuedas ? 'trava-quedas' : 'talabarte',
      // parâmetros/resultados (ajuda buscar por número/valor)
      relatorio.alturaAncoragem.toString(),
      relatorio.compTalabarte.toString(),
      relatorio.estAbsorvedor.toString(),
      relatorio.distPes.toString(),
      relatorio.fq.toString(),
      relatorio.zlqAncoragem.toString(),
      relatorio.zlqPes.toString(),
    ].join(' ').toLowerCase();

    return haystack.contains(queryLower);
  }

  bool _matchesChecklistQuery(
    ChecklistPreUsoRegistro checklist,
    String queryLower,
  ) {
    final formatadorData = DateFormat('dd/MM/yyyy HH:mm');
    final dataStr = formatadorData.format(checklist.createdAt).toLowerCase();
    final tag = (checklist.equipamentoTag ?? '');
    final status = checklist.interditado ? 'interditado' : 'conforme';
    final rascunhoStr = checklist.rascunho ? 'rascunho' : 'finalizado';

    final haystack = <String>[
      checklist.sectionTitle,
      checklist.templateTitle,
      checklist.sectionId,
      tag,
      status,
      rascunhoStr,
      dataStr,
    ].join(' ').toLowerCase();

    return haystack.contains(queryLower);
  }

  bool _matchesInspecaoQuery(
    ChecklistInspecaoInicialPeriodicaRegistro checklist,
    String queryLower,
  ) {
    final formatadorData = DateFormat('dd/MM/yyyy HH:mm');
    final dataStr = formatadorData.format(checklist.createdAt).toLowerCase();
    final tag = (checklist.equipamentoTag ?? '');
    final status = checklist.interditado ? 'interditado' : 'conforme';
    final rascunhoStr = checklist.rascunho ? 'rascunho' : 'finalizado';

    final haystack = <String>[
      checklist.sectionTitle,
      checklist.templateTitle,
      checklist.sectionId,
      checklist.tipoInspecao.label,
      checklist.tipoInspecao.code,
      tag,
      status,
      rascunhoStr,
      dataStr,
    ].join(' ').toLowerCase();

    return haystack.contains(queryLower);
  }

  @override
  void initState() {
    super.initState();
    _carregarRelatorios();
    _searchController.addListener(() {
      // Debounce: aguarda 300ms após parar de digitar
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _filtrarEAgruparRelatorios();
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarRelatorios() async {
    final prefs = await SharedPreferences.getInstance();
    final relatoriosJson = prefs.getStringList('relatorios') ?? [];
    final checklistsJson = prefs.getStringList('checklists_pre_uso') ?? [];
    final inspecoesJson =
        prefs.getStringList('checklists_inspecao_inicial_periodica') ?? [];

    final relatoriosCarregados = relatoriosJson
        .map((jsonString) {
          try {
            return Relatorio.fromJson(jsonDecode(jsonString));
          } catch (e) {
            return null;
          }
        })
        .whereType<Relatorio>()
        .toList();

    final checklistsCarregados = checklistsJson
        .map((jsonString) {
          try {
            return ChecklistPreUsoRegistro.fromJson(jsonDecode(jsonString));
          } catch (e) {
            return null;
          }
        })
        .whereType<ChecklistPreUsoRegistro>()
        .toList();

    final inspecoesCarregadas = inspecoesJson
        .map((jsonString) {
          try {
            return ChecklistInspecaoInicialPeriodicaRegistro.fromJson(
              jsonDecode(jsonString),
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<ChecklistInspecaoInicialPeriodicaRegistro>()
        .toList();

    relatoriosCarregados.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    checklistsCarregados.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    inspecoesCarregadas.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mounted) {
      setState(() {
        _relatorios = relatoriosCarregados;
        _checklists = checklistsCarregados;
        _inspecoes = inspecoesCarregadas;
      });
      _filtrarEAgruparRelatorios();
    }
  }

  String _getItemId(dynamic item) {
    if (item is Relatorio) {
      return item.id;
    } else if (item is ChecklistPreUsoRegistro) {
      return item.id;
    } else if (item is ChecklistInspecaoInicialPeriodicaRegistro) {
      return item.id;
    }
    return '';
  }

  void _filtrarEAgruparRelatorios() {
    final formatador = DateFormat('MMMM yyyy', 'pt_BR');
    final Map<String, List<dynamic>> groups = {};
    final queryLower = _searchQuery.trim().toLowerCase();

    // Filtrar e agrupar relatórios FQ/ZLQ
    final relatoriosFiltrados = queryLower.isEmpty
        ? List.from(_relatorios)
        : _relatorios.where((relatorio) {
            return _matchesRelatorioQuery(relatorio, queryLower);
          }).toList();

    for (final relatorio in relatoriosFiltrados) {
      final key = formatador.format(relatorio.dataHora);
      groups.putIfAbsent(key, () => []).add(relatorio);
    }

    // Filtrar e agrupar checklists
    final checklistsFiltrados = queryLower.isEmpty
        ? List.from(_checklists)
        : _checklists.where((checklist) {
            return _matchesChecklistQuery(checklist, queryLower);
          }).toList();

    for (final checklist in checklistsFiltrados) {
      final key = formatador.format(checklist.createdAt);
      groups.putIfAbsent(key, () => []).add(checklist);
    }

    // Filtrar e agrupar inspeções (inicial/periódica)
    final inspecoesFiltradas = queryLower.isEmpty
        ? List.from(_inspecoes)
        : _inspecoes.where((checklist) {
            return _matchesInspecaoQuery(checklist, queryLower);
          }).toList();

    for (final checklist in inspecoesFiltradas) {
      final key = formatador.format(checklist.createdAt);
      groups.putIfAbsent(key, () => []).add(checklist);
    }

    // Ordenar itens dentro de cada grupo por data
    for (final key in groups.keys) {
      groups[key]!.sort((a, b) {
        final DateTime dateA;
        if (a is Relatorio) {
          dateA = a.dataHora;
        } else if (a is ChecklistPreUsoRegistro) {
          dateA = a.createdAt;
        } else if (a is ChecklistInspecaoInicialPeriodicaRegistro) {
          dateA = a.createdAt;
        } else {
          dateA = DateTime.fromMillisecondsSinceEpoch(0);
        }

        final DateTime dateB;
        if (b is Relatorio) {
          dateB = b.dataHora;
        } else if (b is ChecklistPreUsoRegistro) {
          dateB = b.createdAt;
        } else if (b is ChecklistInspecaoInicialPeriodicaRegistro) {
          dateB = b.createdAt;
        } else {
          dateB = DateTime.fromMillisecondsSinceEpoch(0);
        }
        return dateB.compareTo(dateA);
      });
    }

    setState(() {
      _groupedFilteredRelatorios = groups;
    });
  }

  Future<void> _apagarRelatorios(List<String> idsParaApagar) async {
    final prefs = await SharedPreferences.getInstance();

    // Apagar relatórios FQ/ZLQ
    final relatoriosJson = prefs.getStringList('relatorios') ?? [];
    relatoriosJson.removeWhere((jsonString) {
      try {
        final relatorio = Relatorio.fromJson(jsonDecode(jsonString));
        return idsParaApagar.contains(relatorio.id);
      } catch (e) {
        return false;
      }
    });
    await prefs.setStringList('relatorios', relatoriosJson);

    // Apagar checklists
    final checklistsJson = prefs.getStringList('checklists_pre_uso') ?? [];
    checklistsJson.removeWhere((jsonString) {
      try {
        final checklist = ChecklistPreUsoRegistro.fromJson(
          jsonDecode(jsonString),
        );
        return idsParaApagar.contains(checklist.id);
      } catch (e) {
        return false;
      }
    });
    await prefs.setStringList('checklists_pre_uso', checklistsJson);

    // Apagar inspeções
    final inspecoesJson =
        prefs.getStringList('checklists_inspecao_inicial_periodica') ?? [];
    inspecoesJson.removeWhere((jsonString) {
      try {
        final checklist = ChecklistInspecaoInicialPeriodicaRegistro.fromJson(
          jsonDecode(jsonString),
        );
        return idsParaApagar.contains(checklist.id);
      } catch (e) {
        return false;
      }
    });
    await prefs.setStringList(
      'checklists_inspecao_inicial_periodica',
      inspecoesJson,
    );

    setState(() {
      _isSelectionMode = false;
      _selectedReportIds.clear();
    });

    await _carregarRelatorios();
  }

  void _mostrarConfirmacaoApagarUnico(String relatorioId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text(
            'Tem a certeza de que deseja apagar este relatório permanentemente?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Não'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Sim, Apagar'),
              onPressed: () {
                Navigator.of(context).pop();
                _apagarRelatorios([relatorioId]);
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarConfirmacaoApagarMultiplos() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão Múltipla'),
          content: Text(
            'Tem a certeza de que deseja apagar os ${_selectedReportIds.length} relatórios selecionados?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Não'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              onPressed: () {
                Navigator.of(context).pop();
                _apagarRelatorios(_selectedReportIds.toList());
              },
              child: const Text('Sim, Apagar Todos'),
            ),
          ],
        );
      },
    );
  }

  void _toggleSelectionMode(String reportId) {
    setState(() {
      _isSelectionMode = true;
      _selectedReportIds.add(reportId);
    });
  }

  void _toggleItemSelection(String reportId) {
    setState(() {
      if (_selectedReportIds.contains(reportId)) {
        _selectedReportIds.remove(reportId);
        if (_selectedReportIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedReportIds.add(reportId);
      }
    });
  }

  void _cancelSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedReportIds.clear();
    });
  }

  void _navegarParaDetalhes(Relatorio relatorio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaginaDetalheRelatorio(relatorio: relatorio),
      ),
    ).then((_) => _carregarRelatorios());
  }

  void _navegarParaDetalheChecklist(ChecklistPreUsoRegistro checklist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaginaDetalheChecklistPreUso(checklist: checklist),
      ),
    ).then((_) => _carregarRelatorios());
  }

  void _navegarParaDetalheInspecao(
    ChecklistInspecaoInicialPeriodicaRegistro checklist,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaginaDetalheInspecaoInicialPeriodica(checklist: checklist),
      ),
    ).then((_) => _carregarRelatorios());
  }

  // ===== MÉTODOS DE DUPLICAÇÃO =====

  void _duplicarRelatorio(Relatorio relatorio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaginaCalculadora(relatorioParaEditar: relatorio, duplicar: true),
      ),
    ).then((_) => _carregarRelatorios());
  }

  Future<void> _duplicarChecklist(ChecklistPreUsoRegistro checklist) async {
    final now = DateTime.now();
    final novoChecklist = checklist.copyWith(
      id: 'checklist_${now.millisecondsSinceEpoch}',
      createdAt: now,
      rascunho: true,
      clearAssinatura: true,
    );

    final prefs = await SharedPreferences.getInstance();
    final checklistsJson = prefs.getStringList('checklists_pre_uso') ?? [];
    checklistsJson.add(jsonEncode(novoChecklist.toJson()));
    await prefs.setStringList('checklists_pre_uso', checklistsJson);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Rascunho criado! Edite e assine para finalizar o relatório.',
        ),
      ),
    );
    await _carregarRelatorios();
  }

  Future<void> _duplicarInspecao(
    ChecklistInspecaoInicialPeriodicaRegistro checklist,
  ) async {
    final now = DateTime.now();
    final novoChecklist = checklist.copyWith(
      id: 'inspecao_${now.millisecondsSinceEpoch}',
      createdAt: now,
      rascunho: true,
      clearAssinatura: true,
    );

    final prefs = await SharedPreferences.getInstance();
    final inspecoesJson =
        prefs.getStringList('checklists_inspecao_inicial_periodica') ?? [];
    inspecoesJson.add(jsonEncode(novoChecklist.toJson()));
    await prefs.setStringList(
      'checklists_inspecao_inicial_periodica',
      inspecoesJson,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Rascunho criado! Edite e assine para finalizar o relatório.',
        ),
      ),
    );
    await _carregarRelatorios();
  }

  Future<void> _visualizarPdfChecklist(
    ChecklistPreUsoRegistro checklist,
  ) async {
    try {
      final assinatura = (checklist.assinaturaBase64Png ?? '').trim();
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

      final prefs = await SharedPreferences.getInstance();
      final nomeUsuario = prefs.getString('nome');
      final matriculaUsuario = prefs.getString('matricula');
      final empresaUsuario = prefs.getString('empresa');
      final emailUsuario = prefs.getString('email');
      final estadoUsuario = prefs.getString('estado');
      final municipioUsuario = prefs.getString('municipio');

      // Carregar o template do checklist
      final jsonStr = await rootBundle.loadString(
        'assets/checklists/pre_uso.json',
      );
      final template = ChecklistPreUsoTemplate.fromJsonString(jsonStr);

      // Encontrar a seção correta
      final section = template.sections.firstWhere(
        (s) => s.id == checklist.sectionId,
        orElse: () => template.sections.first,
      );

      // Decodificar assinatura se existir
      final assinaturaPng = checklist.assinaturaBase64Png != null
          ? decodePngFromBase64(checklist.assinaturaBase64Png!)
          : null;

      // Gerar PDF
      final pdfBytes = await gerarPdfChecklistPreUso(
        template: template,
        section: section,
        respostas: checklist.respostas,
        createdAt: checklist.createdAt,
        assinaturaPng: assinaturaPng,
        equipamentoTag: checklist.equipamentoTag,
        equipamentoFotoPath: checklist.equipamentoFotoPath,
        nomeUsuario: nomeUsuario,
        matriculaUsuario: matriculaUsuario,
        empresaUsuario: empresaUsuario,
        emailUsuario: emailUsuario,
        estadoUsuario: estadoUsuario,
        municipioUsuario: municipioUsuario,
      );

      final tempDir = await getTemporaryDirectory();
      final filename =
          'checklist_pre_uso_${checklist.createdAt.millisecondsSinceEpoch}.pdf';
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaginaVisualizarPdf(caminhoPdf: file.path),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    }
  }

  Future<void> _visualizarPdfInspecao(
    ChecklistInspecaoInicialPeriodicaRegistro checklist,
  ) async {
    try {
      final assinatura = (checklist.assinaturaBase64Png ?? '').trim();
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

      final sectionId = checklist.sectionId == 'trava_queda_deslizante_itens'
          ? 'trava_queda_2b'
          : checklist.sectionId;

      final section = template.sections.firstWhere(
        (s) => s.id == sectionId,
        orElse: () => template.sections.first,
      );

      final assinaturaPng = checklist.assinaturaBase64Png != null
          ? decodePngFromBase64(checklist.assinaturaBase64Png!)
          : null;

      final pdfBytes = await gerarPdfChecklistPreUso(
        template: template,
        section: section,
        respostas: checklist.respostas,
        createdAt: checklist.createdAt,
        assinaturaPng: assinaturaPng,
        equipamentoTag: checklist.equipamentoTag,
        equipamentoFotoPath: checklist.equipamentoFotoPath,
        nomeUsuario: nomeUsuario,
        matriculaUsuario: matriculaUsuario,
        empresaUsuario: empresaUsuario,
        emailUsuario: emailUsuario,
        estadoUsuario: estadoUsuario,
        municipioUsuario: municipioUsuario,
        tipoInspecaoLabel: checklist.tipoInspecao.label,
      );

      final tempDir = await getTemporaryDirectory();
      final filename =
          'inspecao_${checklist.createdAt.millisecondsSinceEpoch}.pdf';
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaginaVisualizarPdf(caminhoPdf: file.path),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 1),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // ATUALIZADO: Usando as cores do tema para a AppBar de seleção
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isSelectionMode) {
      final allIds = _getAllSelectableIdsInCurrentView();
      final bool allSelected =
          allIds.isNotEmpty && _selectedReportIds.length >= allIds.length;

      return AppBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurfaceVariant,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancelSelectionMode,
        ),
        title: Text('${_selectedReportIds.length} selecionado(s)'),
        actions: [
          IconButton(
            icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
            tooltip: allSelected ? 'Limpar seleção' : 'Selecionar todos',
            onPressed: allIds.isEmpty
                ? null
                : () {
                    setState(() {
                      if (allSelected) {
                        _selectedReportIds.clear();
                        _isSelectionMode = false;
                      } else {
                        _selectedReportIds
                          ..clear()
                          ..addAll(allIds);
                      }
                    });
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Apagar Selecionados',
            onPressed: _selectedReportIds.isNotEmpty
                ? _mostrarConfirmacaoApagarMultiplos
                : null,
          ),
        ],
      );
    } else {
      // ATUALIZADO: AppBar normal agora usa o tema padrão
      return AppBar(title: const Text('Meus Relatórios'));
    }
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildReportListContent()),
      ],
    );
  }

  Widget _buildSearchBar() {
    // ATUALIZADO: Barra de pesquisa usa cores do tema
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Pesquisar...',
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
        ),
      ),
    );
  }

  Widget _buildReportListContent() {
    final textTheme = Theme.of(context).textTheme;

    if (_relatorios.isEmpty && _checklists.isEmpty && _inspecoes.isEmpty) {
      return Center(
        child: Text(
          'Nenhum relatório salvo ainda.',
          style: textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).disabledColor,
          ),
        ),
      );
    }

    if (_groupedFilteredRelatorios.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Nenhum relatório encontrado para "$_searchQuery".',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ),
      );
    }

    final groupKeys = _groupedFilteredRelatorios.keys.toList();

    return ListView.builder(
      itemCount: groupKeys.length,
      itemBuilder: (context, groupIndex) {
        String monthYearKey = groupKeys[groupIndex];
        List<dynamic> groupItems = _groupedFilteredRelatorios[monthYearKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupHeader(monthYearKey),
            ...groupItems.map((item) {
              if (item is Relatorio) {
                return _buildReportCard(item);
              } else if (item is ChecklistPreUsoRegistro) {
                return _buildChecklistCard(item);
              } else if (item is ChecklistInspecaoInicialPeriodicaRegistro) {
                return _buildInspecaoCard(item);
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      },
    );
  }

  Widget _buildGroupHeader(String title) {
    // ATUALIZADO: Cabeçalho do grupo usa cores do tema
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        title.toUpperCase(),
        style: textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReportCard(Relatorio relatorio) {
    final bool isSelected = _selectedReportIds.contains(relatorio.id);
    final formatadorDataCard = DateFormat('dd/MM/yyyy HH:mm');
    final dataFormatada = formatadorDataCard.format(relatorio.dataHora);
    final localExibicao = relatorio.localAtividade.isNotEmpty
        ? relatorio.localAtividade
        : 'Local não definido';

    final subtitulo =
        'Data: $dataFormatada\n'
        'L: ${relatorio.compTalabarte}m | EA: ${relatorio.estAbsorvedor}m | C: ${relatorio.distPes}m';

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isSelected ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleItemSelection(relatorio.id);
          } else {
            _navegarParaDetalhes(relatorio);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode(relatorio.id);
          }
        },
        child: ListTile(
          leading: _buildLeadingIcon(isSelected),
          title: Text(
            localExibicao,
            style: textTheme.titleMedium?.copyWith(
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          subtitle: Text(subtitulo),
          isThreeLine: true,
          trailing: _isSelectionMode
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.copy_outlined,
                        color: colorScheme.secondary,
                      ),
                      tooltip: 'Duplicar',
                      onPressed: () => _duplicarRelatorio(relatorio),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      onPressed: () {
                        _mostrarConfirmacaoApagarUnico(relatorio.id);
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isSelectionMode) {
      return Icon(
        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
        color: colorScheme.primary,
        size: 30,
      );
    } else {
      return Icon(Icons.assignment, color: colorScheme.primary, size: 40);
    }
  }

  Widget _buildChecklistCard(ChecklistPreUsoRegistro checklist) {
    final checklistId = _getItemId(checklist);
    final bool isSelected = _selectedReportIds.contains(checklistId);
    final formatadorDataCard = DateFormat('dd/MM/yyyy HH:mm');
    final dataFormatada = formatadorDataCard.format(checklist.createdAt);
    final tag = checklist.equipamentoTag?.isNotEmpty == true
        ? checklist.equipamentoTag!
        : 'Sem TAG';
    final tituloBase = '${checklist.sectionTitle} - $tag';
    final titulo = checklist.rascunho
        ? '📝 [RASCUNHO] $tituloBase'
        : tituloBase;

    String statusText;
    if (checklist.rascunho) {
      statusText = 'RASCUNHO - Aguardando assinatura';
    } else if (checklist.interditado) {
      statusText = 'INTERDITADO';
    } else {
      statusText = 'Conforme';
    }
    final subtitulo = 'Data: $dataFormatada\nStatus: $statusText';

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isSelected ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : (checklist.rascunho
                    ? colorScheme.tertiary
                    : (checklist.interditado
                          ? colorScheme.error
                          : Colors.transparent)),
          width: (isSelected || checklist.interditado || checklist.rascunho)
              ? 2
              : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleItemSelection(checklistId);
          } else {
            _navegarParaDetalheChecklist(checklist);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode(checklistId);
          }
        },
        child: ListTile(
          leading: _buildLeadingIconChecklist(
            isSelected,
            checklist.interditado,
            checklist.rascunho,
          ),
          title: Text(
            titulo,
            style: textTheme.titleMedium?.copyWith(
              color: isSelected
                  ? colorScheme.primary
                  : (checklist.interditado
                        ? colorScheme.error
                        : colorScheme.onSurface),
            ),
          ),
          subtitle: Text(subtitulo),
          isThreeLine: true,
          trailing: _isSelectionMode
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.copy_outlined,
                        color: colorScheme.secondary,
                      ),
                      tooltip: 'Duplicar',
                      onPressed: () => _duplicarChecklist(checklist),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.picture_as_pdf,
                        color: colorScheme.primary,
                      ),
                      onPressed: () => _visualizarPdfChecklist(checklist),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      onPressed: () {
                        _mostrarConfirmacaoApagarUnico(checklistId);
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLeadingIconChecklist(
    bool isSelected,
    bool interditado, [
    bool rascunho = false,
  ]) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isSelectionMode) {
      return Icon(
        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
        color: colorScheme.primary,
        size: 30,
      );
    } else {
      Color iconColor;
      IconData iconData;

      if (rascunho) {
        iconColor = colorScheme.tertiary;
        iconData = Icons.edit_note;
      } else if (interditado) {
        iconColor = colorScheme.error;
        iconData = Icons.checklist_rtl;
      } else {
        iconColor = colorScheme.secondary;
        iconData = Icons.checklist_rtl;
      }

      return Icon(iconData, color: iconColor, size: 40);
    }
  }

  Widget _buildInspecaoCard(
    ChecklistInspecaoInicialPeriodicaRegistro checklist,
  ) {
    final checklistId = _getItemId(checklist);
    final bool isSelected = _selectedReportIds.contains(checklistId);
    final formatadorDataCard = DateFormat('dd/MM/yyyy HH:mm');
    final dataFormatada = formatadorDataCard.format(checklist.createdAt);

    final tag = checklist.equipamentoTag?.isNotEmpty == true
        ? checklist.equipamentoTag!
        : 'Sem TAG';

    final tituloBase =
        '${checklist.tipoInspecao.code} - ${checklist.sectionTitle} - $tag';
    final titulo = checklist.rascunho
        ? '📝 [RASCUNHO] $tituloBase'
        : tituloBase;

    String statusText;
    if (checklist.rascunho) {
      statusText = 'RASCUNHO - Aguardando assinatura';
    } else if (checklist.interditado) {
      statusText = 'INTERDITADO';
    } else {
      statusText = 'Conforme';
    }
    final subtitulo = 'Data: $dataFormatada\nStatus: $statusText';

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isSelected ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : (checklist.rascunho
                    ? colorScheme.tertiary
                    : (checklist.interditado
                          ? colorScheme.error
                          : Colors.transparent)),
          width: (isSelected || checklist.interditado || checklist.rascunho)
              ? 2
              : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleItemSelection(checklistId);
          } else {
            _navegarParaDetalheInspecao(checklist);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode(checklistId);
          }
        },
        child: ListTile(
          leading: _buildLeadingIconInspecao(
            isSelected,
            checklist.interditado,
            checklist.rascunho,
          ),
          title: Text(
            titulo,
            style: textTheme.titleMedium?.copyWith(
              color: isSelected
                  ? colorScheme.primary
                  : (checklist.rascunho
                        ? colorScheme.tertiary
                        : (checklist.interditado
                              ? colorScheme.error
                              : colorScheme.onSurface)),
            ),
          ),
          subtitle: Text(subtitulo),
          isThreeLine: true,
          trailing: _isSelectionMode
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.copy_outlined,
                        color: colorScheme.secondary,
                      ),
                      tooltip: 'Duplicar',
                      onPressed: () => _duplicarInspecao(checklist),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.picture_as_pdf,
                        color: colorScheme.primary,
                      ),
                      onPressed: () => _visualizarPdfInspecao(checklist),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      onPressed: () {
                        _mostrarConfirmacaoApagarUnico(checklistId);
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLeadingIconInspecao(
    bool isSelected,
    bool interditado, [
    bool rascunho = false,
  ]) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isSelectionMode) {
      return Icon(
        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
        color: colorScheme.primary,
        size: 30,
      );
    }

    Color iconColor;
    IconData iconData;

    if (rascunho) {
      iconColor = colorScheme.tertiary;
      iconData = Icons.edit_note;
    } else if (interditado) {
      iconColor = colorScheme.error;
      iconData = Icons.fact_check;
    } else {
      iconColor = colorScheme.secondary;
      iconData = Icons.fact_check;
    }

    return Icon(iconData, color: iconColor, size: 40);
  }
}
