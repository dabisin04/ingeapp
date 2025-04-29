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
    if (d.periodoFocal == null) {
      throw StateError('No se definió el periodo focal.');
    }
    final int focal = d.periodoFocal!;

    // ---------- Normalización de tasas ----------
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

    print('\n🌟 Tasas normalizadas:');
    for (final t in tasasOk) {
      print(
          '• ${t.periodoInicio}-${t.periodoFin}: ${(t.valor * 100).toStringAsFixed(6)}% aplica a ${t.aplicaA}');
    }

    double coefX = 0.0;
    double constante = 0.0;
    final ecuacion = <String>[];

    // ---------- Función auxiliar para buscar tasa ----------
    double _getRate(int periodo, String tipoFlujo) {
      final tipoNormalized = RateConversionUtils.normalizeTipo(tipoFlujo);

      final tasasAplicables = tasasOk.where((t) {
        final inRango = periodo >= t.periodoInicio && periodo <= t.periodoFin;
        final aplicaNormalized = RateConversionUtils.normalizeTipo(t.aplicaA);
        return inRango &&
            (aplicaNormalized == tipoNormalized || aplicaNormalized == 'todos');
      }).toList();

      if (tasasAplicables.isEmpty) {
        throw StateError(
            '❌ No se encontró tasa aplicable para t=$periodo ($tipoFlujo)');
      }

      final sumaTasas =
          tasasAplicables.map((t) => t.valor).reduce((a, b) => a + b);

      print('📈 Tasas en t=$periodo para $tipoFlujo: '
          '${tasasAplicables.map((t) => (t.valor * 100).toStringAsFixed(4)).join('% + ')} '
          '= ${(sumaTasas * 100).toStringAsFixed(4)}%');

      return sumaTasas;
    }

    // ---------- Función de cálculo de factor ----------
    double _factor(int periodo, String tipoFlujo) {
      if (periodo == focal) {
        print('💬 Factor de t=$periodo a t=$focal es 1.0 (mismo periodo)');
        return 1.0;
      }

      double factor = 1.0;
      final sentido =
          periodo < focal ? 1 : -1; // ⚡️ CAMBIO AQUI: comparación cambia

      int actual = periodo;

      print('\n🔎 Cálculo de factor de t=$periodo a t=$focal:');

      while (actual != focal) {
        final tasaActual = _getRate(actual, tipoFlujo);
        int siguienteCambio = actual;

        while (siguienteCambio != focal) {
          final next = siguienteCambio + sentido;
          try {
            final tasaNext = _getRate(next, tipoFlujo);
            if (tasaNext != tasaActual) break;
          } catch (_) {
            break;
          }
          siguienteCambio = next;
        }
        if (siguienteCambio == actual) siguienteCambio += sentido;

        final nPeriodos = (siguienteCambio - actual).abs();
        final tramoFactor = sentido > 0
            ? pow(1 + tasaActual, nPeriodos)
                .toDouble() // 🔥 CRECIMIENTO HACIA FUTURO
            : 1 / pow(1 + tasaActual, nPeriodos); // 🔥 DESCUENTO HACIA ATRAS

        print(
            '➔ De t=$actual a t=$siguienteCambio usando tasa ${(tasaActual * 100).toStringAsFixed(4)}% '
            'por $nPeriodos periodos: '
            'factor parcial = ${tramoFactor.toStringAsFixed(12)}');

        factor *= tramoFactor;
        actual = siguienteCambio;
      }

      print(
          '✅ Factor final de t=$periodo a t=$focal: ${factor.toStringAsFixed(12)}');
      return factor;
    }

    // ---------- Procesamiento de valores ----------
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
          final factor =
              double.parse(texto.replaceAll('*', '').replaceAll('X', ''));
          coefX += ingreso ? factor : -factor;
          ecuacion.add('${ingreso ? '+' : '-'} ${factor.toStringAsFixed(6)}X');
          print(
              '🧮 Valor sin periodo: ${ingreso ? '+' : '-'}${factor.toStringAsFixed(6)}X');
        } else if (texto.contains('/')) {
          final partes = texto.split('/');
          final numStr = partes[0].trim();
          final den = double.parse(partes[1].trim());

          if (numStr.contains('X')) {
            final coefStr = numStr.replaceAll('X', '').trim();
            final coef = coefStr.isEmpty ? 1.0 : double.parse(coefStr);
            final factor = coef / den;
            coefX += ingreso ? factor : -factor;
            ecuacion
                .add('${ingreso ? '+' : '-'} ${factor.toStringAsFixed(6)}X');
            print(
                '🧮 Valor sin periodo: ${ingreso ? '+' : '-'}${factor.toStringAsFixed(6)}X');
          } else {
            final num = double.parse(numStr);
            final factor = num / den;
            constante += ingreso ? factor : -factor;
            ecuacion.add('${ingreso ? '+' : '-'} ${factor.toStringAsFixed(2)}');
            print(
                '🧮 Valor sin periodo: ${ingreso ? '+' : '-'}${factor.toStringAsFixed(2)}');
          }
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
          final coef =
              double.parse(texto.replaceAll('*', '').replaceAll('X', ''));
          coefX += (ingreso ? coef : -coef) * fac;
          ecuacion.add(
              '${ingreso ? '+' : '-'} ${(coef * fac).toStringAsFixed(6)}X');
          print(
              '🧮 Valor con periodo: ${(ingreso ? '+' : '-')}${(coef * fac).toStringAsFixed(12)}X');
        } else if (texto.contains('/')) {
          final partes = texto.split('/');
          final numStr = partes[0].trim();
          final den = double.parse(partes[1].trim());

          if (numStr.contains('X')) {
            final coefStr = numStr.replaceAll('X', '').trim();
            final coef = coefStr.isEmpty ? 1.0 : double.parse(coefStr);
            final factorX = coef / den;
            coefX += (ingreso ? factorX : -factorX) * fac;
            ecuacion.add(
                '${ingreso ? '+' : '-'} ${(factorX * fac).toStringAsFixed(6)}X');
            print(
                '🧮 Valor con periodo: ${(ingreso ? '+' : '-')}${(factorX * fac).toStringAsFixed(12)}X');
          } else {
            final num = double.parse(numStr);
            final factorNum = num / den;
            constante += (ingreso ? factorNum : -factorNum) * fac;
            ecuacion.add(
                '${ingreso ? '+' : '-'} ${(factorNum * fac).toStringAsFixed(2)}');
            print(
                '🧮 Valor con periodo: ${(ingreso ? '+' : '-')}${(factorNum * fac).toStringAsFixed(12)}');
          }
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

    // ---------- Procesar todo ----------
    for (final m in d.movimientos) {
      if (m.valor != null) _procesar(m.valor, m.periodo, m.tipo);
    }
    for (final v in d.valores) {
      if (v.valor != null) _procesar(v.valor, v.periodo, v.flujo);
    }

    // ---------- Armar ecuación ----------
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
