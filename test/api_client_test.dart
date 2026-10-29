import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lapticon_app/core/network/api_client.dart';
import 'package:lapticon_app/core/network/app_exception.dart';
import 'package:lapticon_app/data/models/estado.dart';
import 'package:lapticon_app/data/repositories/chat_repository.dart';

void main() {
  late List<http.Request> requests;
  late List<bool> refreshes;

  ApiClient clientWith(
    http.Response Function(http.Request req, int n) handler, {
    String? token = 'tok-1',
  }) {
    requests = [];
    refreshes = [];
    return ApiClient(
      baseUrl: 'https://api.test/',
      tokenProvider: ({bool forceRefresh = false}) async {
        refreshes.add(forceRefresh);
        if (token == null) return null;
        return forceRefresh ? 'tok-2' : token;
      },
      httpClient: MockClient((req) async {
        requests.add(req);
        return handler(req, requests.length);
      }),
    );
  }

  test('PATCH manda el cuerpo en JSON (cancelar viaje)', () async {
    final api = clientWith(
      (req, _) => http.Response(jsonEncode({'message': 'ok'}), 200),
    );
    await api.patch('/api/viajes/v1/estado', body: {'estado': 'cancelado'});
    expect(requests.single.method, 'PATCH');
    expect(jsonDecode(requests.single.body), {'estado': 'cancelado'});
  });

  test('envía el Bearer token y decodifica JSON', () async {
    final api = clientWith(
      (req, _) => http.Response(jsonEncode({'ok': true}), 200),
    );
    final json = await api.get('/api/viajes');
    expect(json, {'ok': true});
    expect(requests.single.url.toString(), 'https://api.test/api/viajes');
    expect(requests.single.headers['Authorization'], 'Bearer tok-1');
  });

  test('rutas públicas no envían token', () async {
    final api = clientWith((req, _) => http.Response('[]', 200));
    await api.get('/api/ciudades/paises', auth: false);
    expect(requests.single.headers.containsKey('Authorization'), isFalse);
    expect(refreshes, isEmpty);
  });

  test('query params', () async {
    final api = clientWith((req, _) => http.Response('[]', 200));
    await api.get(
      '/api/encomiendas/disponibles',
      query: {'origen': 'Bogota', 'destino': 'Miami'},
    );
    expect(requests.single.url.queryParameters, {
      'origen': 'Bogota',
      'destino': 'Miami',
    });
  });

  test('ante un 401 refresca el token y reintenta una vez', () async {
    final api = clientWith(
      (req, n) => n == 1
          ? http.Response('{"message":"Token expirado"}', 401)
          : http.Response('{"uid":"u1"}', 200),
    );
    final json = await api.get('/api/users/u1');
    expect(json, {'uid': 'u1'});
    expect(refreshes, [false, true]);
    expect(requests.last.headers['Authorization'], 'Bearer tok-2');
  });

  test('errores del backend con su mensaje', () async {
    final api = clientWith(
      (req, _) => http.Response(
        jsonEncode({'message': 'Ya tienes un viaje activo'}),
        400,
      ),
    );
    await expectLater(
      api.post('/api/viajes', body: {'numeroVuelo': 'AA123'}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', 'Ya tienes un viaje activo'),
      ),
    );
    expect(
      requests.single.headers['Content-Type'],
      startsWith('application/json'),
    );
    expect(jsonDecode(requests.single.body), {'numeroVuelo': 'AA123'});
  });

  test('403 sin mensaje usa el texto por defecto', () async {
    final api = clientWith((req, _) => http.Response('', 403));
    await expectLater(
      api.get('/api/users/otro'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'No tienes permiso para hacer esto.',
        ),
      ),
    );
  });

  test('sin sesión lanza NotAuthenticatedException', () async {
    final api = clientWith((req, _) => http.Response('{}', 200), token: null);
    await expectLater(
      api.get('/api/viajes'),
      throwsA(isA<NotAuthenticatedException>()),
    );
    expect(requests, isEmpty);
  });

  test('extractMessage reconoce formatos comunes', () {
    expect(ApiClient.extractMessage({'error': 'x'}), 'x');
    expect(ApiClient.extractMessage({'msg': ' y '}), 'y');
    expect(
      ApiClient.extractMessage({
        'error': {'message': 'z'},
      }),
      'z',
    );
    expect(
      ApiClient.extractMessage({
        'errors': [
          {'msg': 'campo requerido'},
        ],
      }),
      'campo requerido',
    );
    expect(ApiClient.extractMessage('<html>Error</html>'), isNull);
  });

  test('estado del chat: el 500 del backend no bloquea el chat', () async {
    final api = clientWith(
      (req, _) => http.Response(
        jsonEncode({'error': 'Error interno del servidor'}),
        500,
      ),
    );
    expect(await ChatRepository(api).estado('a_b'), EstadoChat.abierto);
  });
}
