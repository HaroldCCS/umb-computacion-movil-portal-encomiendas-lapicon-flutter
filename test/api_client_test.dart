import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lapticon_app/core/network/api_client.dart';
import 'package:lapticon_app/core/network/app_exception.dart';
import 'package:lapticon_app/data/models/estado.dart';
import 'package:lapticon_app/data/repositories/chat_repository.dart';
import 'package:lapticon_app/data/repositories/encomienda_repository.dart';
import 'package:lapticon_app/data/repositories/viaje_repository.dart';

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

  test('buscar trae disponibles y tomadas con uid y nombre (28-oct)', () async {
    // referencias/respuestas/fase0_buscar_tomada.json, recortada.
    final api = clientWith(
      (req, _) => http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'disponibles': [],
            'tomadas': [
              {
                '_id': '6ae296ed411da1034525b384',
                'uid': 'uidR',
                'ciudadOrigen': 'Cali',
                'ciudadDestino': 'Lima',
                'moneda': 'USD',
                'valor': 1,
                'estado': 'tomada',
                'viajeroId': 'uidV',
                'fotoUrl': null,
                'remitenteNombre': 'Harold',
              },
            ],
          }),
        ),
        200,
      ),
    );
    final b = await EncomiendaRepository(
      api,
    ).buscar(origen: 'Cali', destino: 'Lima');
    expect(
      requests.single.url.toString(),
      'https://api.test/api/encomiendas/buscar?origen=Cali&destino=Lima',
    );
    expect(b.disponibles, isEmpty);
    final t = b.tomadas.single;
    expect(
      [t.remitenteUid, t.remitenteNombre, t.viajeroUid, t.estado],
      ['uidR', 'Harold', 'uidV', EstadoEncomienda.tomada],
    );
  });

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

  test('estado del chat (28-oct): activo, y cerrado con su fecha', () async {
    final api = clientWith(
      (req, n) => http.Response(
        jsonEncode(
          n == 1
              ? {'estado': 'activo', 'fechaCierre': null}
              : {
                  'estado': 'cerrado',
                  'fechaCierre': '2026-10-29T00:46:00.283Z',
                },
        ),
        200,
      ),
    );
    final repo = ChatRepository(api);
    final activo = await repo.detalleEstado('a_b');
    expect(activo.estado, EstadoChat.abierto);
    expect(activo.fechaCierre, isNull);
    final cerrado = await repo.detalleEstado('a_b');
    expect(cerrado.estado, EstadoChat.cerrado);
    expect(cerrado.fechaCierre, DateTime.utc(2026, 10, 29, 0, 46, 0, 283));
  });

  test('viajeros en ruta y vuelos: rutas públicas, sin token', () async {
    final api = clientWith(
      (req, _) => http.Response.bytes(
        utf8.encode(
          jsonEncode([
            {
              'ciudadOrigen': 'Bogota',
              'ciudadDestino': 'Miami',
              'fechaViaje': '2026-12-01T00:00:00.000Z',
              'nombreUsuario': 'Harold Viajero',
              'uid': 'uidV',
            },
          ]),
        ),
        200,
      ),
    );
    final v = await ViajeRepository(api).disponiblesEnRuta('Bogota', 'Miami');
    expect(
      [v.single.viajeroUid, v.single.viajeroNombre],
      ['uidV', 'Harold Viajero'],
    );
    expect(
      requests.single.url.toString(),
      'https://api.test/api/viajes/disponibles?ciudadOrigen=Bogota&ciudadDestino=Miami',
    );
    expect(requests.single.headers['Authorization'], isNull);
    await ViajeRepository(api).validarVuelo('AV10', DateTime(2026, 12, 1));
    expect(requests.last.headers['Authorization'], isNull);
  });

  test('emparejar-viajes: viajes sugeridos con afinidad (28-oct)', () async {
    final api = clientWith(
      (req, _) => http.Response(
        jsonEncode([
          {
            'viajeId': 'v1',
            'uid': 'uidV',
            'afinidad': 0.868,
            'ciudadOrigen': 'Bogota',
            'ciudadDestino': 'Miami',
            'fechaViaje': '2026-12-01T00:00:00.000Z',
          },
          {'viajeId': 'v2', 'afinidad': 2},
        ]),
        200,
      ),
    );
    final s = await EncomiendaRepository(api).emparejar(
      ciudadOrigen: 'Bogota',
      ciudadDestino: 'Miami',
      fecha: DateTime(2026, 11, 30),
      valor: 20,
    );
    // La que no trae uid no sirve para escribirle: se descarta.
    expect(s.single.viajeroUid, 'uidV');
    expect(s.single.afinidad, 0.868);
    expect(jsonDecode(requests.single.body), {
      'ciudadOrigen': 'Bogota',
      'ciudadDestino': 'Miami',
      'fechaEncomienda': '2026-11-30',
      'valorEncomienda': 20,
    });
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
