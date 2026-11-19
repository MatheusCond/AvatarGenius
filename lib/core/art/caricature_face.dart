import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

/// Traços de uma caricatura desenhada à mão em código.
///
/// É a marca do app e também o "gerador" do modo demo, que cria uma
/// caricatura diferente para cada foto sem chamar nenhuma API.
class CaricatureTraits {
  const CaricatureTraits({
    this.skin = const Color(0xFFE9B48A),
    this.hair = const Color(0xFF3B2A20),
    this.shirt = const Color(0xFF2F4BFF),
    this.headWidth = 1.0,
    this.eyeSize = 1.0,
    this.noseSize = 1.0,
    this.smile = 1.0,
    this.hairStyle = 0,
    this.glasses = false,
  });

  /// Sorteia traços de forma determinística a partir de uma semente.
  factory CaricatureTraits.fromSeed(int seed) {
    final random = math.Random(seed);
    T pick<T>(List<T> options) => options[random.nextInt(options.length)];
    double between(double min, double max) =>
        min + random.nextDouble() * (max - min);

    return CaricatureTraits(
      skin: pick(const [
        Color(0xFFF6D3B8),
        Color(0xFFE9B48A),
        Color(0xFFC98D5E),
        Color(0xFF9C6440),
        Color(0xFF6B4129),
      ]),
      hair: pick(const [
        Color(0xFF1E1A1A),
        Color(0xFF3B2A20),
        Color(0xFF7A4A24),
        Color(0xFFD9A441),
        Color(0xFFB4483A),
        Color(0xFF8A8F9C),
      ]),
      shirt: pick(const [
        Color(0xFF2F4BFF),
        Color(0xFFFF7A8A),
        Color(0xFF22A06B),
        Color(0xFF1B1F3B),
        Color(0xFFFF9F1C),
      ]),
      headWidth: between(0.85, 1.15),
      eyeSize: between(0.8, 1.35),
      noseSize: between(0.8, 1.6),
      smile: between(0.4, 1.3),
      hairStyle: random.nextInt(3),
      glasses: random.nextInt(3) == 0,
    );
  }

  final Color skin;
  final Color hair;
  final Color shirt;
  final double headWidth;
  final double eyeSize;
  final double noseSize;
  final double smile;

  /// 0 = curto, 1 = cacheado, 2 = topete.
  final int hairStyle;
  final bool glasses;
}

/// Pinta uma [CaricatureTraits] num quadrado, com contorno de tinta e,
/// opcionalmente, a mancha de marca-texto atrás.
class CaricaturePainter extends CustomPainter {
  const CaricaturePainter({
    this.traits = const CaricatureTraits(),
    this.ink = const Color(0xFF1B1F3B),
    this.backdrop,
  });

  final CaricatureTraits traits;
  final Color ink;
  final Color? backdrop;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.028
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Paint fill(Color c) => Paint()..color = c;

    if (backdrop != null) _paintBackdrop(canvas, s, fill(backdrop!));

    // Ombros e camisa.
    final shirt = Path()
      ..moveTo(s * 0.14, s * 1.02)
      ..cubicTo(s * 0.16, s * 0.84, s * 0.30, s * 0.78, s * 0.50, s * 0.78)
      ..cubicTo(s * 0.70, s * 0.78, s * 0.84, s * 0.84, s * 0.86, s * 1.02)
      ..close();
    canvas
      ..drawPath(shirt, fill(traits.shirt))
      ..drawPath(shirt, stroke);

    // Pescoço.
    final neck = RRect.fromLTRBR(
      s * 0.44,
      s * 0.62,
      s * 0.56,
      s * 0.80,
      Radius.circular(s * 0.03),
    );
    canvas
      ..drawRRect(neck, fill(traits.skin))
      ..drawRRect(neck, stroke);

    // Cabeça grande: o exagero é o que faz a caricatura.
    final headW = s * 0.44 * traits.headWidth;
    final head = Rect.fromCenter(
      center: Offset(s * 0.5, s * 0.42),
      width: headW,
      height: s * 0.52,
    );

    // Orelhas.
    for (final dx in [-1.0, 1.0]) {
      final ear = Rect.fromCenter(
        center: Offset(s * 0.5 + dx * headW * 0.5, s * 0.45),
        width: s * 0.08,
        height: s * 0.12,
      );
      canvas
        ..drawOval(ear, fill(traits.skin))
        ..drawOval(ear, stroke);
    }

    if (traits.hairStyle == 1) {
      _paintCurls(canvas, head, s, fill(traits.hair), stroke);
    }

    canvas
      ..drawOval(head, fill(traits.skin))
      ..drawOval(head, stroke);

    if (traits.hairStyle != 1) {
      _paintHair(canvas, head, s, fill(traits.hair), stroke);
    }

