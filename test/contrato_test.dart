import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/utils/formatters.dart';
import 'package:lapticon_app/data/models/encomienda.dart';
import 'package:lapticon_app/data/models/estado.dart';
import 'package:lapticon_app/data/models/resumen_calificaciones.dart';
import 'package:lapticon_app/data/models/usuario.dart';
import 'package:lapticon_app/data/models/viaje.dart';
import 'package:lapticon_app/data/repositories/chat_repository.dart';

/// Pruebas del contrato compartido de las prácticas 3–6.
void main() {
  group('Encomienda', () {
    test('lee la respuesta con uid simples', () {
      final e = Encomienda.fromJson({
        '_id': 'e1',
        'ciudadOrigen': 'Bogota',
        'ciudadDestino': 'Miami',
        'observaciones': 'demo',
        'moneda': 'USD',
        'valor': 10,
        'estado': 'tomada',
        'remitente': 'uidR',
        'viajero': 'uidV',
        'fechaVencimiento': '2026-12-01',
      });
      expect(e.id, 'e1');
      expect(e.estado, EstadoEncomienda.tomada);
      expect(e.estado.etiqueta, 'Tomada');
      expect(e.remitenteUid, 'uidR');
      expect(e.viajeroUid, 'uidV');
      expect(e.fechaVencimiento, DateTime(2026, 12, 1));
    });

    test('lee usuarios "populados" y valores como texto', () {
      final e = Encomienda.fromJson({
        'encomienda': {
          'id': 'e2',
          'valor': '12,5',
          'estado': 'desconocido-raro',
          'viajero': {'uid': 'v9', 'nombre': 'Andrés', 'apellido': 'Pérez'},
        },
      });
      expect(e.id, 'e2');
      expect(e.valor, 12.5);
      expect(e.moneda, 'USD');
      expect(e.estado, EstadoEncomienda.desconocido);
      expect(e.viajeroUid, 'v9');
      expect(e.viajeroNombre, 'Andrés Pérez');
    });

    test('body de creación igual al de Postman', () {
      expect(
        Encomienda.crearBody(
          ciudadOrigen: 'Bogota',
          ciudadDestino: 'Miami',
          observaciones: 'demo taller flutter',
          moneda: 'USD',
          valor: 10,
        ),
        {
          'ciudadOrigen': 'Bogota',
          'ciudadDestino': 'Miami',
          'observaciones': 'demo taller flutter',
          'moneda': 'USD',
          'valor': 10,
        },
      );
    });
  });

  group('Viaje', () {
    test('body de creación (fecha YYYY-MM-DD, vuelo en mayúsculas)', () {
      expect(
        Viaje.crearBody(
          numeroVuelo: 'aa 123',
          ciudadOrigen: 'Bogota',
          ciudadDestino: 'Miami',
          fechaViaje: DateTime(2026, 12, 1),
        ),
        {
          'numeroVuelo': 'AA123',
          'ciudadOrigen': 'Bogota',
          'ciudadDestino': 'Miami',
          'fechaViaje': '2026-12-01',
        },
      );
    });

    test('fromJson', () {
      final v = Viaje.fromJson({
        '_id': 'v1',
        'numeroVuelo': 'AA123',
        'ciudadOrigen': 'Bogota',
        'ciudadDestino': 'Miami',
        'fechaViaje': '2026-12-01',
        'estado': 'disponible',
        'viajero': {'uid': 'u1', 'nombre': 'Ana'},
      });
      expect(v.estado, EstadoViaje.disponible);
      expect(v.viajeroUid, 'u1');
      expect(v.viajeroNombre, 'Ana');
    });
  });

  group('Chat', () {
    test('chatId ordena los uid', () {
      expect(ChatRepository.chatId('b', 'a'), 'a_b');
      expect(ChatRepository.chatId('a', 'b'), 'a_b');
    });
    test('parseEstado tolera varias formas', () {
      expect(
        ChatRepository.parseEstado({'estado': 'cerrado'}),
        EstadoChat.cerrado,
      );
      expect(ChatRepository.parseEstado({'cerrado': true}), EstadoChat.cerrado);
      expect(
        ChatRepository.parseEstado({'estado': 'abierto'}),
        EstadoChat.abierto,
      );
      expect(ChatRepository.parseEstado(null), EstadoChat.abierto);
    });
  });

  group('Fmt', () {
    test('dinero', () {
      expect(Fmt.dinero(10, 'usd'), 'USD 10');
      expect(Fmt.dinero(50000, 'COP'), 'COP 50.000');
      expect(Fmt.dinero(12.5, 'USD'), 'USD 12,50');
    });
    test('fecha y relativo', () {
      expect(Fmt.fecha(DateTime(2026, 12, 1)), '1 dic 2026');
      final ahora = DateTime(2026, 10, 22, 12);
      expect(
        Fmt.relativo(ahora.subtract(const Duration(minutes: 5)), ahora: ahora),
        'hace 5 min',
      );
      expect(
        Fmt.relativo(ahora.subtract(const Duration(hours: 3)), ahora: ahora),
        'hace 3 h',
      );
      expect(Fmt.hora(DateTime(2026, 1, 1, 9, 5)), '09:05');
    });
  });

  // Respuestas reales del backend (22-oct-2026, referencias/respuestas/).
  group('Respuestas reales', () {
    test('PATCH /api/viajes/:id/estado devuelve el viaje en "viaje"', () {
      // referencias/respuestas/fase0_patch_viaje_cancelado.json (28-oct).
      final v = Viaje.fromJson({
        'message': 'Estado actualizado',
        'viaje': {
          '_id': '6ae25c6a411da1034525b232',
          'uid': 'uidV',
          'numeroVuelo': 'A777',
          'ciudadOrigen': 'Bogota',
          'ciudadDestino': 'Medellin',
          'fechaViaje': '2026-10-30T00:00:00.000Z',
          'estado': 'cancelado',
          'createdAt': '2026-10-28T20:34:50.718Z',
          '__v': 0,
        },
      });
      expect(v.id, '6ae25c6a411da1034525b232');
      expect(v.estado, EstadoViaje.cancelado);
      expect(EstadoViaje.parse('Contactado'), EstadoViaje.contactado);
      expect(EstadoViaje.parse('pausado'), EstadoViaje.desconocido);
    });

    test('GET /api/users/:uid viene envuelto en "user" y sin rol', () {
      final u = Usuario.fromJson({
        'user': {
          '_id': '6ada5bbe55174b0d3b920bae',
          'uid': 'uidR',
          '__v': 0,
          'apellido': 'Prueba',
          'createdAt': '2026-10-22T18:53:50.787Z',
          'email': 'remitente@correo.com',
          'nacionalidad': 'Colombia',
          'nombre': 'Ana',
          'telefono': '3000000000',
        },
      });
      expect(u.uid, 'uidR');
      expect(u.completo, isTrue);
      expect(u.rol, isNull, reason: 'el backend ignora el campo rol');
      expect(u.creadoEn, DateTime.utc(2026, 10, 22, 18, 53, 50, 787));
    });

    test('GET /api/encomiendas: remitente en uid y viajero en viajeroId', () {
      final e = Encomienda.fromJson({
        '_id': '6ada5d86a4012aeb7e63d853',
        'uid': 'uidR',
        'ciudadOrigen': 'Bogota',
        'ciudadDestino': 'Miami',
        'observaciones': 'Prueba Lapticon: libro pequeño',
        'moneda': 'USD',
        'valor': 15,
        'estado': 'tomada',
        'viajeroId': 'uidV',
        'fechaCreacion': '2026-10-22T19:01:26.915Z',
        'fechaVencimiento': '2026-11-22T19:01:26.915Z',
        'fechaDisponibleDesde': '2026-10-22T19:01:26.915Z',
        'fechaLimiteEntrega': null,
        '__v': 0,
      });
      expect(e.remitenteUid, 'uidR');
      expect(e.viajeroUid, 'uidV');
      expect(e.creadaEn, DateTime.utc(2026, 10, 22, 19, 1, 26, 915));
      expect(e.fechaVencimiento, DateTime.utc(2026, 11, 22, 19, 1, 26, 915));
    });

    test('GET /disponibles trae remitenteNombre y no el uid', () {
      final e = Encomienda.fromJson({
        '_id': '6ad95be0f8b6da54469cfc57',
        'ciudadOrigen': 'Bogota',
        'ciudadDestino': 'Miami',
        'observaciones': 'demo taller flutter',
        'valor': 10,
        'moneda': 'USD',
        'estado': 'disponible',
        'remitenteNombre': 'Manuel',
        'fechaCreacion': '2026-10-22T00:42:08.556Z',
        'fechaVencimiento': '2026-11-22T00:42:08.556Z',
      });
      expect(e.remitenteUid, isNull);
      expect(e.remitenteNombre, 'Manuel');
    });

    test('PUT /:id/estado responde { mensaje, encomienda }', () {
      final e = Encomienda.fromJson({
        'mensaje': 'Estado actualizado',
        'encomienda': {'_id': 'e1', 'uid': 'uidR', 'estado': 'vencida'},
      });
      expect(e.id, 'e1');
      expect(e.estado, EstadoEncomienda.vencida);
    });

    test('PUT /tomar/:id solo trae { mensaje } (sin encomienda)', () {
      final e = Encomienda.fromJson({
        'mensaje': 'Encomienda tomada exitosamente',
      });
      expect(e.id, isEmpty);
    });

    test('estados válidos del backend', () {
      for (final v in [
        'disponible',
        'tomada',
        'vencida',
        'entregada',
        'recibida',
      ]) {
        expect(EstadoEncomienda.parse(v), isNot(EstadoEncomienda.desconocido));
        expect(EstadoEncomienda.parse(v).apiValue, v);
      }
      expect(EstadoEncomienda.parse('cancelada'), EstadoEncomienda.desconocido);
    });

    test('GET /api/ratings/:uid usa "timestamp" como fecha', () {
      final r = ResumenCalificaciones.fromJson({
        'total': 1,
        'promedio': 5,
        'calificaciones': [
          {
            '_id': '6ada5e83a4012aeb7e63d87f',
            'usuarioOrigen': 'uidR',
            'usuarioDestino': 'uidV',
            'rolDestino': 'viajero',
            'calificacion': 5,
            'comentario': 'Prueba antes de entregar',
            'timestamp': '2026-10-22T19:05:39.400Z',
            '__v': 0,
          },
        ],
      });
      expect(r.total, 1);
      expect(r.promedio, 5);
      expect(
        r.calificaciones.single.fecha,
        DateTime.utc(2026, 10, 22, 19, 5, 39, 400),
      );
    });
  });
}
