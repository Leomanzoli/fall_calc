// lib/utils/imagem_local.dart
//
// Abstração para fotos escolhidas pelo usuário. Os modelos continuam a guardar
// apenas uma `String` (caminho); no Android é um arquivo em disco, na web é uma
// chave em memória. Assim, telas e geradores de PDF não precisam de `dart:io`.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'imagem_local_io.dart'
    if (dart.library.js_interop) 'imagem_local_web.dart'
    as impl;

class ImagemLocal {
  ImagemLocal._();

  /// Registra uma imagem vinda do image_picker e devolve o caminho a persistir.
  static Future<String> registrar(XFile arquivo) => impl.registrar(arquivo);

  /// Persiste bytes (ex.: imagem ajustada) e devolve o caminho a persistir.
  static Future<String> salvarBytes(Uint8List bytes, String nomeBase) =>
      impl.salvarBytes(bytes, nomeBase);

  /// Persiste um arquivo qualquer (ex.: PDF) com o nome exato informado.
  static Future<String> salvarArquivo(Uint8List bytes, String nomeArquivo) =>
      impl.salvarArquivo(bytes, nomeArquivo);

  /// Lê os bytes de um caminho previamente registrado; `null` se não existir.
  static Future<Uint8List?> lerBytes(String? caminho) => impl.lerBytes(caminho);

  /// Verifica (de forma síncrona) se o caminho ainda aponta para uma imagem.
  static bool existe(String? caminho) => impl.existe(caminho);

  /// Widget de exibição equivalente a `Image.file`/`Image.memory`.
  static Widget widget(
    String caminho, {
    BoxFit? fit,
    double? width,
    double? height,
    int? cacheWidth,
    int? cacheHeight,
    ImageErrorWidgetBuilder? errorBuilder,
  }) {
    return impl.widget(
      caminho,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: errorBuilder,
    );
  }
}
