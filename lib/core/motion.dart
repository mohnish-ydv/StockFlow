import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Motion primitives for StockFlow.
///
/// Motion is deliberately semantic: status changes can be expressive, while
/// high-frequency actions stay short and quiet. All custom motion respects the
/// platform "reduce motion" preference exposed by MediaQuery.disableAnimations.
class SfMotion {
  static const quick = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const emphasized = Duration(milliseconds: 420);

  static bool reduce(BuildContext context) => MediaQuery.of(context).disableAnimations;
}

class SfAnimatedHourglass extends StatefulWidget {
  final double size;
  final Color color;

  const SfAnimatedHourglass({
    super.key,
    this.size = 72,
    this.color = StockFlowTheme.accent,
  });

  @override
  State<SfAnimatedHourglass> createState() => _SfAnimatedHourglassState();
}

class _SfAnimatedHourglassState extends State<SfAnimatedHourglass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (SfMotion.reduce(context)) {
      return SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _HourglassPainter(progress: .48, color: widget.color),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        final sand = value <= .78 ? value / .78 : 1.0;
        final flip = value <= .78 ? 0.0 : ((value - .78) / .22).clamp(0.0, 1.0);
        final easedFlip = Curves.easeInOutCubic.transform(flip);
        return Transform.rotate(
          angle: math.pi * easedFlip,
          child: SizedBox.square(
            dimension: widget.size,
            child: CustomPaint(
              painter: _HourglassPainter(progress: sand, color: widget.color),
            ),
          ),
        );
      },
    );
  }
}

class _HourglassPainter extends CustomPainter {
  final double progress;
  final Color color;

