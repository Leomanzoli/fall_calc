// lib/screens/pagina_calculadora.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fall_calc_final/models/relatoriofq_zlq.dart';
import 'package:fall_calc_final/utils/calculo_fq_zlq.dart';
import 'package:fall_calc_final/utils/gerador_pdf_fq_zlq.dart';
import 'package:fall_calc_final/utils/imagem_local.dart';
import 'package:fall_calc_final/widgets/ajuste_imagem_widget.dart';
import 'package:fall_calc_final/widgets/checklist/signature_pad.dart';

class PaginaCalculadora extends StatefulWidget {
  final Relatorio? relatorioParaEditar;
  final bool duplicar;

  const PaginaCalculadora({
    super.key,
    this.relatorioParaEditar,
    this.duplicar = false,
  });

  @override
  State<PaginaCalculadora> createState() => _PaginaCalculadoraState();
}

class _PaginaCalculadoraState extends State<PaginaCalculadora> {
  final _controllerLocal = TextEditingController();
  final _controllerTalabarte = TextEditingController();
  final _controllerAbsorvedor = TextEditingController();
  final _controllerDistanciaPes = TextEditingController();
  final _controllerAlturaAncoragem = TextEditingController();
  final _controllerObservacoes = TextEditingController();
  final _controllerFlechaProjeto = TextEditingController();
  late List<TextEditingController> _controllers;

  bool _equipamentoTravaQuedas = false;
  bool _incluirDeformacaoCinto = true;
  bool _usaLinhaVidaHorizontal = false;

  // Caminhos registrados em ImagemLocal (arquivo no Android, memória na web)
  String? _imagemSelecionada;
  String? _imagemSelecionada2; // Segunda imagem opcional
  bool _mostrarSegundaImagem = false; // Controla expansão da seção

  // Assinatura digital
  final _signatureKey = GlobalKey<SignaturePadState>();
  Uint8List? _assinaturaPng;
  String? _assinaturaBase64;
  bool _assinando = false;

  double _resultadoZLQAncoragem = 0.0;
  double _resultadoZLQpes = 0.0;
  double _resultadoFQ = -1.0;
  String _mensagemAlertaFQ = '';
  bool _relatorioAtualSalvo = false;
  String? _caminhoPdfGerado;
  Uint8List? _pdfBytesGerado; // Web: PDF fica apenas em memória

  bool get _temPdfGerado =>
      _caminhoPdfGerado != null || _pdfBytesGerado != null;

  late final String _relatorioId;
  late final DateTime _dataRegistro;

  String _nomeUtilizador = 'Não definido';
  String _matriculaUtilizador = 'Não definida';
  String _empresaUtilizador = 'Não definida';
  String _emailUtilizador = 'Não definido';

  bool get _isEditMode =>
      widget.relatorioParaEditar != null && !widget.duplicar;
  bool get _isDuplicateMode =>
      widget.relatorioParaEditar != null && widget.duplicar;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    // Em modo duplicar, sempre gera novo ID e usa data atual
    _relatorioId = (_isEditMode && !_isDuplicateMode)
        ? (widget.relatorioParaEditar?.id ?? now.toIso8601String())
        : now.toIso8601String();
    _dataRegistro = (_isEditMode && !_isDuplicateMode)
        ? (widget.relatorioParaEditar?.dataHora ?? now)
        : now;

