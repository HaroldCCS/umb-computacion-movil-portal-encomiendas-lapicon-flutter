import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/data/models/encomienda.dart';
import 'package:lapticon_app/data/models/estado.dart';
import 'package:lapticon_app/features/viajero/viajero_logic.dart';

Encomienda _e(
  String id, {
  EstadoEncomienda estado = EstadoEncomienda.tomada,
  String? remitente = 'rem',
  String? viajero,
  DateTime? creada,
}) => Encomienda(
  id: id,
  ciudadOrigen: 'Bogota',
  ciudadDestino: 'Miami',
  observaciones: '',
  moneda: 'USD',
  valor: 10,
  estado: estado,
  remitenteUid: remitente,
  viajeroUid: viajero,
  creadaEn: creada,
);

void main() {
  group('número de vuelo', () {
    test('acepta formatos comunes', () {
      for (final v in [
        'AA123',
        'AV 24',
        'av24',
        '4C5021',
        'LA2401A',
        'AV-24',
      ]) {
        expect(validarNumeroVuelo(v), isNull, reason: v);
      }
    });
    test('rechaza inválidos', () {
      for (final v in ['', '123', 'A', 'AVIANCA', 'AV12345', 'AV']) {
        expect(validarNumeroVuelo(v), isNotNull, reason: v);
      }
    });
    test('normaliza', () {
      expect(normalizarVuelo(' av 24 '), 'AV24');
      expect(normalizarVuelo('la-2401'), 'LA2401');
    });
  });

  group('combinarEntregas', () {
    test('une servidor (viajero = yo) y registro local, sin duplicados', () {
      final servidor = [
        _e('1', viajero: 'yo', estado: EstadoEncomienda.entregada),
        _e('2', viajero: 'otro'),
        _e('3', remitente: 'yo', viajero: null), // mía como remitente
      ];
      final locales = [
        _e('1', viajero: 'yo', estado: EstadoEncomienda.tomada),
        _e('4', viajero: 'yo'),
      ];
      final r = combinarEntregas(
        servidor: servidor,
        locales: locales,
        uid: 'yo',
      );
      expect(r.map((e) => e.id).toSet(), {'1', '4'});
      // El servidor gana: la 1 aparece como entregada.
      expect(
        r.firstWhere((e) => e.id == '1').estado,
        EstadoEncomienda.entregada,
      );
      // Las tomadas (activas) van primero.
      expect(r.first.id, '4');
    });

    test('incluye del servidor las que tomé aunque no traiga viajero', () {
      final r = combinarEntregas(
        servidor: [_e('9', viajero: null)],
        locales: [_e('9', viajero: 'yo')],
        uid: 'yo',
      );
      expect(r.single.id, '9');
    });
  });

  test('paraTomar excluye las propias y las no disponibles', () {
    final r = paraTomar([
      _e('a', estado: EstadoEncomienda.disponible),
      _e('b', estado: EstadoEncomienda.disponible, remitente: 'yo'),
      _e('c', estado: EstadoEncomienda.tomada),
    ], 'yo');
    expect(r.map((e) => e.id), ['a']);
  });

  test('paraTomar excluye las propias aunque no traigan el uid', () {
    final r = paraTomar(
      [
        _e('a', estado: EstadoEncomienda.disponible),
        _e('mia', estado: EstadoEncomienda.disponible),
      ],
      'yo',
      idsPropios: {'mia'},
    );
    expect(r.map((e) => e.id), ['a']);
  });

  test('conservarNombres completa lo que no trae la respuesta', () {
    final previa = Encomienda.fromJson({
      '_id': 'x',
      'estado': 'tomada',
      'remitenteNombre': 'Harold',
    });
    final nueva = Encomienda.fromJson({
      '_id': 'x',
      'uid': 'uidR',
      'estado': 'entregada',
    });
    final r = conservarNombres(nueva, previa);
    expect(r.remitenteUid, 'uidR');
    expect(r.remitenteNombre, 'Harold');
    expect(r.estado, EstadoEncomienda.entregada);
  });

  test('tomadaPorMi y conEstado', () {
    final e = _e('x', viajero: null, estado: EstadoEncomienda.disponible);
    expect(tomadaPorMi(e, 'yo', {}), isFalse);
    expect(tomadaPorMi(e, 'yo', {'x'}), isTrue);
    final t = conEstado(e, EstadoEncomienda.tomada, viajeroUid: 'yo');
    expect(t.estado, EstadoEncomienda.tomada);
    expect(t.viajeroUid, 'yo');
    expect(tomadaPorMi(t, 'yo', {}), isTrue);
  });

  test('encomiendaToJson es compatible con Encomienda.fromJson', () {
    final original = Encomienda(
      id: 'id1',
      ciudadOrigen: 'Bogota',
      ciudadDestino: 'Miami',
      observaciones: 'Libros',
      moneda: 'USD',
      valor: 12.5,
      estado: EstadoEncomienda.tomada,
      remitenteUid: 'rem',
      remitenteNombre: 'Laura Gómez',
      viajeroUid: 'yo',
      fechaVencimiento: DateTime(2026, 12, 1),
    );
    final copia = Encomienda.fromJson(encomiendaToJson(original));
    expect(copia.id, 'id1');
    expect(copia.valor, 12.5);
    expect(copia.estado, EstadoEncomienda.tomada);
    expect(copia.remitenteUid, 'rem');
    expect(copia.remitenteNombre, 'Laura Gómez');
    expect(copia.viajeroUid, 'yo');
    expect(copia.fechaVencimiento, DateTime(2026, 12, 1));
  });

  test('resumenVuelo reconoce el formato de AeroDataBox', () {
    final datos = resumenVuelo({
      'airline': {'name': 'Avianca'},
      'departure': {
        'airport': {'name': 'El Dorado'},
      },
      'arrival': {
        'airport': {'municipalityName': 'Miami'},
      },
    });
    expect(datos, [
      'Aerolínea: Avianca',
      'Sale de: El Dorado',
      'Llega a: Miami',
    ]);
    expect(resumenVuelo({}), isEmpty);
  });
}
