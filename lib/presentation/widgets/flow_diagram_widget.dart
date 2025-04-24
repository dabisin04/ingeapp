import 'package:flutter/material.dart';
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';

class FlowDiagramWidget extends StatelessWidget {
  final DiagramaDeFlujo diagram;
  FlowDiagramWidget({required this.diagram});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      child: Container(
        height: 200,
        padding: EdgeInsets.all(8),
        child: CustomPaint(painter: _FlowPainter(diagram), child: Container()),
      ),
    );
  }
}

class _FlowPainter extends CustomPainter {
  final DiagramaDeFlujo d;
  _FlowPainter(this.d);

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2;
    // Línea base
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paintLine,
    );

    final periodWidth = size.width / d.cantidadDePeriodos;
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Marcas y etiquetas de periodos
    for (int i = 0; i <= d.cantidadDePeriodos; i++) {
      final x = i * periodWidth;
      canvas.drawLine(
        Offset(x, size.height / 2 - 5),
        Offset(x, size.height / 2 + 5),
        paintLine,
      );
      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(color: Colors.white, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height / 2 + 8),
      );
    }

    // Aquí podrías dibujar flechas para ingresos/egresos a partir de d.movimientos...
    // y sombrear los tramos de tasa usando d.tasasDeInteres.
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
