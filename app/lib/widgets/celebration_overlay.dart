import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Brief (~900ms), non-intrusive celebration shown after a rating is
/// recorded. [intense] adds a few extra sparkles for the +2 case — still
/// short, per the "pas de grosses animations longues" rule.
void showCelebration(
  BuildContext context, {
  required String emoji,
  required String message,
  bool intense = false,
  bool negative = false,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _CelebrationWidget(
      emoji: emoji,
      message: message,
      intense: intense,
      negative: negative,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);

  if (!negative) {
    HapticFeedback.lightImpact();
  } else {
    HapticFeedback.selectionClick();
  }
}

class _CelebrationWidget extends StatefulWidget {
  final String emoji;
  final String message;
  final bool intense;
  final bool negative;
  final VoidCallback onDone;

  const _CelebrationWidget({
    required this.emoji,
    required this.message,
    required this.intense,
    required this.negative,
    required this.onDone,
  });

  @override
  State<_CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<_CelebrationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _sparkleCount => widget.intense ? 10 : (widget.negative ? 0 : 5);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  final scale = t < 0.3
                      ? 0.6 + (t / 0.3) * 0.6
                      : (t < 0.7 ? 1.2 : 1.2 - ((t - 0.7) / 0.3) * 1.2);
                  final opacity = t < 0.7 ? 1.0 : 1.0 - ((t - 0.7) / 0.3);
                  return Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: scale.clamp(0.0, 1.3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.emoji, style: const TextStyle(fontSize: 48)),
                            const SizedBox(height: 8),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          for (var i = 0; i < _sparkleCount; i++) _sparkle(context, i),
        ],
      ),
    );
  }

  Widget _sparkle(BuildContext context, int index) {
    final size = MediaQuery.of(context).size;
    final angle = (index / _sparkleCount) * 2 * pi + _random.nextDouble();
    final distance = 90.0 + _random.nextDouble() * 60;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value);
        final dx = cos(angle) * distance * t;
        final dy = sin(angle) * distance * t;
        final opacity = (1 - _controller.value).clamp(0.0, 1.0);
        return Positioned(
          left: size.width / 2 + dx - 10,
          top: size.height / 2 + dy - 10,
          child: Opacity(
            opacity: opacity,
            child: const Text('✨', style: TextStyle(fontSize: 18)),
          ),
        );
      },
    );
  }
}
