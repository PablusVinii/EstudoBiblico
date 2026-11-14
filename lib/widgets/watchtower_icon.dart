import 'package:flutter/material.dart';

/// Ícone oficial linear vazado da Torre de A Sentinela (Watchtower)
class WatchtowerIcon extends StatelessWidget {
  final double size;
  final Color color;

  const WatchtowerIcon({
    super.key,
    this.size = 32,
    this.color = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.15),
      painter: _WatchtowerPainter(color: color),
    );
  }
}

class _WatchtowerPainter extends CustomPainter {
  final Color color;

  _WatchtowerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path();

    // Começa na base inferior esquerda
    path.moveTo(w * 0.22, h * 0.92);
    // Linha inferior
    path.lineTo(w * 0.78, h * 0.92);
    // Sobe para o corpo direito
    path.lineTo(w * 0.72, h * 0.42);
    // Beiral direito
    path.lineTo(w * 0.88, h * 0.42);
    // Ameia direita (sobe)
    path.lineTo(w * 0.88, h * 0.15);
    // Ameia direita (topo para dentro)
    path.lineTo(w * 0.76, h * 0.15);
    path.lineTo(w * 0.76, h * 0.26);
    // Ameia central (vão e sobe)
    path.lineTo(w * 0.62, h * 0.26);
    path.lineTo(w * 0.62, h * 0.15);
    path.lineTo(w * 0.38, h * 0.15);
    path.lineTo(w * 0.38, h * 0.26);
    // Ameia esquerda (vão e sobe)
    path.lineTo(w * 0.24, h * 0.26);
    path.lineTo(w * 0.24, h * 0.15);
    path.lineTo(w * 0.12, h * 0.15);
    // Beiral esquerdo
    path.lineTo(w * 0.12, h * 0.42);
    path.lineTo(w * 0.28, h * 0.42);
    // Desce corpo esquerdo
    path.lineTo(w * 0.22, h * 0.92);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WatchtowerPainter oldDelegate) => oldDelegate.color != color;
}

