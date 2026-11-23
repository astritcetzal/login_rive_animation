import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controladores privados para encapsular el estado de los campos
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Visibilidad de contraseñas
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Errores específicos por campo (permitido y requerido en Registro por OWASP)
  String? _emailError;
  String? _passError;
  String? _confirmPassError;

  // --- REGLAS DE VALIDACIÓN (Métodos puros con responsabilidad única) ---

  bool _isValidInstitutionalEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@tecdesoftware\.edu\.mx$');
    return regex.hasMatch(email.trim());
  }

  bool get _hasMinLength => _passCtrl.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passCtrl.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_passCtrl.text);
  bool get _hasDigit => RegExp(r'\d').hasMatch(_passCtrl.text);
  bool get _hasSpecialChar => RegExp(r'[^A-Za-z0-9]').hasMatch(_passCtrl.text);

  bool get _isPasswordStrong =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasDigit &&
      _hasSpecialChar;

  // --- FLUJO DE REGISTRO EN FIREBASE ---

  Future<void> _onRegister() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    // 1. Validar cada campo individualmente
    String? emailErr;
    if (email.isEmpty) {
      emailErr = 'Ingresa tu correo institucional.';
    } else if (!_isValidInstitutionalEmail(email)) {
      emailErr = 'Debe terminar en @tecdesoftware.edu.mx';
    }

    String? passErr;
    if (pass.isEmpty) {
      passErr = 'Ingresa una contraseña.';
    } else if (!_isPasswordStrong) {
      passErr = 'La contraseña no cumple todas las reglas de seguridad.';
    }

    String? confirmErr;
    if (confirmPass.isEmpty) {
      confirmErr = 'Confirma tu contraseña.';
    } else if (pass != confirmPass) {
      confirmErr = 'Las contraseñas no coinciden.';
    }

    setState(() {
      _emailError = emailErr;
      _passError = passErr;
      _confirmPassError = confirmErr;
    });

    // Si algún campo tiene error, detenemos el envío
    if (emailErr != null || passErr != null || confirmErr != null) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    // 2. Crear cuenta en Firebase Authentication
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // Cerramos la sesión automática de Firebase para que el usuario inicie
      // sesión formalmente desde el Login (y pase por el osito + JWT del backend)
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada con éxito. Ahora inicia sesión.'),
          backgroundColor: Colors.green,
        ),
      );

      // Regresar a LoginScreen usando pop (porque entramos con push)
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'email-already-in-use') {
          _emailError = 'Este correo institucional ya está registrado.';
        } else if (e.code == 'weak-password') {
          _passError = 'Firebase rechazó la contraseña por ser muy débil.';
        } else {
          _emailError = 'Error al registrar: ${e.message ?? e.code}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailError = 'Ocurrió un error inesperado al conectar con Firebase.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registro Institucional',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Usa tu correo @tecdesoftware.edu.mx para acceder al menú.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 20),

              // Campo Correo Institucional
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo institucional',
                  hintText: 'usuario@tecdesoftware.edu.mx',
                  prefixIcon: const Icon(Icons.school_outlined),
                  errorText: _emailError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Campo Contraseña
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                onChanged: (_) => setState(() {}), // Actualiza checklist visual
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _passError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscurePass = !_obscurePass);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Reglas visibles en pantalla (Requisito de rúbrica)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'La contraseña debe incluir:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _RuleItem(label: 'Mínimo 8 caracteres', met: _hasMinLength),
                    _RuleItem(label: 'Al menos una mayúscula (A-Z)', met: _hasUppercase),
                    _RuleItem(label: 'Al menos una minúscula (a-z)', met: _hasLowercase),
                    _RuleItem(label: 'Al menos un número (0-9)', met: _hasDigit),
                    _RuleItem(label: 'Al menos un símbolo (!@#\$...)', met: _hasSpecialChar),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Campo Confirmar Contraseña
              TextField(
                controller: _confirmPassCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  errorText: _confirmPassError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Registrar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 139, 45),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _onRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Registrarme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}

// Widget auxiliar privado para dibujar cada regla de contraseña
class _RuleItem extends StatelessWidget {
  const _RuleItem({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? Colors.green.shade700 : Colors.grey.shade600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}