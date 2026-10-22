import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('acepta correos válidos', () {
      expect(Validators.email('test30@gmail.com'), isNull);
      expect(Validators.email('  laura.gomez+envios@umb.edu.co '), isNull);
    });
    test('rechaza vacíos e incompletos', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('laura@'), isNotNull);
      expect(Validators.email('laura@correo'), isNotNull);
      expect(Validators.email('sin-arroba.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('mínimo 6 caracteres (regla de Firebase)', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
      expect(Validators.password(''), isNotNull);
    });
    test('confirmación', () {
      var original = 'secreta1';
      final v = Validators.confirmarPassword(() => original);
      expect(v('secreta1'), isNull);
      expect(v('otra'), isNotNull);
      original = 'otra';
      expect(v('otra'), isNull, reason: 'lee el valor actual del original');
    });
    test('fortaleza', () {
      expect(Validators.fortalezaPassword(''), 0);
      expect(Validators.fortalezaPassword('abc'), 1);
      expect(Validators.fortalezaPassword('abcdef'), 1);
      expect(Validators.fortalezaPassword('abcdefg1'), 2);
      expect(Validators.fortalezaPassword('Abcdefg1!'), 3);
    });
  });

  group('Validators.nombre y teléfono', () {
    test('nombres con tildes, ñ y espacios', () {
      expect(Validators.nombre('María José'), isNull);
      expect(Validators.nombre('Núñez'), isNull);
      expect(Validators.nombre('A'), isNotNull);
      expect(Validators.nombre('R2D2'), isNotNull);
    });
    test('teléfonos', () {
      expect(Validators.telefono('300 000 0000'), isNull);
      expect(Validators.telefono('+57 (300) 000-0000'), isNull);
      expect(Validators.telefono('123'), isNotNull);
      expect(Validators.telefono('300abc0000'), isNotNull);
    });
  });
}
