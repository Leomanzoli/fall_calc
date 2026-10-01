// lib/widgets/ajuste_imagem_widget.dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Tela para enquadrar uma imagem num quadro retangular usando gestos de
/// pinça (zoom com dois dedos) e arrastar. Retorna os bytes PNG recortados via
/// [Navigator.pop] ou `null` se o usuário cancelar.
class AjusteImagemPage extends StatefulWidget {
  final Uint8List imageBytes;
  final double frameHeight;
  final double horizontalPadding;

  const AjusteImagemPage({
    super.key,
    required this.imageBytes,
    this.frameHeight = 200,
    this.horizontalPadding = 16,
  });

  static Future<Uint8List?> abrir(
    BuildContext context,
    Uint8List imageBytes, {
    double frameHeight = 200,
    double horizontalPadding = 16,
  }) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => AjusteImagemPage(
          imageBytes: imageBytes,
          frameHeight: frameHeight,
          horizontalPadding: horizontalPadding,
        ),
      ),
    );
  }

  @override
  State<AjusteImagemPage> createState() => _AjusteImagemPageState();
}

class _AjusteImagemPageState extends State<AjusteImagemPage> {
  final GlobalKey _frameKey = GlobalKey();
  final TransformationController _transform = TransformationController();
  late final Future<ui.Image> _decoded;
  bool _salvando = false;
  Size? _childSize;
  Size? _frameSize;

  @override
  void initState() {
    super.initState();
    _decoded = _decodeImage();
  }

  Future<ui.Image> _decodeImage() async {
    return decodeImageFromList(widget.imageBytes);
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Dimensões do conteúdo para que a imagem cubra o quadro inteiro (cover).
  Size _coverSize(ui.Image img, Size frame) {
    final imgAspect = img.width / img.height;
    final frameAspect = frame.width / frame.height;
    if (imgAspect > frameAspect) {
      return Size(frame.height * imgAspect, frame.height);
    }
    return Size(frame.width, frame.width / imgAspect);
  }

  void _centralizar() {
    final child = _childSize;
    final frame = _frameSize;
    if (child == null || frame == null) return;
    _transform.value = Matrix4.translationValues(
      -(child.width - frame.width) / 2,
      -(child.height - frame.height) / 2,
      0,
    );
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      final boundary =
          _frameKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      if (!mounted) return;
      Navigator.of(context).pop(pngBytes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao ajustar imagem: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final frameWidth =
        MediaQuery.sizeOf(context).width - (widget.horizontalPadding * 2);
    final frame = Size(frameWidth, widget.frameHeight);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ajustar Imagem'),
        actions: [
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Salvar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: FutureBuilder<ui.Image>(
        future: _decoded,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Não foi possível carregar a imagem.',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final child = _coverSize(snapshot.data!, frame);
          if (_childSize != child || _frameSize != frame) {
            _childSize = child;
            _frameSize = frame;
            // Centraliza a imagem no primeiro layout (ou após rotação).
            WidgetsBinding.instance.addPostFrameCallback((_) => _centralizar());
          }

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: frame.width,
                    height: frame.height,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: RepaintBoundary(
                        key: _frameKey,
                        child: SizedBox(
                          width: frame.width,
                          height: frame.height,
                          child: InteractiveViewer(
                            transformationController: _transform,
                            constrained: false,
                            boundaryMargin: EdgeInsets.zero,
                            minScale: 1.0,
                            maxScale: 5.0,
                            child: SizedBox(
                              width: child.width,
                              height: child.height,
                              child: Image.memory(
                                widget.imageBytes,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                                cacheWidth: 2048,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pinch, color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'Use dois dedos para aproximar ou afastar e arraste para posicionar a imagem no quadro.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: _centralizar,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text(
                              'Redefinir',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text(
                              'Manter original',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
