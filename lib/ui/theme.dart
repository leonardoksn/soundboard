import 'package:flutter/material.dart';

/// Tokens de design do soundboard — estética de sampler/drum machine 80s
/// (Roland TR-808 / Akai MPC). A tela inteira é o chassi de um equipamento:
/// grafite escuro, serigrafia creme e a faixa de cores assinatura da 808.
class BoardColors {
  BoardColors._();

  /// Poço recuado onde mora o grid de pads (o tom mais escuro).
  static const well = Color(0xFF1A1820);

  /// Corpo do chassi / faceplate (grafite).
  static const chassis = Color(0xFF26242B);

  /// Borracha do pad: base (sombra) e topo (luz).
  static const padBase = Color(0xFF302E38);
  static const padTop = Color(0xFF3C3A45);

  /// Serigrafia creme — todo texto de label.
  static const cream = Color(0xFFEDE7DB);

  /// Creme apagado, para textos secundários.
  static const creamDim = Color(0xFF8A857C);

  /// Vermelho de alerta / transporte (REC).
  static const rec = Color(0xFFD8412F);

  /// Faixa-assinatura da 808 (vermelho → laranja → amarelo → branco-osso).
  static const band = <Color>[
    Color(0xFFD8412F),
    Color(0xFFE8823A),
    Color(0xFFE6B34A),
    Color(0xFFEDE7DB),
  ];
}

/// Estilos tipográficos. Oswald condensada UPPERCASE = serigrafia;
/// Share Tech Mono = visor digital.
class BoardText {
  BoardText._();

  static const _label = 'Oswald';
  static const _mono = 'ShareTechMono';

  /// Label do pad (uppercase, condensada, espaçada).
  static const padLabel = TextStyle(
    fontFamily: _label,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: 1.2,
    height: 1.05,
    color: BoardColors.cream,
  );

  /// Wordmark da faceplate.
  static const wordmark = TextStyle(
    fontFamily: _label,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    letterSpacing: 3,
    color: BoardColors.cream,
  );

  /// Rótulos de campo/serigrafia menores.
  static const stencil = TextStyle(
    fontFamily: _label,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    letterSpacing: 2,
    color: BoardColors.creamDim,
  );

  /// Visor digital (nome do som tocando / READY).
  static const readout = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    letterSpacing: 1,
    color: BoardColors.cream,
  );
}

/// Tema Material escuro derivado dos tokens de hardware.
ThemeData buildBoardTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BoardColors.rec,
    brightness: Brightness.dark,
  ).copyWith(
    surface: BoardColors.chassis,
    primary: BoardColors.rec,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: BoardColors.chassis,
    fontFamily: 'Oswald',
  );
}
