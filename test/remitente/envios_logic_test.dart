import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/data/models/encomienda.dart';
import 'package:lapticon_app/data/models/estado.dart';
import 'package:lapticon_app/features/remitente/envios_logic.dart';

Encomienda _e(String id, EstadoEncomienda estado, [DateTime? creada]) =>
    Encomienda(
      id: id,
      ciudadOrigen: 'Bogota',
      ciudadDestino: 'Miami',
      observaciones: 'libro',
      moneda: 'USD',
      valor: 10,
      estado: estado,
      creadaEn: creada,
    );

void main() {
  test('agrupa por pestaña y ordena de la más reciente a la más antigua', () {
    final grupos = agruparEnvios([
      _e('a', EstadoEncomienda.disponible, DateTime(2026, 10, 1)),
      _e('b', EstadoEncomienda.tomada, DateTime(2026, 10, 5)),
      _e('c', EstadoEncomienda.entregada),
      _e('d', EstadoEncomienda.vencida),
      _e('e', EstadoEncomienda.recibida),
      _e('f', EstadoEncomienda.desconocido),
      _e('g', EstadoEncomienda.disponible),
    ]);
    expect(grupos[PestanaEnvios.activas]!.map((e) => e.id), ['b', 'a', 'g']);
    expect(grupos[PestanaEnvios.entregadas]!.map((e) => e.id), ['c', 'e']);
    expect(grupos[PestanaEnvios.historial]!.map((e) => e.id), ['d', 'f']);
  });

  test('lista vacía deja las tres pestañas vacías', () {
    final grupos = agruparEnvios(const []);
    expect(grupos.length, 3);
    expect(grupos.values.every((l) => l.isEmpty), isTrue);
  });

  test('paso actual de la línea de tiempo', () {
    expect(pasoActual(EstadoEncomienda.disponible), 0);
    expect(pasoActual(EstadoEncomienda.tomada), 1);
    expect(pasoActual(EstadoEncomienda.entregada), 2);
    expect(pasoActual(EstadoEncomienda.entregada, calificada: true), 3);
    expect(pasoActual(EstadoEncomienda.recibida), 2);
    expect(pasoActual(EstadoEncomienda.vencida), isNull);
  });

  group('validación del formulario', () {
    test('valor', () {
      expect(parseValor('12,5'), 12.5);
      expect(parseValor('50000'), 50000);
      expect(validarValor('10'), isNull);
      expect(validarValor(''), isNotNull);
      expect(validarValor('0'), isNotNull);
      expect(validarValor('1.2.3'), isNotNull);
    });
    test('observaciones', () {
      expect(validarObservaciones('Un libro'), isNull);
      expect(validarObservaciones('  '), isNotNull);
      expect(validarObservaciones('ab'), isNotNull);
      expect(validarObservaciones('x' * 201), isNotNull);
    });
    test('ruta distinta', () {
      expect(validarRuta('Bogota', 'Miami'), isNull);
      expect(validarRuta('Bogota', 'bogota '), isNotNull);
      expect(validarRuta('', 'Miami'), isNull, reason: 'lo valida el campo');
    });
  });

  test('conEstado conserva los demás datos', () {
    final original = _e('x', EstadoEncomienda.disponible, DateTime(2026));
    final retirada = conEstado(original, EstadoEncomienda.vencida);
    expect(retirada.estado, EstadoEncomienda.vencida);
    expect(retirada.id, 'x');
    expect(retirada.creadaEn, DateTime(2026));
  });
}