    _controllers = [
      _controllerLocal,
      _controllerTalabarte,
      _controllerAbsorvedor,
      _controllerDistanciaPes,
      _controllerAlturaAncoragem,
      _controllerObservacoes,
      _controllerFlechaProjeto,
    ];
    for (var controller in _controllers) {
      controller.addListener(_marcarComoNaoSalvo);
    }
    _carregarDadosUtilizador();
    if (_isEditMode || _isDuplicateMode) {
      _popularCamposParaEdicao();
    }
  }

  void _popularCamposParaEdicao() {
    final relatorio = widget.relatorioParaEditar!;
    _controllerLocal.text = relatorio.localAtividade;
    _controllerAlturaAncoragem.text = relatorio.alturaAncoragem
        .toString()
        .replaceAll('.', ',');
    _controllerTalabarte.text = relatorio.compTalabarte.toString().replaceAll(
      '.',
      ',',
    );
    _controllerAbsorvedor.text = relatorio.estAbsorvedor.toString().replaceAll(
      '.',
      ',',
    );
    _controllerDistanciaPes.text = relatorio.distPes.toString().replaceAll(
      '.',
      ',',
    );
    _controllerObservacoes.text = relatorio.observacoes;
    _controllerFlechaProjeto.text = relatorio.flechaProjeto
        .toString()
        .replaceAll('.', ',');

    setState(() {
      _equipamentoTravaQuedas = relatorio.usaTravaQuedas;
      _incluirDeformacaoCinto = relatorio.incluiDeformacaoCinto;
      _usaLinhaVidaHorizontal = relatorio.usaLinhaVidaHorizontal;

      if (ImagemLocal.existe(relatorio.caminhoImagem)) {
        _imagemSelecionada = relatorio.caminhoImagem;
      }

      if (ImagemLocal.existe(relatorio.caminhoImagem2)) {
        _imagemSelecionada2 = relatorio.caminhoImagem2;
        _mostrarSegundaImagem = true; // Expandir seção se já houver imagem
      }

      _resultadoFQ = relatorio.fq;
      _resultadoZLQAncoragem = relatorio.zlqAncoragem;
      _resultadoZLQpes = relatorio.zlqPes;
      _mensagemAlertaFQ = relatorio.mensagemAlertaFQ;
      _caminhoPdfGerado = relatorio.caminhoPdf;
      _relatorioAtualSalvo = true;

      // Carregar assinatura existente
      if (relatorio.assinaturaBase64Png != null &&
          relatorio.assinaturaBase64Png!.isNotEmpty) {
        _assinaturaBase64 = relatorio.assinaturaBase64Png;
        _assinaturaPng = base64Decode(relatorio.assinaturaBase64Png!);
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.removeListener(_marcarComoNaoSalvo);
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarDadosUtilizador() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nomeUtilizador = prefs.getString('nome') ?? 'Não definido';
      _matriculaUtilizador = prefs.getString('matricula') ?? 'Não definida';
      // Na web o campo Empresa não existe; vazio faz o PDF omitir a linha.
      _empresaUtilizador =
          prefs.getString('empresa') ?? (kIsWeb ? '' : 'Não definida');
      _emailUtilizador = prefs.getString('email') ?? 'Não definido';
    });
  }

  void _marcarComoNaoSalvo() {
    if (mounted && _relatorioAtualSalvo) {
      // Apenas atualiza se realmente mudou de estado (evita rebuilds excessivos)
      setState(() {
        _relatorioAtualSalvo = false;
        _caminhoPdfGerado = null;
        _pdfBytesGerado = null;
      });
    } else {
      // Se já estava marcado como não salvo, apenas atualiza as variáveis sem rebuild
      _relatorioAtualSalvo = false;
      _caminhoPdfGerado = null;
      _pdfBytesGerado = null;
    }
  }

  Relatorio _criarObjetoRelatorio() {
    return Relatorio(
      id: _relatorioId,
      dataHora: _dataRegistro,
      nomeUtilizador: _nomeUtilizador,
      matriculaUtilizador: _matriculaUtilizador,
      empresaUtilizador: _empresaUtilizador,
      emailUtilizador: _emailUtilizador,
      localAtividade: _controllerLocal.text,
      caminhoImagem: _imagemSelecionada,
      caminhoImagem2: _imagemSelecionada2,
      alturaAncoragem:
          double.tryParse(
            _controllerAlturaAncoragem.text.replaceAll(',', '.'),
          ) ??
          0.0,
      compTalabarte:
          double.tryParse(_controllerTalabarte.text.replaceAll(',', '.')) ??
          0.0,
      estAbsorvedor:
          double.tryParse(_controllerAbsorvedor.text.replaceAll(',', '.')) ??
          0.0,
      distPes:
          double.tryParse(_controllerDistanciaPes.text.replaceAll(',', '.')) ??
          0.0,
      usaTravaQuedas: _equipamentoTravaQuedas,
      incluiDeformacaoCinto: _incluirDeformacaoCinto,
      usaLinhaVidaHorizontal: _usaLinhaVidaHorizontal,
      flechaProjeto:
          double.tryParse(_controllerFlechaProjeto.text.replaceAll(',', '.')) ??
          0.0,
      fq: _resultadoFQ,
      zlqAncoragem: _resultadoZLQAncoragem,
      zlqPes: _resultadoZLQpes,
      mensagemAlertaFQ: _mensagemAlertaFQ,
      observacoes: _controllerObservacoes.text,
      caminhoPdf: _isEditMode ? null : _caminhoPdfGerado,
      assinaturaBase64Png: _assinaturaBase64,
    );
  }

  Future<bool> _validarCalculo() async {
    _calcular();
    if (_resultadoFQ < 0 && !_equipamentoTravaQuedas) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Execute um cálculo válido primeiro.')),
      );
      return false;
    }
    return true;
  }

  Future<void> _salvarRelatorio() async {
    if (!await _validarCalculo()) return;
    final novoRelatorio = _criarObjetoRelatorio();
    final prefs = await SharedPreferences.getInstance();
    final relatoriosJson = prefs.getStringList('relatorios') ?? [];
    relatoriosJson.removeWhere((jsonString) {
      try {
        return Relatorio.fromJson(jsonDecode(jsonString)).id ==
            novoRelatorio.id;
      } catch (e) {
        return false;
      }
    });
    relatoriosJson.add(jsonEncode(novoRelatorio.toJson()));
    await prefs.setStringList('relatorios', relatoriosJson);
    setState(() {
      _relatorioAtualSalvo = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditMode
              ? 'Relatório atualizado com sucesso!'
              : 'Relatório salvo!',
        ),
      ),
    );
    if (_isEditMode) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _salvarEGerarPdf() async {
    if (!await _validarCalculo()) return;
    try {
      final relatorioParaPdf = _criarObjetoRelatorio();
      final pdfBytes = await gerarPdfRelatorio(relatorioParaPdf);

      if (kIsWeb) {
        // Versão web: sem histórico; o PDF é exibido para imprimir/baixar.
        setState(() {
          _pdfBytesGerado = pdfBytes;
          _relatorioAtualSalvo = true;
        });
        _visualizarPdf();
        return;
      }

      final caminhoPdf = await ImagemLocal.salvarArquivo(
        pdfBytes,
        'relatorio_${relatorioParaPdf.id}.pdf',
      );
      relatorioParaPdf.caminhoPdf = caminhoPdf;
      final prefs = await SharedPreferences.getInstance();
      final relatoriosJson = prefs.getStringList('relatorios') ?? [];
      relatoriosJson.removeWhere((jsonString) {
        try {
          return Relatorio.fromJson(jsonDecode(jsonString)).id ==
              relatorioParaPdf.id;
        } catch (e) {
          return false;
        }
      });
      relatoriosJson.add(jsonEncode(relatorioParaPdf.toJson()));
      await prefs.setStringList('relatorios', relatoriosJson);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'PDF regenerado e relatório atualizado!'
                : 'PDF gerado e relatório salvo!',
          ),
        ),
      );
      setState(() {
        _caminhoPdfGerado = caminhoPdf;
        _relatorioAtualSalvo = true;
      });
      if (_isEditMode) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('[Calculadora][ERRO] Falha ao gerar PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar PDF: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _visualizarPdf() {
    if (!_temPdfGerado) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaginaVisualizarPdf(
          caminhoPdf: _caminhoPdfGerado,
          pdfBytes: _pdfBytesGerado,
        ),
      ),
    );
  }

  /// Constrói a seção de assinatura digital
  Widget _buildSecaoAssinatura(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_assinaturaPng == null) ...[
          // Modo assinatura - mostrar o SignaturePad
          SignaturePad(
            key: _signatureKey,
            height: 150,
            onSigningChanged: (signing) {
              setState(() => _assinando = signing);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _signatureKey.currentState?.clear();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _assinando
                      ? null
                      : () async {
                          final png = await _signatureKey.currentState
                              ?.exportPng();
                          if (png != null) {
                            setState(() {
                              _assinaturaPng = png;
                              _assinaturaBase64 = base64Encode(png);
                              _relatorioAtualSalvo = false;
                              _caminhoPdfGerado = null;
                            });
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Por favor, assine antes de confirmar.',
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar Assinatura'),
                ),
              ),
            ],
          ),
        ] else ...[
          // Assinatura já capturada - mostrar preview
          Text('Assinatura', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withAlpha(128)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _assinaturaPng!,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _assinaturaPng = null;
                      _assinaturaBase64 = null;
                      _relatorioAtualSalvo = false;
                      _caminhoPdfGerado = null;
                    });
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Alterar Assinatura'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _mostrarOpcoesSelecaoImagem({bool segundaImagem = false}) {
    final imagemAtual = segundaImagem ? _imagemSelecionada2 : _imagemSelecionada;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  _pegarImagem(
                    ImageSource.gallery,
                    segundaImagem: segundaImagem,
                  );
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tirar Foto com a Câmara'),
                onTap: () {
                  _pegarImagem(
                    ImageSource.camera,
                    segundaImagem: segundaImagem,
                  );
                  Navigator.of(context).pop();
                },
              ),
              if (imagemAtual != null)
                ListTile(
                  leading: const Icon(Icons.crop),
                  title: const Text('Ajustar Enquadramento'),
                  subtitle: const Text('Use dois dedos para zoom e arraste'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _ajustarImagem(imagemAtual, segundaImagem: segundaImagem);
                  },
                ),
              if (segundaImagem && _imagemSelecionada2 != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remover Imagem'),
                  onTap: () {
                    setState(() {
                      _imagemSelecionada2 = null;
                    });
                    _marcarComoNaoSalvo();
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pegarImagem(
    ImageSource source, {
    bool segundaImagem = false,
  }) async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(source: source);
    if (imagem == null) return;

    final caminho = await ImagemLocal.registrar(imagem);
    if (!mounted) return;
    setState(() {
      if (segundaImagem) {
        _imagemSelecionada2 = caminho;
      } else {
        _imagemSelecionada = caminho;
      }
    });
    _marcarComoNaoSalvo();

    await _ajustarImagem(caminho, segundaImagem: segundaImagem);
  }

  Future<void> _ajustarImagem(
    String caminho, {
    bool segundaImagem = false,
  }) async {
    final bytes = await ImagemLocal.lerBytes(caminho);
    if (bytes == null || !mounted) return;
    final ajustada = await AjusteImagemPage.abrir(context, bytes);
    if (ajustada == null || !mounted) return;
    final novoCaminho = await ImagemLocal.salvarBytes(ajustada, 'ajustada');
    if (!mounted) return;
    setState(() {
      if (segundaImagem) {
        _imagemSelecionada2 = novoCaminho;
      } else {
        _imagemSelecionada = novoCaminho;
      }
    });
    _marcarComoNaoSalvo();
  }

  Widget _buildChipAjustar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pinch, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'Ajustar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCorResultado(ThemeData theme) {
    double valorReferencia = _resultadoFQ;
    if (_equipamentoTravaQuedas) {
      if (valorReferencia > 0.01) {
        return theme.colorScheme.error;
      }
      return theme.colorScheme.secondary;
    } else {
      if (valorReferencia < 0) {
        return theme.colorScheme.onSurface;
      } else if (valorReferencia < 1) {
        return theme.colorScheme.secondary;
      } else if (valorReferencia >= 1 && valorReferencia <= 2) {
        return theme.colorScheme.tertiary;
      } else {
        return theme.colorScheme.error;
      }
    }
  }

  void _calcular() {
    double lerCampo(TextEditingController c) =>
        double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;

    final double distanciaPes = lerCampo(_controllerDistanciaPes);
    final double alturaAncoragemPes = lerCampo(_controllerAlturaAncoragem);
    final double flechaProjetoValor = _usaLinhaVidaHorizontal
        ? lerCampo(_controllerFlechaProjeto)
        : 0.0;

    final ResultadoFqZlq resultado = _equipamentoTravaQuedas
        ? calcularTravaQuedas(
            dof: lerCampo(_controllerAbsorvedor),
            aa: alturaAncoragemPes,
            c: distanciaPes,
            incluirDeformacaoCinto: _incluirDeformacaoCinto,
            flecha: flechaProjetoValor,
          )
        : calcularTalabarte(
            l: lerCampo(_controllerTalabarte),
            ea: lerCampo(_controllerAbsorvedor),
            aa: alturaAncoragemPes,
            c: distanciaPes,
            incluirDeformacaoCinto: _incluirDeformacaoCinto,
            flecha: flechaProjetoValor,
          );

    setState(() {
      _resultadoZLQAncoragem = resultado.zlqAncoragem;
      _resultadoZLQpes = resultado.zlqPes;
      _resultadoFQ = resultado.fq;
      _mensagemAlertaFQ = resultado.alerta;
    });
  }

  void _mostrarPopupAjudaImagem(
    BuildContext context,
    String caminhoImagem,
    String titulo,
    String descricao,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  caminhoImagem,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Erro ao carregar a imagem. Verifique o caminho em assets/imagens/ e a configuração no pubspec.yaml.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(descricao, textAlign: TextAlign.justify),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final String fqLabel = _equipamentoTravaQuedas
        ? 'Potencial de Queda Livre (m):'
        : 'Fator de Queda (FQ):';
    final String fqPopupTitulo = _equipamentoTravaQuedas
        ? 'Potencial de Queda Livre'
        : 'Cálculo do Fator de Queda (FQ)';
    final String fqPopupDescricao = _equipamentoTravaQuedas
        ? "Para trava-quedas, o indicador de risco mais importante é saber se existe a possibilidade de uma queda livre antes da ativação do equipamento.\n\nIsso ocorre quando o ponto de ancoragem está abaixo do Anel-D do cinto (costas do trabalhador).\n\nQualquer valor acima de 0.00m indica um risco severo e a necessidade de consultar o manual do fabricante, pois pode ser exigido um equipamento específico (Classe B / SRD-LE)."
        : "O cálculo do Fator de Queda (FQ) é o resultado da divisão entre a altura da queda (Hq) e o comprimento do talabarte (L).\n\nInterpretação:\n< 1: Queda controlada.\n= 1: Queda moderada.\n> 1: Queda severa, alto risco.";

    final Color corResultado = _getCorResultado(theme);

    String tituloAppBar;
    if (_isDuplicateMode) {
      tituloAppBar = 'Duplicar Relatório';
    } else if (_isEditMode) {
      tituloAppBar = 'Editar Relatório';
    } else {
      tituloAppBar = 'Dados da Atividade';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tituloAppBar),
        actions: [
          if (!kIsWeb)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Tooltip(
                message: _relatorioAtualSalvo
                    ? 'Relatório salvo'
                    : 'Alterações não salvas',
                child: Icon(
                  _relatorioAtualSalvo ? Icons.check_circle : Icons.add_box,
                  color: _relatorioAtualSalvo
                      ? colorScheme.secondary
                      : colorScheme.tertiary,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Todas as distâncias em metros',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controllerLocal,
                decoration: const InputDecoration(
                  labelText: 'Local da Atividade',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 200,
                child: Center(
                  child: _imagemSelecionada != null
                      ? GestureDetector(
                          onTap: () => _ajustarImagem(_imagemSelecionada!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ImagemLocal.widget(
                                  _imagemSelecionada!,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  cacheWidth: 400,
                                  cacheHeight: 400,
                                ),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: _buildChipAjustar(colorScheme),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Text(
                          'Nenhuma imagem selecionada',
                          style: textTheme.bodyMedium,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('ADICIONAR IMAGEM DO LOCAL'),
                onPressed: () => _mostrarOpcoesSelecaoImagem(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              // Segunda imagem (opcional) - seção expansível
              InkWell(
                onTap: () {
                  setState(() {
                    _mostrarSegundaImagem = !_mostrarSegundaImagem;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(100),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withAlpha(100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _mostrarSegundaImagem
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _imagemSelecionada2 != null
                              ? 'Segunda Imagem (adicionada)'
                              : 'Adicionar Segunda Imagem (opcional)',
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (_imagemSelecionada2 != null)
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
              // Conteúdo expansível da segunda imagem
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        height: 200,
                        child: Center(
                          child: _imagemSelecionada2 != null
                              ? GestureDetector(
                                  onTap: () => _ajustarImagem(
                                    _imagemSelecionada2!,
                                    segundaImagem: true,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ImagemLocal.widget(
                                          _imagemSelecionada2!,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          cacheWidth: 400,
                                          cacheHeight: 400,
                                        ),
                                        Positioned(
                                          right: 8,
                                          bottom: 8,
                                          child: _buildChipAjustar(colorScheme),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Text(
                                  'Nenhuma segunda imagem',
                                  style: textTheme.bodyMedium,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: Icon(
                          _imagemSelecionada2 != null
                              ? Icons.edit
                              : Icons.add_photo_alternate,
                        ),
                        label: Text(
                          _imagemSelecionada2 != null
                              ? 'ALTERAR SEGUNDA IMAGEM'
                              : 'ADICIONAR SEGUNDA IMAGEM',
                        ),
                        onPressed: () =>
                            _mostrarOpcoesSelecaoImagem(segundaImagem: true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: colorScheme.tertiaryContainer,
                          foregroundColor: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: _mostrarSegundaImagem
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Equipamento: Trava-quedas?'),
                subtitle: Text(
                  _equipamentoTravaQuedas
                      ? 'Modo Trava-quedas ativado.'
                      : 'Modo Talabarte com Absorvedor ativado.',
                ),
                value: _equipamentoTravaQuedas,
                onChanged: (bool novoValor) {
                  setState(() {
                    _equipamentoTravaQuedas = novoValor;
                  });
                  _marcarComoNaoSalvo();
                },
              ),
              SwitchListTile(
                title: const Text('Incluir Fator de Deformação do Cinto?'),
                subtitle: Text(
                  _incluirDeformacaoCinto
                      ? 'Sim (+0,3 m na ZLQ; adicional conservador, não previsto no exemplo do Manual da NR-35)'
                      : 'Não (fórmula do Manual da NR-35: ZLQ = f3 + a + b + c + d)',
                ),
                value: _incluirDeformacaoCinto,
                onChanged: (bool novoValor) {
                  setState(() {
                    _incluirDeformacaoCinto = novoValor;
                  });
                  _marcarComoNaoSalvo();
                },
              ),
              SwitchListTile(
                title: const Text('Ancoragem em Linha de Vida Horizontal?'),
                subtitle: Text(
                  _usaLinhaVidaHorizontal
                      ? 'Sim (Incluir Flecha de Projeto na ZLQ)'
                      : 'Não (Ancoragem rígida)',
                ),
                value: _usaLinhaVidaHorizontal,
                onChanged: (bool novoValor) {
                  setState(() {
                    _usaLinhaVidaHorizontal = novoValor;
                  });
                  _marcarComoNaoSalvo();
                },
              ),
              // Campo para Flecha de Projeto (visível apenas quando LVH está ativa)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: TextField(
                    controller: _controllerFlechaProjeto,
                    decoration: InputDecoration(
                      labelText: 'Flecha de Projeto (FLV) - metros',
                      hintText: 'Ex: 0.5 (consulte o projeto da LVH)',
                      suffixText: 'm',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                        ),
                        onPressed: () => _mostrarPopupAjudaImagem(
                          context,
                          'assets/imagens/FLV.png',
                          'Flecha de Projeto (FLV)',
                          "A Flecha de Projeto é a deflexão máxima esperada da Linha de Vida Horizontal quando submetida às forças de uma queda.\n\nEste valor deve ser obtido do projeto da linha de vida ou do manual do fabricante.\n\nA flecha é somada à ZLQ pois representa o deslocamento vertical adicional que o trabalhador sofrerá durante a retenção da queda.",
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                crossFadeState: _usaLinhaVidaHorizontal
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
              const Divider(height: 20),
              TextField(
                controller: _controllerAlturaAncoragem,
                decoration: InputDecoration(
                  labelText: 'Altura da Ancoragem aos pés (AA) - metros',
                  hintText: 'Ex: 2.0 (acima da cabeça), 0 (no chão)',
                  suffixText: 'm',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.info_outline, color: colorScheme.primary),
                    onPressed: () => _mostrarPopupAjudaImagem(
                      context,
                      'assets/imagens/AA.png',
                      'Altura da Ancoragem (AA)',
                      "Refere-se à distância vertical entre o nível onde o trabalhador está pisando (piso de trabalho) e o ponto onde o sistema de proteção contra quedas será ancorado.\n\nExemplos:\n- Ancoragem 2 metros acima do piso: Insira 2.0\n- Ancoragem ao nível dos pés (no piso): Insira 0.0\n- Ancoragem 1 metro abaixo do nível do piso: Insira -1.0",
                    ),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controllerTalabarte,
                enabled: !_equipamentoTravaQuedas,
                decoration: InputDecoration(
                  labelText: _equipamentoTravaQuedas
                      ? 'Comprimento (L) - Não aplicável'
                      : 'Comprimento do Talabarte (L) - metros',
                  hintText: _equipamentoTravaQuedas
                      ? 'Desabilitado no modo trava-quedas'
                      : 'Ex: 1.5',
                  suffixText: 'm',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.info_outline, color: colorScheme.primary),
                    onPressed: () {
                      _mostrarPopupAjudaImagem(
                        context,
                        _equipamentoTravaQuedas
                            ? 'assets/imagens/L_travaquedas.png'
                            : 'assets/imagens/L_talabarte.png',
                        _equipamentoTravaQuedas
                            ? 'Comprimento do Trava-quedas'
                            : 'Comprimento do Talabarte',
                        _equipamentoTravaQuedas
                            ? 'Para o cálculo da Zona Livre de Queda (ZLQ) com trava-quedas retráteis, o comprimento total do cabo do equipamento não é relevante para a ZLQ (apenas o DOF).\nO Potencial de Queda Livre é o indicador de risco para este tipo de operação.'
                            : "Corresponde ao comprimento total do talabarte de segurança, medido de ponta a ponta (incluindo os conectores, como ganchos ou mosquetões).\n\nVerifique este valor na etiqueta do equipamento ou no manual do fabricante.",
                      );
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controllerAbsorvedor,
                decoration: InputDecoration(
                  labelText: _equipamentoTravaQuedas
                      ? 'Distância de Operação de Freio (DOF) - metros'
                      : 'Estiramento do Absorvedor (EA) - metros',
                  hintText: _equipamentoTravaQuedas
                      ? 'Consulte o manual do trava-quedas'
                      : 'Ex: 1.2 (consulte o absorvedor)',
                  suffixText: 'm',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.info_outline, color: colorScheme.primary),
                    onPressed: () {
                      _mostrarPopupAjudaImagem(
                        context,
                        _equipamentoTravaQuedas
                            ? 'assets/imagens/DOF.png'
                            : 'assets/imagens/EA.png',
                        _equipamentoTravaQuedas
                            ? 'Distância de Operação de Freio (DOF)'
                            : 'Estiramento do Absorvedor (EA)',
                        _equipamentoTravaQuedas
                            ? "Distância máxima de deslizamento que o dispositivo trava-quedas percorre ao longo da linha de ancoragem vertical ou retrátil antes de travar completamente a queda, incluindo o alongamento dinâmico.\n\nATENÇÃO: Consulte obrigatoriamente este valor na etiqueta do equipamento ou no manual do fabricante, para obter o valor exato do DOF."
                            : "Distância máxima que o absorvedor de energia se alonga para dissipar o impacto da queda. Este valor é crítico para a segurança.\n\nATENÇÃO: Consulte obrigatoriamente este valor na etiqueta do equipamento ou no manual do fabricante, para obter o valor exato do estiramento (EA).",
                      );
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controllerDistanciaPes,
                decoration: InputDecoration(
                  labelText: 'Distância do Anel-D aos Pés (C) - metros',
                  hintText: 'Ex: 1.5',
                  suffixText: 'm',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.info_outline, color: colorScheme.primary),
                    onPressed: () => _mostrarPopupAjudaImagem(
                      context,
                      'assets/imagens/C.png',
                      'Distância do Anel-D aos Pés (C)',
                      "Medida vertical entre o ponto de conexão do cinto de segurança (Anel-D, geralmente localizado nas costas, entre as omoplatas) e a sola do calçado do trabalhador.\n\nUm valor padrão frequentemente utilizado para esta medida é 1,5 metros, mas meça no utilizador para maior precisão.",
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _calcular,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: Text(
                  '1. CALCULAR RESULTADOS',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controllerObservacoes,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText:
                      'Adicione notas ou observações sobre a atividade...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 24),
              // Seção de Assinatura Digital
              _buildSecaoAssinatura(colorScheme),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (!kIsWeb) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.save_alt),
                        label: Text(
                          _isEditMode ? 'Atualizar' : 'Salvar Relatório',
                        ),
                        onPressed: _salvarRelatorio,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: !_temPdfGerado
                        ? ElevatedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: Text(
                              _isEditMode ? 'Atualizar PDF' : 'Gerar PDF',
                            ),
                            onPressed: _salvarEGerarPdf,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: colorScheme.secondary,
                              foregroundColor: colorScheme.onSecondary,
                            ),
                          )
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.visibility),
                            label: const Text('Ver PDF'),
                            onPressed: _visualizarPdf,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: colorScheme.secondary,
                              foregroundColor: colorScheme.onSecondary,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              '$fqLabel ${_resultadoFQ < 0 ? "---" : _resultadoFQ.toStringAsFixed(2)}',
                              style: textTheme.titleLarge?.copyWith(
                                color: corResultado,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Entenda o cálculo',
                            onPressed: () => _mostrarPopupAjudaImagem(
                              context,
                              'assets/imagens/FQ.png',
                              fqPopupTitulo,
                              fqPopupDescricao,
                            ),
                          ),
                        ],
                      ),
                      if (_mensagemAlertaFQ.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            bottom: 16.0,
                          ),
                          child: Text(
                            _mensagemAlertaFQ,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const Divider(height: 20, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'ZLQ\n(desde o ponto de ancoragem):',
                              style: textTheme.titleMedium?.copyWith(
                                color: corResultado,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Entenda o cálculo da ZLQ',
                            onPressed: () {
                              _mostrarPopupAjudaImagem(
                                context,
                                'assets/imagens/ZLQ_E_F.png',
                                'Zona Livre de Queda (ZLQ)',
                                "A Zona Livre de Queda (ZLQ) é a distância vertical mínima necessária abaixo do ponto de ancoragem para que a queda seja detida com segurança. A ZLQ é a soma de todos os deslocamentos do sistema (Queda Livre, DOF ou EA, deformação do cinto) mais uma margem de segurança.",
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        '${_resultadoZLQAncoragem.toStringAsFixed(2)} metros',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: corResultado,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'F\n(distância livre desde os pés):',
                              style: textTheme.titleMedium?.copyWith(
                                color: corResultado,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Entenda o cálculo de F',
                            onPressed: () {
                              _mostrarPopupAjudaImagem(
                                context,
                                'assets/imagens/ZLQ_E_F.png',
                                'Distância Livre desde os Pés (F)',
                                "Esta é a distância vertical mínima necessária abaixo dos pés do trabalhador para evitar colisão.\n\nCorresponde à ZLQ (desde a ancoragem) subtraída da altura do ponto de ancoragem em relação aos pés (AA).",
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        '${_resultadoZLQpes.toStringAsFixed(2)} metros',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: corResultado,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Espaçamento fixo - evita rebuild ao abrir/fechar teclado
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class PaginaVisualizarPdf extends StatelessWidget {
  final String? caminhoPdf;
  final Uint8List? pdfBytes;

  const PaginaVisualizarPdf({super.key, this.caminhoPdf, this.pdfBytes})
    : assert(
        caminhoPdf != null || pdfBytes != null,
        'Informe caminhoPdf ou pdfBytes',
      );

  Future<Uint8List> _carregar() async {
    if (pdfBytes != null) return pdfBytes!;
    final bytes = await ImagemLocal.lerBytes(caminhoPdf);
    if (bytes == null) throw Exception('Arquivo não encontrado');
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visualizador de PDF')),
      body: FutureBuilder<Uint8List>(
        future: _carregar(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar o PDF: ${snapshot.error}'),
            );
          } else if (snapshot.hasData) {
            return PdfPreview(
              build: (format) => snapshot.data!,
              useActions: true,
              canChangePageFormat: false,
              pdfFileName: 'relatorio_fallcalc35.pdf',
            );
          } else {
            return const Center(
              child: Text('Não foi possível carregar o PDF.'),
            );
          }
        },
      ),
    );
  }
}
