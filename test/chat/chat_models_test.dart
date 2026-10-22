import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/data/repositories/chat_repository.dart';
import 'package:lapticon_app/features/chat/models/conversacion.dart';
import 'package:lapticon_app/features/chat/models/mensaje_chat.dart';

void main() {
  group('MensajeChat.fromMap', () {
    test('lee un mensaje confirmado por el servidor', () {
      final m = MensajeChat.fromMap('m1', {
        'texto': 'Hola',
        'emisorUid': 'a',
        'creadoEn': DateTime(2026, 10, 22, 14, 5),
      });
      expect(m.texto, 'Hola');
      expect(m.esDe('a'), isTrue);
      expect(m.pendiente, isFalse);
      expect(m.fecha, DateTime(2026, 10, 22, 14, 5));
    });

    test('serverTimestamp pendiente: usa la hora local y queda pendiente', () {
      final local = DateTime(2026, 10, 22, 9, 30);
      final m = MensajeChat.fromMap('m2', {
        'texto': 'Enviando',
        'emisorUid': 'a',
        'creadoEn': null,
        'creadoLocal': local.millisecondsSinceEpoch,
      });
      expect(m.pendiente, isTrue);
      expect(m.fecha, local);
    });

    test('escritura local pendiente aunque traiga fecha', () {
      final m = MensajeChat.fromMap('m3', {
        'texto': 'x',
        'emisorUid': 'b',
        'creadoEn': DateTime(2026),
      }, pendienteDeEscritura: true);
      expect(m.pendiente, isTrue);
    });
  });

  group('agruparPorDia', () {
    final ahora = DateTime(2026, 10, 22, 18);
    MensajeChat msg(String id, DateTime f) =>
        MensajeChat(id: id, texto: id, emisorUid: 'a', fecha: f);

    test('ordena e inserta separadores Hoy / Ayer / fecha', () {
      final items = agruparPorDia([
        msg('hoy2', DateTime(2026, 10, 22, 10)),
        msg('antes', DateTime(2026, 10, 3, 8)),
        msg('ayer', DateTime(2026, 10, 21, 20)),
        msg('hoy1', DateTime(2026, 10, 22, 9)),
      ], ahora: ahora);

      final etiquetas = items
          .map(
            (i) => switch (i) {
              SeparadorDia(:final etiqueta) => '[$etiqueta]',
              ItemMensaje(:final mensaje) => mensaje.id,
            },
          )
          .toList();
      expect(etiquetas, [
        '[3 oct]',
        'antes',
        '[Ayer]',
        'ayer',
        '[Hoy]',
        'hoy1',
        'hoy2',
      ]);
    });

    test('lista vacía', () {
      expect(agruparPorDia(const []), isEmpty);
    });
  });

  group('Conversacion', () {
    test('fromMap con participantes y nombres', () {
      final c = Conversacion.fromMap('a_b', {
        'participantes': ['a', 'b'],
        'nombres': {'a': 'Laura Gómez', 'b': 'Andrés Ruiz'},
        'ruta': 'Bogota → Miami',
        'ultimoMensaje': 'Nos vemos en el aeropuerto',
        'ultimoEmisorUid': 'b',
        'actualizadoEn': DateTime(2026, 10, 22),
      });
      expect(c.otroUid('a'), 'b');
      expect(c.nombreDe(c.otroUid('a')), 'Andrés Ruiz');
      expect(c.ruta, 'Bogota → Miami');
      expect(c.encomiendaId, isNull);
    });

    test('sin participantes los deduce del id y sin nombre usa "Usuario"', () {
      final c = Conversacion.fromMap('a_b', const {});
      expect(c.participantes, ['a', 'b']);
      expect(c.otroUid('b'), 'a');
      expect(c.nombreDe('a'), 'Usuario');
      expect(c.nombreDe(null), 'Usuario');
    });

    test('ordenar: pendientes arriba y luego las más recientes', () {
      final lista = Conversacion.ordenar([
        Conversacion.fromMap('v', {'actualizadoEn': DateTime(2026, 1, 1)}),
        Conversacion.fromMap('n', {'actualizadoEn': DateTime(2026, 6, 1)}),
        Conversacion.fromMap('p', const {}),
      ]);
      expect(lista.map((c) => c.id), ['p', 'n', 'v']);
    });

    test('el id del chat es el mismo sin importar quién escribe primero', () {
      expect(ChatRepository.chatId('zeta', 'alfa'), 'alfa_zeta');
      expect(
        ChatRepository.chatId('alfa', 'zeta'),
        ChatRepository.chatId('zeta', 'alfa'),
      );
    });
  });

  test('inicialesDe', () {
    expect(inicialesDe('Laura Gómez'), 'LG');
    expect(inicialesDe('  ana  '), 'A');
    expect(inicialesDe(''), '?');
  });
}
