import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/campo.dart';
import '../../core/widgets/pantalla.dart';
import '../../providers.dart';

/// Crear cuenta: solo correo y contraseña; el resto se pide en el paso
/// siguiente (docs/07 §7.3-5).
class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authServiceProvider)
          .crearCuenta(_email.text, _password.text);
      // Con la sesión creada, el router lleva a "Completar perfil".
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Pantalla(
          titulo: 'Crear cuenta',
          subtitulo:
              'Solo te pedimos lo necesario. Tus datos de contacto los '
              'completas en el siguiente paso.',
          hijos: [
            // Un solo bloque: así todos los campos existen al validar.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Campo(
                  etiqueta: 'Correo',
                  controlador: _email,
                  pista: 'tu@correo.com',
                  teclado: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email],
                  validador: Validators.email,
                  icono: Icons.mail_outline,
                ),
                const SizedBox(height: 16),
                CampoContrasena(
                  controlador: _password,
                  minimo: 6,
                  nueva: true,
                  validador: Validators.password,
                ),
                const SizedBox(height: 8),
                BarraFortaleza(valor: _password.text),
                const SizedBox(height: 16),
                CampoContrasena(
                  etiqueta: 'Confirmar contraseña',
                  controlador: _confirm,
                  nueva: true,
                  validador: Validators.confirmarPassword(() => _password.text),
                  accionTeclado: TextInputAction.done,
                  alEnviar: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Aviso(_error!, tipo: TipoAviso.error),
                  const SizedBox(height: 12),
                ],
                Boton(
                  'Crear cuenta',
                  textoCargando: 'Creando cuenta…',
                  cargando: _loading,
                  onTap: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra de seguridad de la contraseña (validación positiva): tres tramos y
/// la palabra, nunca solo color.
class BarraFortaleza extends StatelessWidget {
  const BarraFortaleza({super.key, required this.valor});

  final String valor;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final nivel = Validators.fortalezaPassword(valor);
    if (nivel == 0) return const SizedBox.shrink();
    const etiquetas = ['', 'Débil', 'Media', 'Fuerte'];
    final colores = [c.separador, c.peligro, c.atencion, c.exito];
    final animar = !MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Seguridad de la contraseña: ${etiquetas[nivel]}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 1; i <= 3; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: animar
                    ? const Duration(milliseconds: 200)
                    : Duration.zero,
                height: 6,
                decoration: BoxDecoration(
                  color: i <= nivel ? colores[nivel] : c.superficie2,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const SizedBox(width: 8),
          Text(
            etiquetas[nivel],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colores[nivel],
            ),
          ),
        ],
      ),
    );
  }
}
