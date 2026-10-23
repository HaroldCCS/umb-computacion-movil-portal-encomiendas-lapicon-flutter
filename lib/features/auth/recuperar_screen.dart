import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/theme/tema.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/aviso.dart';
import '../../core/widgets/boton.dart';
import '../../core/widgets/campo.dart';
import '../../core/widgets/pantalla.dart';
import '../../data/services/auth_service.dart';
import '../../providers.dart';

/// Recuperar contraseña. Por privacidad nunca dice si el correo existe.
class RecuperarScreen extends ConsumerStatefulWidget {
  const RecuperarScreen({super.key});

  @override
  ConsumerState<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends ConsumerState<RecuperarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _enviado = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).recuperarPassword(_email.text);
      if (mounted) setState(() => _enviado = true);
    } on AuthException catch (e) {
      if (!mounted) return;
      // "No existe" se muestra igual que el éxito.
      setState(() {
        if (e.code == 'user-not-found') {
          _enviado = true;
        } else {
          _error = e.message;
        }
      });
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (_enviado) {
      return Pantalla(
        titulo: 'Revisa tu correo',
        hijos: [
          Vacio(
            titulo: 'Enlace enviado',
            icono: Icons.mark_email_read_outlined,
            colorIcono: c.exito,
            fondoIcono: c.exitoSuave,
            texto:
                'Si ${_email.text.trim()} está registrado, te enviamos un '
                'enlace para crear una nueva contraseña.',
            accion: Boton(
              'Volver a iniciar sesión',
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      );
    }
    return Form(
      key: _formKey,
      child: Pantalla(
        titulo: 'Recuperar contraseña',
        subtitulo: 'Te enviaremos un enlace para crear una contraseña nueva.',
        hijos: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Campo(
                etiqueta: 'Correo',
                controlador: _email,
                pista: 'tu@correo.com',
                teclado: TextInputType.emailAddress,
                accionTeclado: TextInputAction.done,
                autofill: const [AutofillHints.email],
                validador: Validators.email,
                icono: Icons.mail_outline,
                alEnviar: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Aviso(_error!, tipo: TipoAviso.error),
                const SizedBox(height: 12),
              ],
              Boton(
                'Enviar enlace',
                textoCargando: 'Enviando…',
                cargando: _loading,
                onTap: _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
