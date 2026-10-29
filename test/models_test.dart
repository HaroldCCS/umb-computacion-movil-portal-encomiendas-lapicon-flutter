import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/data/models/resumen_calificaciones.dart';
import 'package:lapticon_app/data/models/rol.dart';
import 'package:lapticon_app/data/models/usuario.dart';
import 'package:lapticon_app/data/repositories/catalogo_repository.dart';

void main() {
  group('Usuario y fechaNacimiento (docs/11 §2D)', () {
    test('el cuerpo nunca lleva uid ni email; la fecha solo si existe', () {
      final u = Usuario.fromJson({
        'user': {
          'uid': 'abc',
          'nombre': 'Ana',
          'apellido': 'G',
          'telefono': '300',
          'nacionalidad': 'Peru',
          'email': 'a@b.co',
          'fechaNacimiento': '1999-01-31T00:00:00.000Z',
        },
      });
      expect(u.fechaNacimiento, '1999-01-31');
      expect(u.toRegisterJson(), {
        'nombre': 'Ana',
        'apellido': 'G',
        'telefono': '300',
        'nacionalidad': 'Peru',
        'fechaNacimiento': '1999-01-31',
      });
      final sin = Usuario.fromJson({'uid': 'abc', 'email': 'a@b.co'});
      expect(sin.fechaNacimiento, isNull);
      expect(sin.toRegisterJson().keys, isNot(contains('fechaNacimiento')));
      for (final c in [u.toRegisterJson(), sin.toRegisterJson()]) {
        expect(c.keys, isNot(contains('uid')));
        expect(c.keys, isNot(contains('email')));
      }
    });
  });

  group('Usuario.fromJson', () {
    test('lee el perfil directo', () {
      final u = Usuario.fromJson({
        'uid': 'abc',
        'nombre': 'Estudiante',
        'apellido': 'Demo',
        'telefono': '3000000000',
        'nacionalidad': 'Colombia',
        'rol': 'Viajero',
      });
      expect(u.uid, 'abc');
      expect(u.nombreCompleto, 'Estudiante Demo');
      expect(u.iniciales, 'ED');
      expect(u.rol, Rol.viajero);
      expect(u.completo, isTrue);
    });

    test('lee el perfil envuelto y usa el uid de respaldo', () {
      final u = Usuario.fromJson({
        'usuario': {'nombre': 'Ana', 'apellido': 'Ruiz', 'telefono': '1234567'},
      }, uidFallback: 'xyz');
      expect(u.uid, 'xyz');
      expect(u.nombre, 'Ana');
      expect(u.rol, isNull);
    });

    test('perfil incompleto', () {
      final u = Usuario.fromJson({'uid': 'a', 'nombre': 'Solo'});
      expect(u.completo, isFalse);
    });

    test('toRegisterJson coincide con el body de Postman', () {
      const u = Usuario(
        uid: 'a',
        nombre: 'Estudiante',
        apellido: 'Demo',
        telefono: '3000000000',
        nacionalidad: 'Colombia',
      );
      expect(u.toRegisterJson(), {
        'nombre': 'Estudiante',
        'apellido': 'Demo',
        'telefono': '3000000000',
        'nacionalidad': 'Colombia',
      });
    });
  });

  test('ResumenCalificaciones con la respuesta real del backend', () {
    final r = ResumenCalificaciones.fromJson({
      'total': 0,
      'promedio': null,
      'calificaciones': <dynamic>[],
    });
    expect(r.vacio, isTrue);
    expect(r.promedio, isNull);

    final r2 = ResumenCalificaciones.fromJson({
      'total': 2,
      'promedio': 4.5,
      'calificaciones': [
        {'calificacion': 5, 'comentario': 'excelente', 'rolDestino': 'viajero'},
        {'calificacion': '4', 'comentario': ''},
      ],
    });
    expect(r2.total, 2);
    expect(r2.promedio, 4.5);
    expect(r2.calificaciones.map((c) => c.calificacion), [5, 4]);
  });

  test('Rol.tryParse', () {
    expect(Rol.tryParse('remitente'), Rol.remitente);
    expect(Rol.tryParse(' VIAJERO '), Rol.viajero);
    expect(Rol.tryParse('admin'), isNull);
    expect(Rol.tryParse(null), isNull);
    expect(Rol.remitente.opuesto, Rol.viajero);
  });

  test('limpiarLista quita corruptos y duplicados por mayúsculas', () {
    final limpia = CatalogoRepository.limpiarLista([
      'Colombia',
      'Curaï¿½ï',
      'South Georgia And South Sandwich Islands',
      'South Georgia and South Sandwich Islands',
      'albania',
      '',
      42,
    ]);
    expect(limpia, [
      'albania',
      'Colombia',
      'South Georgia And South Sandwich Islands',
    ]);
  });
}
