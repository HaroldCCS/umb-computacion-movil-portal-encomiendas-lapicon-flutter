import 'json_utils.dart';
import 'rol.dart';

/// Perfil del usuario en el backend (`/api/users`).
class Usuario {
  const Usuario({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.nacionalidad,
    this.email,
    this.fechaNacimiento,
    this.rol,
    this.creadoEn,
  });

  final String uid;
  final String nombre;
  final String apellido;
  final String telefono;
  final String nacionalidad;
  final String? email;

  /// Opcional (Swagger oficial), `YYYY-MM-DD`: se guarda como texto para no
  /// correr el día por zona horaria.
  final String? fechaNacimiento;
  final Rol? rol;
  final DateTime? creadoEn;

  /// El backend puede responder el perfil directo o envuelto.
  factory Usuario.fromJson(dynamic json, {String? uidFallback}) {
    final map =
        unwrapObject(json, const ['usuario', 'user', 'perfil', 'data']) ??
        const <String, dynamic>{};
    final uid = readString(map, const ['uid', 'firebaseUid', 'userId', '_id']);
    final email = readString(map, const ['email', 'correo']);
    final nacimiento = readString(map, const ['fechaNacimiento']);
    return Usuario(
      uid: uid.isNotEmpty ? uid : (uidFallback ?? ''),
      nombre: readString(map, const ['nombre', 'name', 'firstName']),
      apellido: readString(map, const ['apellido', 'lastName']),
      telefono: readString(map, const ['telefono', 'phone']),
      nacionalidad: readString(map, const ['nacionalidad', 'pais']),
      email: email.isEmpty ? null : email,
      fechaNacimiento: RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(nacimiento)
          ? nacimiento.substring(0, 10)
          : null,
      rol: Rol.tryParse(map['rol'] ?? map['role']),
      creadoEn: readDate(map, const ['createdAt', 'fechaRegistro']),
    );
  }

  /// Cuerpo que espera `POST /api/users/register` y `PUT /api/users/:uid`.
  /// Nunca lleva `uid` ni `email`: el `PUT` responde 400 si se intentan
  /// cambiar (Swagger oficial).
  Map<String, dynamic> toRegisterJson() => {
    'nombre': nombre,
    'apellido': apellido,
    'telefono': telefono,
    'nacionalidad': nacionalidad,
    if (fechaNacimiento != null) 'fechaNacimiento': fechaNacimiento,
  };

  /// El perfil está completo cuando tiene los datos que pide el registro.
  bool get completo =>
      nombre.isNotEmpty && apellido.isNotEmpty && telefono.isNotEmpty;

  String get nombreCompleto => '$nombre $apellido'.trim();

  String get iniciales {
    final partes = [nombre, apellido].where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    return partes.map((p) => p.primeraLetra.toUpperCase()).join();
  }

  Usuario copyWith({
    String? nombre,
    String? apellido,
    String? telefono,
    String? nacionalidad,
    String? email,
    String? fechaNacimiento,
    Rol? rol,
  }) => Usuario(
    uid: uid,
    nombre: nombre ?? this.nombre,
    apellido: apellido ?? this.apellido,
    telefono: telefono ?? this.telefono,
    nacionalidad: nacionalidad ?? this.nacionalidad,
    email: email ?? this.email,
    fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
    rol: rol ?? this.rol,
    creadoEn: creadoEn,
  );
}

extension on String {
  /// Primera letra (sin depender del paquete `characters`).
  String get primeraLetra => isEmpty ? '' : String.fromCharCode(runes.first);
}
