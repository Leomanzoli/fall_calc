// lib/utils/imagem_local_web.dart
// Implementação para Flutter Web: bytes mantidos em memória durante a sessão.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

final Map<String, Uint8List> _cache = <String, Uint8List>{};
int _seq = 0;

String _novaChave(String nomeBase) =>
    'mem://${nomeBase}_${DateTime.now().millisecondsSinceEpoch}_${_seq++}';

Future<String> registrar(XFile arquivo) async {
  final bytes = await arquivo.readAsBytes();
  final chave = _novaChave('foto');
  _cache[chave] = bytes;
  return chave;
}

Future<String> salvarBytes(Uint8List bytes, String nomeBase) async {
  final chave = _novaChave(nomeBase);
  _cache[chave] = bytes;
  return chave;
}

Future<String> salvarArquivo(Uint8List bytes, String nomeArquivo) async {
  final chave = 'mem://$nomeArquivo';
  _cache[chave] = bytes;
  return chave;
}

Future<Uint8List?> lerBytes(String? caminho) async {
  if (caminho == null || caminho.isEmpty) return null;
  return _cache[caminho];
}

bool existe(String? caminho) =>
    caminho != null && caminho.isNotEmpty && _cache.containsKey(caminho);

Widget widget(
  String caminho, {
  BoxFit? fit,
  double? width,
  double? height,
  int? cacheWidth,
  int? cacheHeight,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  final bytes = _cache[caminho];
  if (bytes == null) {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
  return Image.memory(
    bytes,
    fit: fit,
    width: width,
    height: height,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    errorBuilder: errorBuilder,
    gaplessPlayback: true,
  );
}
