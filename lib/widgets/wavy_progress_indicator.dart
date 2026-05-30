import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_colors.dart';

class WavyProgressIndicator extends StatefulWidget {
  final double width;
  final double height;
  final Color? color;
  final double strokeWidth;

  const WavyProgressIndicator({
    super.key,
    this.width = 150.0,
    this.height = 30.0,
    this.color,
    this.strokeWidth = 4.0,
  });

  @override
  State<WavyProgressIndicator> createState() => _WavyProgressIndicatorState();
}

class _WavyProgressIndicatorState extends State<WavyProgressIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: _WavyProgressPainter(
              phase: _controller.value * 2 * math.pi,
              strokeWidth: widget.strokeWidth,
              color: widget.color ?? AppColors.moradoPrincipal,
            ),
          ),
        );
      },
    );
  }
}

class _WavyProgressPainter extends CustomPainter {
  final double phase;
  final double strokeWidth;
  final Color color;

  _WavyProgressPainter({
    required this.phase,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Gradiente premium morado a azul
    paint.shader = LinearGradient(
      colors: [color, Colors.blueAccent],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path path = Path();
    
    // Parámetros de la onda senoidal
    final double amplitude = size.height / 3;
    final double midY = size.height / 2;
    const double wavelength = 0.05; // Ajusta la frecuencia/cantidad de ondas

    path.moveTo(0, midY + math.sin(phase) * amplitude);

    for (double x = 0; x <= size.width; x++) {
      final double y = midY + math.sin((x * wavelength) - phase) * amplitude;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavyProgressPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}