    _paintFace(canvas, head, s, stroke, fill);
    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas, double s, Paint paint) {
    final blob = Path();
    // Número par de pontos: o contorno termina no mesmo raio em que começa.
    const points = 10;
    for (var i = 0; i <= points; i++) {
      final angle = i / points * math.pi * 2;
      final radius = s * (0.44 + (i.isEven ? 0.03 : -0.02));
      final p = Offset(
        s * 0.5 + math.cos(angle) * radius,
        s * 0.5 + math.sin(angle) * radius,
      );
      if (i == 0) {
        blob.moveTo(p.dx, p.dy);
      } else {
        final prev = (i - 0.5) / points * math.pi * 2;
        final control = Offset(
          s * 0.5 + math.cos(prev) * s * 0.5,
          s * 0.5 + math.sin(prev) * s * 0.5,
        );
        blob.quadraticBezierTo(control.dx, control.dy, p.dx, p.dy);
      }
    }
    canvas.drawPath(blob, paint);
  }

  void _paintHair(
    Canvas canvas,
    Rect head,
    double s,
    Paint hair,
    Paint stroke,
  ) {
    final top = head.top;
    final path = Path()
      ..moveTo(head.left + s * 0.01, head.center.dy - s * 0.02);
    if (traits.hairStyle == 2) {
      // Topete alto.
      path
        ..cubicTo(
          head.left,
          top - s * 0.06,
          head.center.dx - s * 0.05,
          top - s * 0.16,
          head.center.dx + s * 0.12,
          top - s * 0.12,
        )
        ..cubicTo(
          head.right + s * 0.02,
          top - s * 0.08,
          head.right + s * 0.01,
          top + s * 0.08,
          head.right - s * 0.01,
          head.center.dy - s * 0.02,
        )
        ..cubicTo(
          head.right - s * 0.06,
          top + s * 0.08,
          head.center.dx,
          top + s * 0.10,
          head.left + s * 0.01,
          head.center.dy - s * 0.02,
        );
    } else {
      // Corte curto com franja de lado.
      path
        ..cubicTo(
          head.left - s * 0.01,
          top - s * 0.02,
          head.right + s * 0.01,
          top - s * 0.04,
          head.right - s * 0.005,
          head.center.dy - s * 0.04,
        )
        ..cubicTo(
          head.right - s * 0.08,
          top + s * 0.07,
          head.center.dx - s * 0.04,
          top + s * 0.12,
          head.left + s * 0.01,
          head.center.dy - s * 0.02,
        );
    }
    path.close();
    canvas
      ..drawPath(path, hair)
      ..drawPath(path, stroke);
  }

  void _paintCurls(
    Canvas canvas,
    Rect head,
    double s,
    Paint hair,
    Paint stroke,
  ) {
    const curls = 9;
    for (var i = 0; i < curls; i++) {
      final angle = math.pi + i / (curls - 1) * math.pi;
      final c = Offset(
        head.center.dx + math.cos(angle) * head.width * 0.52,
        head.center.dy - s * 0.04 + math.sin(angle) * head.height * 0.5,
      );
      canvas
        ..drawCircle(c, s * 0.075, hair)
        ..drawCircle(c, s * 0.075, stroke);
    }
  }

  void _paintFace(
    Canvas canvas,
    Rect head,
    double s,
    Paint stroke,
    Paint Function(Color) fill,
  ) {
    final eyeY = head.center.dy + s * 0.01;
    final eyeDx = head.width * 0.2;
    final eyeR = s * 0.045 * traits.eyeSize;

    for (final dx in [-eyeDx, eyeDx]) {
      final c = Offset(head.center.dx + dx, eyeY);
      canvas
        ..drawCircle(c, eyeR, fill(const Color(0xFFFFFFFF)))
        ..drawCircle(c, eyeR, stroke)
        ..drawCircle(c + Offset(s * 0.008, s * 0.006), eyeR * 0.45, fill(ink));
      // Sobrancelha.
      canvas.drawLine(
        c + Offset(-eyeR * 1.1, -eyeR * 1.7),
        c + Offset(eyeR * 1.1, -eyeR * (dx < 0 ? 1.9 : 1.5)),
        stroke,
      );
    }

    if (traits.glasses) {
      final lens = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018;
      for (final dx in [-eyeDx, eyeDx]) {
        canvas.drawCircle(Offset(head.center.dx + dx, eyeY), eyeR * 1.7, lens);
      }
      canvas.drawLine(
        Offset(head.center.dx - eyeDx + eyeR * 1.7, eyeY),
        Offset(head.center.dx + eyeDx - eyeR * 1.7, eyeY),
        lens,
      );
    }

    // Nariz exagerado.
    final nose = Rect.fromCenter(
      center: Offset(head.center.dx + s * 0.012, eyeY + s * 0.075),
      width: s * 0.07 * traits.noseSize,
      height: s * 0.09 * traits.noseSize,
    );
    canvas
      ..drawOval(
        nose,
        fill(Color.lerp(traits.skin, const Color(0xFFFF7A8A), 0.25)!),
      )
      ..drawOval(nose, stroke);

    // Boca.
    final mouthY = head.bottom - s * 0.085;
    final mouthW = head.width * 0.32;
    final mouth = Path()
      ..moveTo(head.center.dx - mouthW, mouthY)
      ..quadraticBezierTo(
        head.center.dx,
        mouthY + s * 0.07 * traits.smile,
        head.center.dx + mouthW,
        mouthY,
      );
    canvas.drawPath(mouth, stroke);
  }

  @override
  bool shouldRepaint(CaricaturePainter oldDelegate) =>
      oldDelegate.traits != traits ||
      oldDelegate.ink != ink ||
      oldDelegate.backdrop != backdrop;
}

/// Renderiza uma caricatura como PNG, fora da árvore de widgets.
Future<Uint8List> renderCaricaturePng(
  CaricatureTraits traits, {
  int size = 768,
  Color background = const Color(0xFFF7F8FB),
  Color backdrop = const Color(0xFFFFD23F),
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final area = Size.square(size.toDouble());
  canvas.drawRect(Offset.zero & area, Paint()..color = background);
  CaricaturePainter(traits: traits, backdrop: backdrop).paint(canvas, area);
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}
