// Genera lib/firebase_options.dart a partir del google-services.json del curso.
//
// Uso: dart run tool/generate_firebase_options.dart <ruta-google-services.json> [package_name]
//
// Así no hace falta la CLI de FlutterFire ni acceso de administrador al proyecto
// Firebase `lapticon-eba31`: tomamos los datos públicos del cliente Android.
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final path = args.isNotEmpty
      ? args[0]
      : '../referencias/google-services.json';
  final packageName = args.length > 1 ? args[1] : 'com.lapticon.app';

  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('No se encontró $path');
    exit(1);
  }

  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final project = json['project_info'] as Map<String, dynamic>;
  final clients = (json['client'] as List).cast<Map<String, dynamic>>();

  final client = clients.firstWhere(
    (c) =>
        (c['client_info'] as Map)['android_client_info']['package_name'] ==
        packageName,
    orElse: () {
      stderr.writeln(
        'El google-services.json no tiene un cliente para $packageName. '
        'Paquetes disponibles: ${clients.map((c) => (c['client_info'] as Map)['android_client_info']['package_name']).join(', ')}',
      );
      exit(1);
    },
  );

  final apiKey = ((client['api_key'] as List).first as Map)['current_key'];
  final appId = (client['client_info'] as Map)['mobilesdk_app_id'];

  final output =
      '''
// ARCHIVO GENERADO por tool/generate_firebase_options.dart. No editar a mano.
// No se versiona (ver .gitignore).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Lapticon no está configurado para web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Lapticon solo está configurado para Android por ahora.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '$apiKey',
    appId: '$appId',
    messagingSenderId: '${project['project_number']}',
    projectId: '${project['project_id']}',
    storageBucket: '${project['storage_bucket']}',
  );
}
''';

  final out = File('lib/firebase_options.dart');
  out.writeAsStringSync(output);
  stdout.writeln(
    'OK: ${out.path} generado para $packageName (${project['project_id']}).',
  );
}
