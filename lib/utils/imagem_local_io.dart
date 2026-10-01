// lib/utils/imagem_local_io.dart
// Implementação para Android/iOS/desktop: arquivos em disco.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<String> registrar(XFile arquivo) async => arquivo.path;

Future<String> salvarBytes(Uint8List bytes, String nomeBase) async {
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/${nomeBase}_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes);
  return file.path;
}

Future<String> salvarArquivo(Uint8List bytes, String nomeArquivo) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$nomeArquivo');
  await file.writeAsBytes(bytes);
  return file.path;
}

Future<Uint8List?> lerBytes(String? caminho) async {
  if (caminho == null || caminho.isEmpty) return null;
  final file = File(caminho);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

bool existe(String? caminho) {
  if (caminho == null || caminho.isEmpty) return false;
  return File(caminho).existsSync();
}

Widget widget(
  String caminho, {
  BoxFit? fit,
  double? width,
  double? height,
  int? cacheWidth,
  int? cacheHeight,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return Image.file(
    File(caminho),
    fit: fit,
    width: width,
    height: height,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    errorBuilder: errorBuilder,
  );
}
