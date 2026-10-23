import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';
import '../../core/router/routes.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/campo.dart';
import '../../core/widgets/entrada.dart';
import '../../core/widgets/route_ticket.dart';
import '../../providers.dart';

/// Inicio de sesión (docs/07 §7.6): marca, propuesta de valor, pase
/// decorativo y el formulario. El error se muestra junto al botón.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
          .iniciarSesion(_email.text, _password.text);
      // El router redirige solo cuando cambia la sesión.
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.fondo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Medidas.margen,
              24,
              Medidas.margen,
              24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Medidas.anchoMaximo),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Entrada(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: BrandMark(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Entrada(
                        indice: 1,
                        child: Text(
                          'Tu paquete viaja con alguien que ya va para allá.',
                          style: context.t.headlineLarge,
                        ),
                      ),
                      const SizedBox(height: Medidas.bloque),
                      const Entrada(
                        indice: 2,
                        child: ExcludeSemantics(
                          child: RouteTicket(
                            origen: 'Bogotá',
                            destino: 'Miami',
                            compact: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
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
                        validador: Validators.password,
                        accionTeclado: TextInputAction.done,
                        alEnviar: (_) => _submit(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading
                              ? null
                              : () => context.push(Routes.recuperar),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 4),
                        Aviso(_error!, tipo: TipoAviso.error),
                        const SizedBox(height: 12),
                      ] else
                        const SizedBox(height: 8),
                      Boton(
                        'Iniciar sesión',
                        textoCargando: 'Entrando…',
                        cargando: _loading,
                        onTap: _submit,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '¿No tienes cuenta?',
                            style: TextStyle(fontSize: 15, color: c.texto2),
                          ),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => context.push(Routes.registro),
                            child: const Text('Crear cuenta'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
