// lib/screens/pagina_dados_utilizador.dart
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:fall_calc_final/widgets/bottom_navigation_widget.dart';
import 'package:fall_calc_final/widgets/image_crop_widget.dart';

class PaginaDadosUtilizador extends StatefulWidget {
  const PaginaDadosUtilizador({super.key});

  @override
  State<PaginaDadosUtilizador> createState() => _PaginaDadosUtilizadorState();
}

class _PaginaDadosUtilizadorState extends State<PaginaDadosUtilizador> {
  final _formKey = GlobalKey<FormState>();
  final _controllerNome = TextEditingController();
  final _controllerMatricula = TextEditingController();
  final _controllerEmpresa = TextEditingController();
  final _controllerEmail = TextEditingController();
  final _controllerMunicipio = TextEditingController();

  final List<String> _estadosBrasileiros = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  ];
  String? _estadoSelecionado;
  File? _imagemPerfil;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _controllerNome.dispose();
    _controllerMatricula.dispose();
    _controllerEmpresa.dispose();
    _controllerEmail.dispose();
    _controllerMunicipio.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _controllerNome.text = prefs.getString('nome') ?? '';
      _controllerMatricula.text = prefs.getString('matricula') ?? '';
      _controllerEmpresa.text = prefs.getString('empresa') ?? '';
      _controllerEmail.text = prefs.getString('email') ?? '';
      _estadoSelecionado = prefs.getString('estado');
      _controllerMunicipio.text = prefs.getString('municipio') ?? '';
      final caminhoImagem = prefs.getString('caminho_imagem_perfil');
      if (!kIsWeb &&
          caminhoImagem != null &&
          File(caminhoImagem).existsSync()) {
        _imagemPerfil = File(caminhoImagem);
      }
    });
  }

  Future<void> _salvarDados() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Capturar colorScheme antes das operações assíncronas
      final colorScheme = Theme.of(context).colorScheme;

      final prefs = await SharedPreferences.getInstance();
      if (!kIsWeb && _imagemPerfil != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final nomeFicheiro = path.basename(_imagemPerfil?.path ?? '');
        final caminhoSalvo = path.join(appDir.path, nomeFicheiro);
        if (caminhoSalvo != (_imagemPerfil?.path ?? '')) {
          await _imagemPerfil?.copy(caminhoSalvo);
        }
        await prefs.setString('caminho_imagem_perfil', caminhoSalvo);
      }

      await prefs.setString('nome', _controllerNome.text);
      await prefs.setString('matricula', _controllerMatricula.text);
      await prefs.setString('email', _controllerEmail.text);
      if (!kIsWeb) {
        await prefs.setString('empresa', _controllerEmpresa.text);
        if (_estadoSelecionado != null) {
          await prefs.setString('estado', _estadoSelecionado!);
        }
        await prefs.setString('municipio', _controllerMunicipio.text);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dados salvos com sucesso!',
            style: TextStyle(color: colorScheme.onSecondaryContainer),
          ),
          backgroundColor: colorScheme.secondaryContainer,
        ),
      );
    }
  }

  Future<void> _pegarImagem(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(
      source: source,
      imageQuality: 90,
      maxHeight: 1024,
      maxWidth: 1024,
    );

    if (imagem != null) {
      final File imageFile = File(imagem.path);

      if (!mounted) return;

      // Navegar para a tela de crop
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImageCropWidget(
            imageFile: imageFile,
            onImageCropped: (File croppedFile) {
              setState(() {
                _imagemPerfil = croppedFile;
              });
            },
          ),
        ),
      );
    }
  }

  void _mostrarOpcoesSelecaoImagem() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Selecionar Foto de Perfil',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildImageOption(
                              context,
                              icon: Icons.photo_library,
                              label: 'Galeria',
                              onTap: () {
                                Navigator.of(context).pop();
                                _pegarImagem(ImageSource.gallery);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildImageOption(
                              context,
                              icon: Icons.photo_camera,
                              label: 'Câmera',
                              onTap: () {
                                Navigator.of(context).pop();
                                _pegarImagem(ImageSource.camera);
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_imagemPerfil != null) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildImageOption(
                            context,
                            icon: Icons.delete_outline,
                            label: 'Remover Foto',
                            onTap: () {
                              Navigator.of(context).pop();
                              setState(() {
                                _imagemPerfil = null;
                              });
                            },
                            isDestructive: true,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Seus Dados'), elevation: 4),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                if (kIsWeb)
                  Card(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Estes dados são usados apenas para identificar o responsável nos relatórios em PDF e ficam salvos somente neste navegador.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 65,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              backgroundImage: _imagemPerfil != null
                                  ? FileImage(_imagemPerfil!)
                                  : null,
                              child: _imagemPerfil == null
                                  ? Icon(
                                      Icons.person,
                                      size: 70,
                                      color: colorScheme.onSurfaceVariant,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: _mostrarOpcoesSelecaoImagem,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: colorScheme.primary,
                                  child: Icon(
                                    _imagemPerfil == null
                                        ? Icons.add_a_photo
                                        : Icons.edit,
                                    color: colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                _buildSectionCard(
                  context,
                  title: 'Identificação',
                  children: [
                    _buildTextField(
                      controller: _controllerNome,
                      label: 'Nome Completo',
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 16),
                    if (kIsWeb) ...[
                      _buildTextField(
                        controller: _controllerMatricula,
                        label: 'Matrícula',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _controllerEmail,
                        label: 'Contato (e-mail ou telefone)',
                        icon: Icons.contact_mail_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ] else
                      _buildTextField(
                        controller: _controllerEmail,
                        label: 'E-mail',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              !value.contains('@')) {
                            return 'Por favor, insira um e-mail válido';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: 'Informações Profissionais',
                    children: [
                      _buildTextField(
                        controller: _controllerEmpresa,
                        label: 'Empresa',
                        icon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _controllerMatricula,
                        label: 'Matrícula',
                        icon: Icons.badge_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: 'Localização',
                    children: [
                      _buildDropdownField(context),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _controllerMunicipio,
                        label: 'Município',
                        icon: Icons.location_city_outlined,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar dados'),
                  onPressed: _salvarDados,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 3),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo é obrigatório';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Estado',
        prefixIcon: const Icon(Icons.map_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      initialValue: _estadoSelecionado,
      items: _estadosBrasileiros.map((String estado) {
        return DropdownMenuItem<String>(value: estado, child: Text(estado));
      }).toList(),
      onChanged: (String? novoValor) {
        setState(() {
          _estadoSelecionado = novoValor;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione um estado';
        }
        return null;
      },
    );
  }
}
