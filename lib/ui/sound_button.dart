import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/sound.dart';
import 'equalizer_bars.dart';
import 'theme.dart';

/// Um pad de borracha do sampler. Corpo grafite uniforme; a cor do som
/// aparece como LED (canto) e no glow do equalizador. Afunda ao toque.
class SoundButton extends StatefulWidget {
  final Sound sound;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final bool isPlaying;

  const SoundButton({
    super.key,
    required this.sound,
    required this.onTap,
    required this.onEdit,
    this.isPlaying = false,
  });

  @override
  State<SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<SoundButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final led = Color(widget.sound.color);
    final lit = widget.isPlaying;
    final noAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final down = _pressed && !noAnim;

    return Semantics(
      button: true,
      label: widget.sound.name,
      hint: widget.isPlaying ? l10n.stop : l10n.play,
      child: GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: down ? 0.96 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: down
                  ? const [BoardColors.padBase, BoardColors.padBase]
                  : const [BoardColors.padTop, BoardColors.padBase],
            ),
            border: Border.all(
              color: lit ? led.withValues(alpha: 0.55) : Colors.black26,
              width: lit ? 1.5 : 1,
            ),
            boxShadow: down
                ? const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                : [
                    // sombra projetada (pad saliente)
                    const BoxShadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 5),
                    ),
                    // brilho do LED aceso, transbordando
                    if (lit)
                      BoxShadow(
                        color: led.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                  ],
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 22,
                  ),
                  child: Text(
                    widget.sound.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BoardText.padLabel,
                  ),
                ),
              ),
              // LED de status no canto superior direito
              Positioned(
                top: 8,
                right: 8,
                child: _Led(color: led, lit: lit),
              ),
              // botão de edição recuado, canto superior esquerdo
              Positioned(
                top: -2,
                left: -2,
                child: IconButton(
                  icon: const Icon(Icons.tune, size: 16),
                  color: BoardColors.creamDim,
                  tooltip: AppLocalizations.of(context).editTooltip,
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onEdit,
                ),
              ),
              if (widget.sound.loop)
                const Positioned(
                  left: 8,
                  bottom: 8,
                  child: Icon(Icons.loop, size: 13, color: BoardColors.creamDim),
                ),
              if (widget.isPlaying)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: EqualizerBars(color: led),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// LED redondo: aceso (cor cheia + halo) quando o som toca, apagado quando não.
class _Led extends StatelessWidget {
  final Color color;
  final bool lit;
  const _Led({required this.color, required this.lit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? color : color.withValues(alpha: 0.28),
        boxShadow: lit
            ? [BoxShadow(color: color.withValues(alpha: 0.9), blurRadius: 8)]
            : null,
      ),
    );
  }
}
