import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key, required this.height, this.onSigningChanged});

  final double height;
  final ValueChanged<bool>? onSigningChanged;

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<Offset?> _points = <Offset?>[];
  int _pointsRevision = 0;

  bool get hasSignature {
    return _points.whereType<Offset>().length >= 2;
  }

  void clear() {
    setState(() {
      _points.clear();
      _pointsRevision++;
    });
  }

  Future<Uint8List?> exportPng() async {
    if (!hasSignature) return null;

    // Não capturar o widget pronto (que depende do tema e pode estar escuro).
    // Em vez disso, renderizar os pontos em um canvas com fundo branco para
    // uso no PDF (evita assinatura com fundo preto no tema escuro).
    final renderBox =
        _repaintKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size(300, widget.height);

    const pixelRatio = 3.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, size.width * pixelRatio, size.height * pixelRatio),
    );
    canvas.scale(pixelRatio, pixelRatio);

    // Fundo branco
    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Traço preto (boa legibilidade no PDF)
    final strokePaint = ui.Paint()
      ..color = const ui.Color(0xFF000000)
      ..strokeCap = ui.StrokeCap.round
      ..strokeWidth = 3.0
      ..style = ui.PaintingStyle.stroke;

    for (int i = 0; i < _points.length - 1; i++) {
      final p1 = _points[i];
      final p2 = _points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, strokePaint);
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (size.width * pixelRatio).round(),
      (size.height * pixelRatio).round(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Assinatura', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: clear,
              icon: const Icon(Icons.refresh),
              label: const Text('Limpar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: RawGestureDetector(
            gestures: <Type, GestureRecognizerFactory>{
              _ImmediatePanGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _ImmediatePanGestureRecognizer
                  >(() => _ImmediatePanGestureRecognizer(), (
                    _ImmediatePanGestureRecognizer instance,
                  ) {
                    instance
                      ..onStart = (details) {
                        widget.onSigningChanged?.call(true);
                        final renderBox =
                            _repaintKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        if (renderBox != null) {
                          final size = renderBox.size;
                          final pos = details.localPosition;
                          if (pos.dx >= 0 &&
                              pos.dx <= size.width &&
                              pos.dy >= 0 &&
                              pos.dy <= size.height) {
                            setState(() {
                              _points.add(pos);
                              _pointsRevision++;
                            });
                          }
                        } else {
                          setState(() {
                            _points.add(details.localPosition);
                            _pointsRevision++;
                          });
                        }
                      }
                      ..onUpdate = (details) {
                        final renderBox =
                            _repaintKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        if (renderBox != null) {
                          final size = renderBox.size;
                          final pos = details.localPosition;
                          final clampedPos = Offset(
                            pos.dx.clamp(0, size.width),
                            pos.dy.clamp(0, size.height),
                          );
                          setState(() {
                            _points.add(clampedPos);
                            _pointsRevision++;
                          });
                        } else {
                          setState(() {
                            _points.add(details.localPosition);
                            _pointsRevision++;
                          });
                        }
                      }
                      ..onEnd = (_) {
                        setState(() {
                          _points.add(null);
                          _pointsRevision++;
                        });
                        widget.onSigningChanged?.call(false);
                      }
                      ..onCancel = () {
                        setState(() {
                          _points.add(null);
                          _pointsRevision++;
                        });
                        widget.onSigningChanged?.call(false);
                      };
                  }),
            },
            child: RepaintBoundary(
              key: _repaintKey,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withAlpha(128)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: CustomPaint(
                    painter: _SignaturePainter(
                      points: _points,
                      revision: _pointsRevision,
                      strokeColor: colorScheme.onSurface,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Assine com o dedo na área acima.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withAlpha(160),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({
    required this.points,
    required this.revision,
    required this.strokeColor,
  });

  final List<Offset?> points;
  final int revision;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    // A lista `points` é mutada in-place (mesma referência). Usar um contador
    // de revisão garante repaint sempre que novos pontos forem adicionados.
    return oldDelegate.revision != revision ||
        oldDelegate.strokeColor != strokeColor;
  }
}

/// Recognizer de pan que ganha a arena de gestos imediatamente,
/// impedindo que o scroll do widget pai capture o gesto.
class _ImmediatePanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    // Resolve imediatamente como aceito para ganhar a arena
    resolve(GestureDisposition.accepted);
  }
}
