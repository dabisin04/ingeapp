import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/movimiento.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/domain/entities/unidad_de_tiempo.dart';
import 'package:inge_app/domain/entities/valor.dart';
import 'package:inge_app/infrastructure/utils/financial_analyzer.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';

class DeepSeekAssistant {
  static const _apiKey = '';
  static const _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  static Stream<
      ({
        String? explanation,
        DiagramaDeFlujo? diagram,
        EquationAnalysis? solution,
        String? error,
        String? rawResponse
      })> solveWithDescription(String description) async* {
    print('🛠️ Iniciando asistente DeepSeek con descripción: $description');

    yield (
      explanation: 'Cargando archivos...',
      diagram: null,
      solution: null,
      error: null,
      rawResponse: null
    );

    final codeFiles = await _loadCodeFiles();
    print('📚 Archivos cargados exitosamente.');

    yield (
      explanation: 'Construyendo prompt...',
      diagram: null,
      solution: null,
      error: null,
      rawResponse: null
    );

    final systemPrompt = _buildSystemPrompt(codeFiles);
    print(
        '🧠 System Prompt construido correctamente (longitud=${systemPrompt.length} caracteres).');

    final messages = [
      {
        "role": "system",
        "content": systemPrompt,
      },
      {
        "role": "user",
        "content": '''
Basándote en la siguiente descripción:

**Descripción:**
$description

**Instrucciones:**
1. Analiza el tipo de caso (VP/VF, X, n, IRR).
2. Explica paso a paso la resolución de forma clara, incluyendo:
   - Identificación del tipo de problema.
   - Definición de variables.
   - Planteamiento de la ecuación.
   - Cálculo de factores de descuento o capitalización.
3. Para las fórmulas matemáticas, usa el formato:
   ```
   \$\$\$formula_latex\$\$\$
   ```
4. NO proporciones la solución final. En su lugar, escribe:
   "La solución se presenta a continuación:"

5. Luego escribe SOLO el JSON compatible con esta clase Dart, encerrándolo entre etiquetas [JSON] y [/JSON], SIN EXPLICACIÓN EXTRA dentro de esas etiquetas. Asegúrate de que el JSON sea válido y cumpla con el formato exacto de la clase DiagramaDeFlujo:
$_diagramaDeFlujoModel

**Notas importantes:**
- Usa únicamente las unidades de tiempo válidas proporcionadas en el system prompt.
- Asegúrate de que los valores numéricos (como tasas y valores) sean números, no cadenas, a menos que representen una expresión (como "0.2*X").
- No incluyas comentarios ni explicaciones dentro del bloque [JSON][/JSON].
- Si el JSON no es válido, el proceso fallará, así que verifica que esté correctamente formado.
- **CRUCIAL**: El JSON DEBE estar encerrado entre [JSON] y [/JSON]. Si no está encerrado en estas etiquetas, la respuesta será rechazada.
''',
      }
    ];

    yield (
      explanation: 'Enviando solicitud a DeepSeek...',
      diagram: null,
      solution: null,
      error: null,
      rawResponse: null
    );

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "deepseek-chat",
          "temperature": 0.2,
          "messages": messages,
          "stream": true,
        }),
      );

      if (response.statusCode == 200) {
        print('📡 Respuesta recibida de DeepSeek (status 200).');

        String accumulatedContent = '';
        String currentExplanation = '';
        String currentJson = '';

        final content = utf8.decode(response.bodyBytes);
        final lines = content.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;

            try {
              final json = jsonDecode(data);
              final content = json['choices'][0]['delta']['content'] as String?;
              if (content != null) {
                accumulatedContent += content;

                // Actualizar explicación y JSON
                if (accumulatedContent.contains('[JSON]')) {
                  final parts = accumulatedContent.split('[JSON]');
                  currentExplanation = parts[0].trim();
                  if (parts.length > 1) {
                    final jsonParts = parts[1].split('[/JSON]');
                    if (jsonParts.length > 1) {
                      currentJson = jsonParts[0].trim();
                      try {
                        final diagrama = _parseDiagram(currentJson);
                        final solucion = FinancialAnalyzer.analyze(diagrama);
                        yield (
                          explanation: currentExplanation,
                          diagram: diagrama,
                          solution: solucion,
                          error: null,
                          rawResponse: accumulatedContent
                        );
                      } catch (e) {
                        yield (
                          explanation: currentExplanation,
                          diagram: null,
                          solution: null,
                          error: e.toString(),
                          rawResponse: accumulatedContent
                        );
                      }
                    }
                  }
                } else {
                  yield (
                    explanation: accumulatedContent,
                    diagram: null,
                    solution: null,
                    error: null,
                    rawResponse: accumulatedContent
                  );
                }
              }
            } catch (e) {
              print('Error procesando chunk: $e');
            }
          }
        }
      } else {
        yield (
          explanation: null,
          diagram: null,
          solution: null,
          error: 'Error al invocar DeepSeek: ${response.body}',
          rawResponse: response.body
        );
      }
    } catch (e) {
      yield (
        explanation: null,
        diagram: null,
        solution: null,
        error: e.toString(),
        rawResponse: null
      );
    }
  }

  static Future<Map<String, String>> _loadCodeFiles() async {
    const files = [
      'financial_analyzer.dart',
      'financial_analysis_multiple_unknowns.dart',
      'financial_analysis_series.dart',
    ];

    final Map<String, String> contents = {};
    for (final file in files) {
      print('📂 Cargando archivo: lib/infrastructure/utils/$file');
      final content =
          await rootBundle.loadString('lib/infrastructure/utils/$file');
      contents[file] = content;
    }
    return contents;
  }

  static String _buildSystemPrompt(Map<String, String> files) {
    final buffer = StringBuffer();
    buffer.writeln('Eres un experto en ingeniería económica.');
    buffer
        .writeln('Tu tarea es analizar descripciones financieras y producir:');
    buffer.writeln('1. Una explicación clara del procedimiento paso a paso.');
    buffer.writeln(
        '2. Un objeto DiagramaDeFlujo en formato JSON limpio y válido, encerrado entre [JSON] y [/JSON].');
    buffer.writeln('Reglas estrictas para el JSON:');
    buffer.writeln(
        '- No incluyas comentarios ni explicaciones dentro del bloque [JSON][/JSON].');
    buffer.writeln(
        '- Asegúrate de que los valores numéricos (como tasas y montos) sean números, no cadenas, a menos que representen una expresión (como "0.2*X").');
    buffer.writeln(
        '- Verifica que el JSON sea sintácticamente correcto antes de incluirlo.');

    buffer
        .writeln('\n🧩 IMPORTANTE: Usa sólo estas unidades de tiempo válidas:');
    buffer.writeln('[');
    buffer.writeln('  { "id": 1, "nombre": "Diaria", "valor": 360 },');
    buffer.writeln('  { "id": 2, "nombre": "Semanal", "valor": 48 },');
    buffer.writeln('  { "id": 3, "nombre": "Quincenal", "valor": 24 },');
    buffer.writeln('  { "id": 4, "nombre": "Mensual", "valor": 12 },');
    buffer.writeln('  { "id": 5, "nombre": "Bimestral", "valor": 6 },');
    buffer.writeln('  { "id": 6, "nombre": "Trimestral", "valor": 4 },');
    buffer.writeln('  { "id": 7, "nombre": "Cuatrimestral", "valor": 3 },');
    buffer.writeln('  { "id": 8, "nombre": "Semestral", "valor": 2 },');
    buffer.writeln('  { "id": 9, "nombre": "Anual", "valor": 1 }');
    buffer.writeln(']');

    buffer.writeln('\n🔒 Cualquier unidad fuera de esta lista será inválida.');

    // Agregar ejemplo de JSON bien formateado
    buffer.writeln('\n📝 Ejemplo de JSON válido:');
    buffer.writeln('''
[JSON]
{
  "id": 1,
  "nombre": "Ejemplo de Diagrama",
  "descripcion": "Descripción del ejemplo",
  "unidadDeTiempo": {
    "id": 4,
    "nombre": "Mensual",
    "valor": 12
  },
  "cantidadDePeriodos": 36,
  "periodoFocal": 0,
  "tasasDeInteres": [
    {
      "id": 1,
      "valor": 0.024,
      "periodicidad": {
        "id": 4,
        "nombre": "Mensual",
        "valor": 12
      },
      "capitalizacion": {
        "id": 4,
        "nombre": "Mensual",
        "valor": 12
      },
      "tipo": "Vencida",
      "periodoInicio": 0,
      "periodoFin": 12,
      "aplicaA": "Todos"
    }
  ],
  "movimientos": [
    {
      "id": 1,
      "valor": 200000,
      "tipo": "egreso",
      "periodo": 1,
      "esSerie": true,
      "tipoSerie": "vencida",
      "hastaPeriodo": 9
    },
    {
      "id": 2,
      "valor": 650000,
      "tipo": "ingreso",
      "periodo": 4,
      "esSerie": false,
      "tipoSerie": null,
      "hastaPeriodo": null
    }
  ],
  "valores": [
    {
      "id": 1,
      "valor": "x",
      "tipo": "Presente",
      "periodo": 0,
      "flujo": "egreso",
      "esSerie": false,
      "tipoSerie": null,
      "hastaPeriodo": null
    }
  ]
}
[/JSON]
''');

    files.forEach((name, content) {
      buffer.writeln('\n--- Archivo: $name ---\n```\n$content\n```');
    });

    return buffer.toString();
  }

  static DiagramaDeFlujo _parseDiagram(String diagramJson) {
    try {
      final map = jsonDecode(diagramJson) as Map<String, dynamic>;
      final diagrama = DiagramaDeFlujo(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
        descripcion: map['descripcion'] as String?,
        unidadDeTiempo: UnidadDeTiempo.fromMap(map['unidadDeTiempo']),
        cantidadDePeriodos: map['cantidadDePeriodos'] as int,
        periodoFocal: map['periodoFocal'] as int?,
        tasasDeInteres: (map['tasasDeInteres'] as List)
            .map((e) => TasaDeInteres.fromMap(e))
            .toList(),
        movimientos: (map['movimientos'] as List)
            .map((e) => Movimiento.fromMap(e))
            .toList(),
        valores: (map['valores'] as List).map((e) => Valor.fromMap(e)).toList(),
      );

      print('✅ DiagramaDeFlujo parseado correctamente.');
      print('Movimientos:');
      for (var m in diagrama.movimientos) {
        print('  - valor: ${m.valor} (type: ${m.valor.runtimeType})');
      }
      print('Valores:');
      for (var v in diagrama.valores) {
        print('  - valor: ${v.valor} (type: ${v.valor.runtimeType})');
      }

      return diagrama;
    } catch (e) {
      print('❌ Error parseando el DiagramaDeFlujo: $e');
      print('JSON problemático:\n$diagramJson');
      throw Exception('Error parseando el DiagramaDeFlujo: $e');
    }
  }

  static const String _diagramaDeFlujoModel = '''
DiagramaDeFlujo {
  id: int,
  nombre: String,
  descripcion: String?,
  unidadDeTiempo: UnidadDeTiempo { id: int, nombre: String, valor: int },
  cantidadDePeriodos: int,
  periodoFocal: int?,
  tasasDeInteres: List<TasaDeInteres> {
    id: int,
    valor: double,
    periodicidad: UnidadDeTiempo,
    capitalizacion: UnidadDeTiempo,
    tipo: String,
    periodoInicio: int,
    periodoFin: int,
    aplicaA: String,
  },
  movimientos: List<Movimiento> {
    id: int,
    tipo: String,
    periodo: int?,
    valor: double | String,
  },
  valores: List<Valor> {
    id: int,
    tipo: String,
    flujo: String,
    periodo: int?,
    valor: double | String,
  }
}
''';
}