  _HourglassPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final left = w * .22;
    final right = w * .78;
    final top = h * .17;
    final bottom = h * .83;
    final neckY = h * .50;
    final neckLeft = w * .46;
    final neckRight = w * .54;

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, w * .045)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF47514B);

    final frame = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(neckRight, neckY)
      ..lineTo(right, bottom)
      ..lineTo(left, bottom)
      ..lineTo(neckLeft, neckY)
      ..close();
    canvas.drawPath(frame, outline);

    final cap = Paint()
      ..color = const Color(0xFF313934)
      ..strokeWidth = math.max(3.0, w * .065)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left - w * .05, top - h * .04), Offset(right + w * .05, top - h * .04), cap);
    canvas.drawLine(Offset(left - w * .05, bottom + h * .04), Offset(right + w * .05, bottom + h * .04), cap);

    final sandPaint = Paint()..color = color;
    final p = progress.clamp(0.0, 1.0);

    // Upper sand shrinks down toward the neck.
    final upperTop = top + (neckY - top) * p;
    if (p < .995) {
      final upper = Path()
        ..moveTo(left + w * .055, upperTop)
        ..lineTo(right - w * .055, upperTop)
        ..lineTo(neckRight - w * .01, neckY - h * .018)
        ..lineTo(neckLeft + w * .01, neckY - h * .018)
        ..close();
      canvas.drawPath(upper, sandPaint);
    }

    // Lower pile grows naturally from the bottom.
    final pileHeight = (bottom - neckY) * (.16 + .76 * p);
    final pileY = bottom - pileHeight;
    final half = (right - left) * (.13 + .34 * p);
    final lower = Path()
      ..moveTo(w / 2, pileY)
      ..lineTo(w / 2 + half, bottom - h * .035)
      ..lineTo(w / 2 - half, bottom - h * .035)
      ..close();
    canvas.drawPath(lower, sandPaint);

    if (p > .02 && p < .985) {
      final stream = Paint()
        ..color = color
        ..strokeWidth = math.max(1.4, w * .027)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(w / 2, neckY - h * .018),
        Offset(w / 2, pileY + h * .018),
        stream,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class SfOrderSuccessMotion extends StatefulWidget {
  final double size;

  const SfOrderSuccessMotion({super.key, this.size = 220});

  @override
  State<SfOrderSuccessMotion> createState() => _SfOrderSuccessMotionState();
}

class _SfOrderSuccessMotionState extends State<SfOrderSuccessMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (SfMotion.reduce(context)) {
      return SizedBox.square(
        dimension: widget.size,
        child: const Center(child: _SuccessBadge(progress: 1)),
      );
    }
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final v = _controller.value;
          final boxIn = Curves.easeOutBack.transform((v / .34).clamp(0.0, 1.0));
          final check = Curves.easeOutBack.transform(((v - .28) / .34).clamp(0.0, 1.0));
          final confetti = ((v - .42) / .58).clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _ConfettiPainter(progress: confetti),
              ),
              Transform.translate(
                offset: Offset(0, 10 * (1 - boxIn)),
                child: Transform.scale(
                  scale: .72 + .28 * boxIn,
                  child: Opacity(
                    opacity: boxIn.clamp(0.0, 1.0),
                    child: Container(
                      width: 112,
                      height: 94,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E5C9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD7C49B)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x18000000), blurRadius: 24, offset: Offset(0, 12)),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 0,
                            bottom: 0,
                            child: Container(width: 22, color: const Color(0xFFE0C581)),
                          ),
                          const Icon(Icons.inventory_2_rounded, size: 48, color: Color(0xFF755B28)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 34,
                bottom: 42,
                child: Transform.scale(
                  scale: check,
                  child: _SuccessBadge(progress: check),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  final double progress;
  const _SuccessBadge({required this.progress});

  @override
  Widget build(BuildContext context) => Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: StockFlowTheme.accent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: const [BoxShadow(color: Color(0x281769FF), blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
      );
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  const _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    const palette = [
      Color(0xFF1769FF),
      Color(0xFFE3A12B),
      Color(0xFF5E83C7),
      Color(0xFFE46F62),
      Color(0xFF7A66B7),
    ];
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 18; i++) {
      final angle = i * (math.pi * 2 / 18) + (i.isEven ? .08 : -.05);
      final distance = size.width * (.18 + .31 * Curves.easeOutCubic.transform(progress));
      final drift = math.sin(progress * math.pi + i) * 7;
      final point = Offset(
        center.dx + math.cos(angle) * distance + drift,
        center.dy + math.sin(angle) * distance + progress * 16,
      );
      final alpha = (1 - ((progress - .72).clamp(0.0, .28) / .28)).clamp(0.0, 1.0);
      final paint = Paint()..color = palette[i % palette.length].withValues(alpha: alpha);
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + progress * 2.4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-3.5, -7, 7, 14), const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class SfShimmer extends StatefulWidget {
  final Widget child;

  const SfShimmer({super.key, required this.child});

  @override
  State<SfShimmer> createState() => _SfShimmerState();
}

class _SfShimmerState extends State<SfShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (SfMotion.reduce(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final x = -1.0 + _controller.value * 3.0;
          return LinearGradient(
            begin: Alignment(x - 1, 0),
            end: Alignment(x + 1, 0),
            colors: const [Color(0xFFE8EBE7), Color(0xFFF8F9F7), Color(0xFFE8EBE7)],
            stops: const [0, .5, 1],
          ).createShader(rect);
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}

class SfScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const SfScaleTap({super.key, required this.child, this.onTap, this.borderRadius});

  @override
  State<SfScaleTap> createState() => _SfScaleTapState();
}

class _SfScaleTapState extends State<SfScaleTap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = SfMotion.reduce(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      child: AnimatedScale(
        duration: reduce ? Duration.zero : SfMotion.quick,
        curve: Curves.easeOutCubic,
        scale: _down ? .982 : 1,
        child: widget.child,
      ),
    );
  }
}

class SfFadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;

  const SfFadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    if (SfMotion.reduce(context)) return child;
    final delayFactor = math.min(index, 8) / 8;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (delayFactor * 150).round()),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 10 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}
