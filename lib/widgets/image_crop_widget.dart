// lib/widgets/image_crop_widget.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ImageCropWidget extends StatefulWidget {
  final File imageFile;
  final Function(File) onImageCropped;

  const ImageCropWidget({
    super.key,
    required this.imageFile,
    required this.onImageCropped,
  });

  @override
  State<ImageCropWidget> createState() => _ImageCropWidgetState();
}

class _ImageCropWidgetState extends State<ImageCropWidget> {
  final GlobalKey _cropKey = GlobalKey();
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  Offset _startOffset = Offset.zero;
  double _startScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Editar Foto de Perfil'),
        actions: [
          TextButton(
            onPressed: _cropAndSave,
            child: const Text(
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
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(150),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(150),
                  child: RepaintBoundary(
                    key: _cropKey,
                    child: GestureDetector(
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.translationValues(
                            _offset.dx,
                            _offset.dy,
                            0.0,
                          )..scaleByDouble(_scale, _scale, 1.0, 1.0),
                          child: Image.file(
                            widget.imageFile,
                            fit: BoxFit.cover,
                            width: 300,
                            height: 300,
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Ajustar Foto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.zoom_out, color: Colors.white),
                    Expanded(
                      child: Slider(
                        value: _scale,
                        min: 0.5,
                        max: 3.0,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white38,
                        onChanged: (value) {
                          setState(() {
                            _scale = value;
                          });
                        },
                      ),
                    ),
                    const Icon(Icons.zoom_in, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.refresh,
                      label: 'Resetar',
                      onPressed: _resetTransform,
                    ),
                    _buildControlButton(
                      icon: Icons.center_focus_strong,
                      label: 'Centralizar',
                      onPressed: _centerImage,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Use dois dedos para zoom ou arraste para posicionar',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white24,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startFocalPoint = details.focalPoint;
    _startOffset = _offset;
    _startScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Atualizar escala
      _scale = (_startScale * details.scale).clamp(0.5, 3.0);

      // Atualizar posição
      final delta = details.focalPoint - _startFocalPoint;
      _offset = _startOffset + delta;
    });
  }

  void _resetTransform() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  void _centerImage() {
    setState(() {
      _offset = Offset.zero;
    });
  }

  Future<void> _cropAndSave() async {
    try {
      // Capturar a imagem do widget
      final cropContext = _cropKey.currentContext;
      if (cropContext == null) return;
      final RenderRepaintBoundary boundary =
          cropContext.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // Criar arquivo temporário
        final tempFile = File(
          '${widget.imageFile.parent.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await tempFile.writeAsBytes(pngBytes);

        // Retornar o arquivo cropado
        widget.onImageCropped(tempFile);

        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
