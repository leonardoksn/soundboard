import 'dart:math';
import 'package:flutter/material.dart';

/// Barras verticais animadas (estilo equalizador) exibidas enquanto um som toca.
class EqualizerBars extends StatefulWidget {
  final Color color;
  const EqualizerBars({super.key, this.color = Colors.white});

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  static const int _barCount = 5;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_barCount, (i) {
              final phase = i / _barCount;
              final t = (_controller.value + phase) % 1.0;
              final height = 4 + 16 * (0.5 - 0.5 * cos(2 * pi * t));
              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
