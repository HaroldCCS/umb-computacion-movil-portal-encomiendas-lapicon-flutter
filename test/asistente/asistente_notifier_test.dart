import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapticon_app/core/network/app_exception.dart';
import 'package:lapticon_app/data/repositories/chatbot_repository.dart';
import 'package:lapticon_app/features/asistente/asistente_controller.dart';
import 'package:lapticon_app/providers.dart';

class _FakeChatbot implements ChatbotRepository {
  final preguntas = <String>[];
  AppException? fallarCon;

  @override
  Future<String> enviar(String mensajeUsuario) async {
    preguntas.add(mensajeUsuario);
    final error = fallarCon;
    if (error != null) throw error;
    return 'Respuesta a: $mensajeUsuario';
  }
}

void main() {
  late _FakeChatbot fake;
  late ProviderContainer container;

  setUp(() {
    fake = _FakeChatbot();
    container = ProviderContainer(
      overrides: [chatbotRepositoryProvider.overrideWithValue(fake)],
    );
  });

  tearDown(() => container.dispose());

  AsistenteState leer() => container.read(asistenteProvider);

  test('empieza con el saludo y sin escribir', () {
    final sub = container.listen(asistenteProvider, (_, _) {});
    expect(leer().mensajes.single.texto, bienvenidaAsistente.texto);
    expect(leer().esNueva, isTrue);
    expect(leer().escribiendo, isFalse);
    sub.close();
  });

  test('enviar agrega la pregunta y la respuesta', () async {
    final sub = container.listen(asistenteProvider, (_, _) {});
    final futuro = container
        .read(asistenteProvider.notifier)
        .enviar('  ¿Cómo publico?  ');
    expect(leer().escribiendo, isTrue);
    await futuro;

    final mensajes = leer().mensajes;
    expect(mensajes, hasLength(3));
    expect(mensajes[1].autor, AutorMensaje.usuario);
    expect(mensajes[1].texto, '¿Cómo publico?');
    expect(mensajes[2].autor, AutorMensaje.asistente);
    expect(mensajes[2].texto, 'Respuesta a: ¿Cómo publico?');
    expect(leer().escribiendo, isFalse);
    expect(fake.preguntas, ['¿Cómo publico?']);
    sub.close();
  });

  test('ignora mensajes vacíos', () async {
    final sub = container.listen(asistenteProvider, (_, _) {});
    await container.read(asistenteProvider.notifier).enviar('   ');
    expect(leer().mensajes, hasLength(1));
    expect(fake.preguntas, isEmpty);
    sub.close();
  });

  test(
    'error del servidor muestra aviso amable y se puede reintentar',
    () async {
      final sub = container.listen(asistenteProvider, (_, _) {});
      fake.fallarCon = const ApiException(500, 'OPENROUTER_API_KEY missing');
      await container.read(asistenteProvider.notifier).enviar('Hola');

      final error = leer().mensajes.last;
      expect(error.error, isTrue);
      expect(error.texto, contains('no está disponible'));
      expect(error.reintentarCon, 'Hola');

      fake.fallarCon = null;
      await container.read(asistenteProvider.notifier).reintentar(error);
      final mensajes = leer().mensajes;
      expect(mensajes.where((m) => m.error), isEmpty);
      expect(
        mensajes.where((m) => m.autor == AutorMensaje.usuario),
        hasLength(1),
      );
      expect(mensajes.last.texto, 'Respuesta a: Hola');
      sub.close();
    },
  );

  test('reiniciar vuelve al saludo', () async {
    final sub = container.listen(asistenteProvider, (_, _) {});
    await container.read(asistenteProvider.notifier).enviar('Hola');
    container.read(asistenteProvider.notifier).reiniciar();
    expect(leer().esNueva, isTrue);
    sub.close();
  });

  test('mensajeErrorAsistente', () {
    expect(
      mensajeErrorAsistente(const NetworkException()),
      const NetworkException().message,
    );
    expect(
      mensajeErrorAsistente(const ApiException(400, 'Mensaje inválido')),
      'Mensaje inválido',
    );
    expect(
      mensajeErrorAsistente(const ApiException(503, 'x')),
      contains('no está disponible'),
    );
  });
}
