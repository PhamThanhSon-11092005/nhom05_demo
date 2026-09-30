import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

const ink = Color(0xFF152D35);
const teal = Color(0xFF087E80);
const mint = Color(0xFFB9F3D5);
const muted = Color(0xFF62767C);
const orange = Color(0xFFD67943);
const paper = Color(0xFFF3F6F4);

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = 20,
  });
  final Widget child;
  final Color color;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE0E8E3)),
    ),
    child: child,
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: muted, height: 1.5)),
      ],
    ),
  );
}

class Badge extends StatelessWidget {
  const Badge(
    this.label, {
    super.key,
    this.dark = false,
    this.icon = Icons.circle,
    this.warning = false,
  });
  final String label;
  final bool dark, warning;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final foreground = warning ? const Color(0xFF9A4D20) : (dark ? mint : teal);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: warning
            ? const Color(0xFFFFEEDC)
            : (dark
                  ? Colors.white.withValues(alpha: .09)
                  : const Color(0xFFE8F5EE)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoStrip extends StatelessWidget {
  const InfoStrip(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFEEDC) : const Color(0xFFE6EEEB),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          warning ? Icons.info_outline : Icons.lightbulb_outline,
          size: 19,
          color: warning ? orange : teal,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.5, color: ink),
          ),
        ),
      ],
    ),
  );
}

class Metric extends StatelessWidget {
  const Metric(
    this.icon,
    this.value,
    this.label, {
    super.key,
    this.dark = false,
  });
  final IconData icon;
  final String value, label;
  final bool dark;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: dark ? mint : teal, size: 21),
      const SizedBox(height: 8),
      Text(
        value,
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: dark ? Colors.white : ink,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: dark ? const Color(0xFFB4C8C6) : muted,
        ),
      ),
    ],
  );
}

class ProgressDial extends StatelessWidget {
  const ProgressDial({
    super.key,
    required this.progress,
    required this.value,
    required this.label,
  });
  final double progress;
  final String value, label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$value $label, ${(progress * 100).round()} phần trăm mục tiêu',
    child: SizedBox(
      width: 228,
      height: 228,
      child: CustomPaint(
        painter: _DialPainter(progress),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_walk_rounded, color: mint, size: 29),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 53,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFB4C8C6), fontSize: 13),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final track = rect.deflate(12);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      track,
      math.pi * .7,
      math.pi * 1.6,
      false,
      paint..color = const Color(0xFF345057),
    );
    if (progress > 0) {
      canvas.drawArc(
        track,
        math.pi * .7,
        math.pi * 1.6 * progress,
        false,
        paint..color = mint,
      );
    }
    final center = size.center(Offset.zero);
    for (var i = 0; i < 41; i++) {
      final a = math.pi * .7 + math.pi * 1.6 * i / 40;
      final r = size.width / 2 - 27;
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * r,
        center + Offset(math.cos(a), math.sin(a)) * (r - 4),
        Paint()
          ..color = const Color(0xFF517070)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class SensorChart extends StatelessWidget {
  const SensorChart({super.key, required this.values, required this.unit});
  final List<Vector3> values;
  final String unit;
  @override
  Widget build(BuildContext context) {
    final limit = values.fold<double>(
      1,
      (value, vector) => math.max(
        value,
        math.max(vector.x.abs(), math.max(vector.y.abs(), vector.z.abs())),
      ),
    );
    final range = (limit * 1.15).ceilToDouble();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '±${range.toStringAsFixed(0)} $unit',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
            const Text(
              '120 mẫu gần nhất',
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 148,
          width: double.infinity,
          child: values.isEmpty
              ? const Center(
                  child: Text(
                    'Chờ dữ liệu cảm biến…',
                    style: TextStyle(color: muted),
                  ),
                )
              : CustomPaint(painter: _TracePainter(List.of(values), range)),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Cũ hơn', style: TextStyle(color: muted, fontSize: 11)),
            Text('Mới nhất →', style: TextStyle(color: muted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

const axisColors = [teal, orange, Color(0xFF7866BA)];

class _TracePainter extends CustomPainter {
  _TracePainter(this.values, this.range);
  final List<Vector3> values;
  final double range;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    for (var row = 0; row <= 4; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = row == 2 ? const Color(0xFFCCDAD3) : const Color(0xFFEAF0EC)
          ..strokeWidth = 1,
      );
    }
    for (var axis = 0; axis < 3; axis++) {
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final v = values[i];
        final value = [v.x, v.y, v.z][axis];
        final x = size.width * (120 - values.length + i) / 119;
        final y = size.height / 2 - value / range * size.height / 2;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = axisColors[axis]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_TracePainter oldDelegate) => true;
}
