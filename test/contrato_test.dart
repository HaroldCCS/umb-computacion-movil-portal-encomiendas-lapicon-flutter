import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/utils/formatters.dart';
import 'package:lapticon_app/data/models/encomienda.dart';
import 'package:lapticon_app/data/models/estado.dart';
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
      expect(e.estado.etiqueta, 'En camino');
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
}
