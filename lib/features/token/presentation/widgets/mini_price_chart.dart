import 'package:flutter/material.dart';

/// Mini price chart widget for displaying sparkline graphs
class MiniPriceChart extends StatelessWidget {
  final List<double> data;
  final double width;
  final double height;
  final bool isPositive;

  const MiniPriceChart({
    super.key,
    required this.data,
    this.width = 100,
    this.height = 40,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return SizedBox(width: width, height: height);
    }

    return CustomPaint(
      size: Size(width, height),
      painter: _ChartPainter(
        data: data,
        isPositive: isPositive,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final bool isPositive;

  _ChartPainter({
    required this.data,
    required this.isPositive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue == 0 ? 1.0 : maxValue - minValue;

    const padding = 2.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    final paint = Paint()
      ..color = isPositive ? const Color(0xFF00D1A7) : const Color(0xFFFF6B6B)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final y = padding + chartHeight - ((data[i] - minValue) / range) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.isPositive != isPositive;
  }
}
