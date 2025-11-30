import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:timezone/timezone.dart' as tz;
import 'dart:ui' as ui;

class WorldClock extends StatefulWidget {
  final String timezone;
  final String cityName;
  final bool isFavorite;
  final bool isLocalTime;
  final VoidCallback onToggleFavorite;

  const WorldClock({
    super.key,
    required this.timezone,
    required this.cityName,
    required this.isFavorite,
    required this.isLocalTime,
    required this.onToggleFavorite,
  });

  @override
  State<WorldClock> createState() => _WorldClockState();
}

class _WorldClockState extends State<WorldClock> {
  late String _currentTime;
  late String _currentDate;
  late DateTime _currentDateTime;

  @override
  void initState() {
    super.initState();
    _updateTime();
    Future.delayed(const Duration(seconds: 1), _updateTimeLoop);
  }

  void _updateTimeLoop() {
    if (mounted) {
      _updateTime();
      Future.delayed(const Duration(seconds: 1), _updateTimeLoop);
    }
  }

  void _updateTime() {
    final location = tz.getLocation(widget.timezone);
    final now = tz.TZDateTime.now(location);
    setState(() {
      _currentDateTime = now;
      _currentTime = DateFormat('HH:mm:ss').format(now);
      _currentDate = _formatDateWithOrdinal(now);
    });
  }

  String _formatDateWithOrdinal(DateTime date) {
    final day = date.day;
    final month = DateFormat('MMMM').format(date);
    final year = date.year;
    
    // Determina il suffisso ordinale (st, nd, rd, th)
    String ordinal;
    if (day >= 11 && day <= 13) {
      ordinal = 'th';
    } else {
      switch (day % 10) {
        case 1:
          ordinal = 'st';
          break;
        case 2:
          ordinal = 'nd';
          break;
        case 3:
          ordinal = 'rd';
          break;
        default:
          ordinal = 'th';
      }
    }
    
    return '$day$ordinal $month $year';
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          // Layout orizzontale
          return _buildLandscapeLayout();
        } else {
          // Layout verticale
          return _buildPortraitLayout();
        }
      },
    );
  }

  // Layout verticale (portrait)
  Widget _buildPortraitLayout() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.cityName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!widget.isLocalTime)
                  IconButton(
                    onPressed: widget.onToggleFavorite,
                    icon: Icon(
                      widget.isFavorite ? Icons.star : Icons.star_border,
                      color: Colors.yellow,
                      size: 32,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            AnalogClock(
              dateTime: _currentDateTime,
              size: 200,
            ),
            const SizedBox(height: 30),
            Text(
              _currentDate,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              _currentTime,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.timezone,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Layout orizzontale (landscape)
  Widget _buildLandscapeLayout() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Parte sinistra: Nome città + Orologio
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nome città + stella
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.cityName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!widget.isLocalTime)
                        IconButton(
                          onPressed: widget.onToggleFavorite,
                          icon: Icon(
                            widget.isFavorite ? Icons.star : Icons.star_border,
                            color: Colors.yellow,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnalogClock(
                    dateTime: _currentDateTime,
                    size: 170,
                  ),
                ],
              ),
              const SizedBox(width: 40),
              // Parte destra: Ora digitale + Timezone
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentDate,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.timezone,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget per l'orologio analogico
class AnalogClock extends StatelessWidget {
  final DateTime dateTime;
  final double size;

  const AnalogClock({
    super.key,
    required this.dateTime,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ClockPainter(dateTime: dateTime),
      ),
    );
  }
}

// Painter per disegnare l'orologio
class ClockPainter extends CustomPainter {
  final DateTime dateTime;

  ClockPainter({required this.dateTime});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);
    final radius = min(centerX, centerY);

    // Sfondo dell'orologio - stile antico con texture
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF5E6D3),
          const Color(0xFFD4A574),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // Bordo esterno decorativo - bronzo antico
    final outerBorderPaint = Paint()
      ..color = const Color(0xFF8B6914)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06;
    canvas.drawCircle(center, radius - radius * 0.03, outerBorderPaint);

    // Bordo interno decorativo
    final innerBorderPaint = Paint()
      ..color = const Color(0xFFCD853F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.015;
    canvas.drawCircle(center, radius - radius * 0.075, innerBorderPaint);

    // Ombra interna per profondità
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.1),
        ],
        stops: const [0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - radius * 0.1, shadowPaint);

    // Disegna i numeri romani
    _drawRomanNumerals(canvas, center, radius);

    // Centro decorativo
    final centerDotPaint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawCircle(center, radius * 0.06, centerDotPaint);

    final centerDotInnerPaint = Paint()..color = const Color(0xFFD4A574);
    canvas.drawCircle(center, radius * 0.04, centerDotInnerPaint);

    // Calcola gli angoli per le lancette
    final secondAngle = (dateTime.second * 6.0 - 90) * pi / 180;
    final minuteAngle =
        ((dateTime.minute + dateTime.second / 60) * 6.0 - 90) * pi / 180;
    final hourAngle =
        ((dateTime.hour % 12 + dateTime.minute / 60) * 30.0 - 90) * pi / 180;

    // Disegna lancetta delle ore - più spessa e corta
    _drawHand(
      canvas,
      center,
      hourAngle,
      radius * 0.5,
      radius * 0.04,
      const Color(0xFF2C1810),
    );

    // Disegna lancetta dei minuti - media
    _drawHand(
      canvas,
      center,
      minuteAngle,
      radius * 0.7,
      radius * 0.03,
      const Color(0xFF3D2817),
    );

    // Disegna lancetta dei secondi - sottile e rossa
    _drawHand(
      canvas,
      center,
      secondAngle,
      radius * 0.75,
      radius * 0.01,
      const Color(0xFFB22222),
    );

    // Centro finale sopra le lancette
    canvas.drawCircle(center, radius * 0.03, centerDotPaint);
  }

  void _drawRomanNumerals(Canvas canvas, Offset center, double radius) {
    final numerals = ['XII', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI'];
    
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final x = center.dx + radius * 0.75 * cos(angle);
      final y = center.dy + radius * 0.75 * sin(angle);

      final textSpan = TextSpan(
        text: numerals[i],
        style: TextStyle(
          color: const Color(0xFF3D2817),
          fontSize: radius * (i == 0 ? 0.1 : 0.09),
          fontWeight: FontWeight.bold,
          fontFamily: 'serif',
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double length,
      double width, Color color) {
    final handPaint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final handEndX = center.dx + length * cos(angle);
    final handEndY = center.dy + length * sin(angle);

    // Disegna ombra per profondità
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawLine(
      center,
      Offset(handEndX + 2, handEndY + 2),
      shadowPaint,
    );

    // Disegna la lancetta
    canvas.drawLine(center, Offset(handEndX, handEndY), handPaint);

    // Punta decorativa per ore e minuti
    if (width > 2) {
      final tipPaint = Paint()..color = color;
      canvas.drawCircle(Offset(handEndX, handEndY), width / 2, tipPaint);
    }
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) {
    return oldDelegate.dateTime != dateTime;
  }
}