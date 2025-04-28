import 'dart:math';
import 'package:inge_app/domain/entities/diagrama_de_flujo.dart';
import 'package:inge_app/domain/entities/equation_analysis.dart';
import 'package:inge_app/domain/entities/tasa_de_interes.dart';
import 'package:inge_app/infrastructure/utils/rate_conversor.dart';

class FinancialAnalysisUnknown {
  static EquationAnalysis analyze(DiagramaDeFlujo d) {
    final steps = <String>[];

    if (d.tasasDeInteres.isEmpty) {
      throw StateError('Se necesita al menos una tasa de interés.');
    }

    final focal = d.periodoFocal ?? 0;

    final tasasOk = d.tasasDeInteres.map((t) {
      final yaOk = t.periodicidad.id == d.unidadDeTiempo.id &&
          t.capitalizacion.id == d.unidadDeTiempo.id &&
          t.tipo.toLowerCase() == 'vencida';

      if (yaOk) return t;

      final nuevaRate = RateConversionUtils.periodicRateForDiagram(
        tasa: t,
        unidadObjetivo: d.unidadDeTiempo,
      );

      return TasaDeInteres(
        id: t.id,
        valor: nuevaRate,
        periodicidad: d.unidadDeTiempo,
        capitalizacion: d.unidadDeTiempo,
        tipo: 'Vencida',
        periodoInicio: t.periodoInicio,
        periodoFin: t.periodoFin,
        aplicaA: t.aplicaA,
      );
    }).toList();

    print('🌟 Tasas normalizadas:');
    for (final t in tasasOk) {
      print(
          ' • ${t.periodoInicio}-${t.periodoFin}: ${(t.valor * 100).toStringAsFixed(6)}% para ${t.aplicaA}');
    }

    double coefX = 0.0;
    double constante = 0.0;
    final ecuacion = <String>[];

    double _getRate(int periodo, String tipoFlujo) {
      final tipoNormalized = RateConversionUtils.normalizeTipo(tipoFlujo);

      final tasasAplicables = tasasOk.where((t) {
        final inRango = periodo >= t.periodoInicio && periodo <= t.periodoFin;
        final aplica = RateConversionUtils.normalizeTipo(t.aplicaA);
        final tipoCoincide = aplica == 'todos' || aplica == tipoNormalized;
        return inRango && tipoCoincide;
      }).toList();

      if (tasasAplicables.isEmpty) {
        throw StateError(
            '❌ No se encontró tasa aplicable para t=$periodo ($tipoFlujo)');
      }

      final sumaTasas =
          tasasAplicables.map((t) => t.valor).reduce((a, b) => a + b);

      print('🔍 Tasas activas para $tipoFlujo en t=$periodo: '
          '${tasasAplicables.map((t) => (t.valor * 100).toStringAsFixed(4)).join('% + ')}%'
          ' = ${(sumaTasas * 100).toStringAsFixed(4)}%');

      return sumaTasas;
    }

    double _factor(int p, String tipoFlujo) {
      if (p == focal) {
        print('💬 Factor para t=$p es 1.0 (focal)');
        return 1.0;
      }

      double factor = 1.0;
      final sentido = p > focal ? 1 : -1;
      int actual = focal;

      print('🔎 Calculando factor de descuento de t=$focal a t=$p:');

      while (actual != p) {
        final tasaActual = _getRate(actual, tipoFlujo);
        int siguienteCambio = actual;

        while (siguienteCambio != p) {
          final nextStep = siguienteCambio + sentido;
          try {
            final tasaNext = _getRate(nextStep, tipoFlujo);
            if (tasaNext != tasaActual) {
              break;
            }
          } catch (_) {
            break;
          }
          siguienteCambio = nextStep;
        }

        if (siguienteCambio == actual) {
          siguienteCambio += sentido; // 🔥 Corrección: avanzar 1 si no cambia
        }

        final nPeriodos = (siguienteCambio - actual).abs();
        final tramoFactor = sentido > 0
            ? 1 / pow(1 + tasaActual, nPeriodos)
            : pow(1 + tasaActual, nPeriodos).toDouble();

        print(
            '   • De t=$actual a t=$siguienteCambio con tasa ${(tasaActual * 100).toStringAsFixed(4)}%: factor parcial = ${tramoFactor.toStringAsFixed(12)}');

        factor *= tramoFactor;
        actual = siguienteCambio;
      }

      print('✅ Factor total de t=$focal a t=$p: ${factor.toStringAsFixed(12)}');
      return factor;
    }

    void _procesarValorSinPeriodo(dynamic valor, String tipoFlujo) {
      final ingreso = RateConversionUtils.normalizeTipo(tipoFlujo) == 'ingreso';

      if (valor == null) return;

      if (valor is double) {
        final contrib = ingreso ? valor : -valor;
        constante += contrib;
        ecuacion.add(
            '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(2)}');
        print('🧮 Valor sin periodo: ${ingreso ? '+' : '-'}${valor}');
      } else if (valor is String) {
        final texto = valor.trim().toUpperCase();
        if (texto == 'X') {
          coefX += ingreso ? 1 : -1;
          ecuacion.add('${ingreso ? '+' : '-'} 1.000000X');
          print('🧮 Valor sin periodo: ${ingreso ? '+' : '-'}1.000000X');
        } else if (RegExp(r'^\d*\.?\d+\*?X$').hasMatch(texto)) {
          final factorStr = texto.replaceAll('*', '').replaceAll('X', '');
          final factor = double.parse(factorStr);
          coefX += ingreso ? factor : -factor;
          ecuacion.add('${ingreso ? '+' : '-'} ${factor.toStringAsFixed(6)}X');
          print(
              '🧮 Valor sin periodo: ${ingreso ? '+' : '-'}${factor.toStringAsFixed(6)}X');
        } else if (texto.contains('/')) {
          final partes = texto.split('/');
          final numerador = partes[0].trim();
          final denominador = partes[1].trim();
          final num = numerador == 'X' ? 1.0 : double.parse(numerador);
          final den = double.parse(denominador);
          final factor = num / den;

          coefX += ingreso ? factor : -factor;
          ecuacion.add('${ingreso ? '+' : '-'} ${factor.toStringAsFixed(6)}X');
          print(
              '🧮 Valor sin periodo: ${ingreso ? '+' : '-'}${factor.toStringAsFixed(6)}X');
        } else {
          final num = double.parse(texto);
          final contrib = ingreso ? num : -num;
          constante += contrib;
          ecuacion.add(
              '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(2)}');
          print('🧮 Valor sin periodo: ${ingreso ? '+' : '-'}${num}');
        }
      }
    }

    void _procesarValorConFactor(dynamic valor, double fac, String tipoFlujo) {
      final ingreso = RateConversionUtils.normalizeTipo(tipoFlujo) == 'ingreso';

      if (valor == null) return;

      if (valor is double) {
        final contrib = (ingreso ? 1 : -1) * valor * fac;
        constante += contrib;
        ecuacion.add(
            '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(2)}');
        print(
            '🧮 Valor con periodo: ${(ingreso ? '+' : '-')}${valor} * factor ${fac.toStringAsFixed(12)}');
      } else if (valor is String) {
        final texto = valor.trim().toUpperCase();
        if (texto == 'X') {
          coefX += (ingreso ? 1 : -1) * fac;
          ecuacion.add('${ingreso ? '+' : '-'} ${fac.toStringAsFixed(6)}X');
          print(
              '🧮 Valor con periodo: ${(ingreso ? '+' : '-')}${fac.toStringAsFixed(12)}X');
        } else if (RegExp(r'^\d*\.?\d+\*?X$').hasMatch(texto)) {
          final factorStr = texto.replaceAll('*', '').replaceAll('X', '');
          final factor = double.parse(factorStr);
          coefX += (ingreso ? factor : -factor) * fac;
          ecuacion.add(
              '${ingreso ? '+' : '-'} ${(factor * fac).toStringAsFixed(6)}X');
          print(
              '🧮 Valor con periodo: ${(ingreso ? '+' : '-')}${(factor * fac).toStringAsFixed(12)}X');
        } else if (texto.contains('/')) {
          final partes = texto.split('/');
          final numerador = partes[0].trim();
          final denominador = partes[1].trim();
          final num = numerador == 'X' ? 1.0 : double.parse(numerador);
          final den = double.parse(denominador);
          final factor = num / den;

          coefX += (ingreso ? factor : -factor) * fac;
          ecuacion.add(
              '${ingreso ? '+' : '-'} ${(factor * fac).toStringAsFixed(6)}X');
          print(
              '🧮 Valor con periodo: ${(ingreso ? '+' : '-')}${(factor * fac).toStringAsFixed(12)}X');
        } else {
          final num = double.parse(texto);
          final contrib = (ingreso ? 1 : -1) * num * fac;
          constante += contrib;
          ecuacion.add(
              '${contrib >= 0 ? '+' : '-'} ${contrib.abs().toStringAsFixed(2)}');
          print(
              '🧮 Valor con periodo: ${(ingreso ? '+' : '-')}${(num * fac).toStringAsFixed(12)}');
        }
      }
    }

    void _procesar(dynamic valor, int? periodo, String tipoFlujo) {
      if (periodo == null) {
        _procesarValorSinPeriodo(valor, tipoFlujo);
      } else {
        final fac = _factor(periodo, tipoFlujo);
        _procesarValorConFactor(valor, fac, tipoFlujo);
      }
    }

    for (final m in d.movimientos) {
      if (m.valor != null) {
        _procesar(m.valor, m.periodo, m.tipo);
      }
    }

    for (final v in d.valores) {
      if (v.valor != null) {
        _procesar(v.valor, v.periodo, v.flujo);
      }
    }

    final ecuacionFinal = ecuacion.join(' ');
    steps.add('🧮 Ecuación construida: $ecuacionFinal = 0');

    if (coefX == 0) {
      throw StateError('No hay incógnita X en el problema.');
    }

    final X = -constante / coefX;

    steps.add('🔎 Resolviendo:');
    steps.add('X = -($constante) / ($coefX)');
    steps.add('X = ${X.toStringAsFixed(6)}');

    return EquationAnalysis(
      equation: '$ecuacionFinal = 0',
      steps: steps,
      solution: X,
    );
  }
}
