import 'package:flutter/material.dart';
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';

class FlowDiagramWidget extends StatelessWidget {
  final DiagramaDeFlujo diagram;
  const FlowDiagramWidget({required this.diagram});

  @override
  Widget build(BuildContext context) {
    const double spacing = 50.0;
    // Ahora incluimos el nodo "final", por eso +(1)
    final totalWidth = spacing * (diagram.cantidadDePeriodos + 1);

    return Card(
      color: Colors.grey[850],
      child: SizedBox(
        height: 200,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: totalWidth,
            padding: const EdgeInsets.all(8),
            child: CustomPaint(
              size: Size(totalWidth, 200),
              painter: _FlowPainter(diagram, spacing),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowPainter extends CustomPainter {
  final DiagramaDeFlujo d;
  final double spacing;
  _FlowPainter(this.d, this.spacing);

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final paintLine =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2;

    // 1) Dibujar tramos de tasa de interés (incluyendo el fin)
    for (final tasa in d.tasasDeInteres) {
      final left = tasa.periodoInicio * spacing;
      // +1 para cubrir inclusive el nodo final
      final width = (tasa.periodoFin - tasa.periodoInicio + 1) * spacing;
      final paintBar = Paint()..color = Colors.blue.withOpacity(0.3);
      final rect = Rect.fromLTWH(left, midY - 20, width, 40);
      canvas.drawRect(rect, paintBar);

      // Etiqueta porcentaje centrada en la franja
      final label = TextPainter(
        text: TextSpan(
          text: '${tasa.valor.toStringAsFixed(1)}%',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      label.layout(minWidth: width);
      label.paint(canvas, Offset(left + (width - label.width) / 2, midY - 35));
    }

    // 2) Línea base completa
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paintLine);

    // 3) Marcas y etiquetas de periodo (0 ... cantidadDePeriodos)
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i <= d.cantidadDePeriodos; i++) {
      final x = i * spacing;
      canvas.drawLine(Offset(x, midY - 5), Offset(x, midY + 5), paintLine);
      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(color: Colors.white, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, midY + 8));
    }

    // 4) (Opcional) aquí irían las flechas de movimientos...
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
