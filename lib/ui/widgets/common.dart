import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/pillars.dart';

/// REWIND wordmark on a black pill.
class RewindLogo extends StatelessWidget {
  const RewindLogo({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(color: RC.ink, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: compact ? 8 : 10,
          height: compact ? 8 : 10,
          decoration: const BoxDecoration(color: RC.lime, shape: BoxShape.circle),
        ),
        SizedBox(width: compact ? 8 : 10),
        Text('REWIND',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                fontSize: compact ? 13 : 15)),
      ]),
    );
  }
}

/// White rounded card.
class RCard extends StatelessWidget {
  const RCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.color, this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? RC.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RC.line.withValues(alpha: 0.6)),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(24), onTap: onTap, child: card),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Small rounded label.
class Chip2 extends StatelessWidget {
  const Chip2(this.text, {super.key, this.color = RC.limeSoft, this.fg = RC.ink});
  final String text;
  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      );
}

/// Circular score gauge.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 180, this.label = 'Longevity Score', this.dark = false});
  final int score;
  final double size;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : RC.ink;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v, dark),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${(v * 100).round()}',
                  style: TextStyle(fontSize: size * 0.3, fontWeight: FontWeight.w800, color: fg, height: 1)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: math.max(11, size * 0.065),
                      color: dark ? Colors.white70 : RC.muted,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.dark);
  final double value;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.075;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = dark ? Colors.white12 : RC.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = RC.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;
    canvas.drawArc(r, start, sweep, false, track);
    if (value > 0) canvas.drawArc(r, start, sweep * value.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value || old.dark != dark;
}

/// Horizontal progress bar for a 0–100 pillar score.
class PillarBar extends StatelessWidget {
  const PillarBar({super.key, required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value / 100,
        minHeight: 8,
        backgroundColor: RC.line,
        valueColor: AlwaysStoppedAnimation(value >= 55 ? RC.ink : const Color(0xFF9AA08F)),
      ),
    );
  }
}

/// 8-axis radar of pillar scores.
class PillarRadar extends StatelessWidget {
  const PillarRadar({super.key, required this.scores, this.size = 280});
  final Map<Pillar, int> scores;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RadarPainter(scores)),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.scores);
  final Map<Pillar, int> scores;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 34;
    final n = Pillar.values.length;
    Offset pt(int i, double r) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      return c + Offset(math.cos(a) * r, math.sin(a) * r);
    }

    final grid = Paint()
      ..color = RC.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final f in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = pt(i, radius * f);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, pt(i, radius), grid);
    }

    final shape = Path();
    for (var i = 0; i < n; i++) {
      final v = (scores[Pillar.values[i]] ?? 0) / 100;
      final p = pt(i, radius * v);
      i == 0 ? shape.moveTo(p.dx, p.dy) : shape.lineTo(p.dx, p.dy);
    }
    shape.close();
    canvas.drawPath(shape, Paint()..color = RC.lime.withValues(alpha: 0.55));
    canvas.drawPath(
        shape,
        Paint()
          ..color = RC.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    for (var i = 0; i < n; i++) {
      final tp = TextPainter(
        text: TextSpan(
            text: Pillar.values[i].short,
            style: const TextStyle(fontSize: 11, color: RC.muted, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = pt(i, radius + 18);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.scores != scores;
}

/// Simple line chart for score history.
class ScoreLineChart extends StatelessWidget {
  const ScoreLineChart({super.key, required this.values, this.height = 180});
  final List<int> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _LinePainter(values)),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values);
  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 28.0, padB = 8.0, padT = 8.0;
    final w = size.width - padL;
    final h = size.height - padB - padT;
    final grid = Paint()
      ..color = RC.line
      ..strokeWidth = 1;
    for (final g in [0, 25, 50, 75, 100]) {
      final y = padT + h - h * g / 100;
      canvas.drawLine(Offset(padL, y), Offset(size.width, y), grid);
      final tp = TextPainter(
        text: TextSpan(text: '$g', style: const TextStyle(fontSize: 10, color: RC.muted)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    if (values.isEmpty) return;
    final pts = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? padL + w / 2 : padL + w * i / (values.length - 1);
      final y = padT + h - h * values[i].clamp(0, 100) / 100;
      pts.add(Offset(x, y));
    }
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(line)
      ..lineTo(pts.last.dx, padT + h)
      ..lineTo(pts.first.dx, padT + h)
      ..close();
    canvas.drawPath(fill, Paint()..color = RC.lime.withValues(alpha: 0.35));
    canvas.drawPath(
        line,
        Paint()
          ..color = RC.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round);
    canvas.drawCircle(pts.last, 5, Paint()..color = RC.ink);
    canvas.drawCircle(pts.last, 3, Paint()..color = RC.lime);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.values != values;
}

/// Renders an AsyncValue with consistent loading/error states.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(color: RC.ink, strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, color: RC.muted),
          const SizedBox(height: 8),
          Text('Something went wrong.\n$e', textAlign: TextAlign.center,
              style: const TextStyle(color: RC.muted)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ]),
      ),
    );
  }
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

/// Max-width wrapper so desktop layouts stay readable.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 1120});
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 700;
    return ListView(
      padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 16, wide ? 32 : 16, 48),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ],
    );
  }
}
