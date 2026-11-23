import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //3.1 Importar el Timer
//5.1 Importar Firebase Auth y la pantalla de productos
import 'package:firebase_auth/firebase_auth.dart';
import 'products_screen.dart';
import 'signup_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //control para mostrar o ocultar contraseña
  bool _isObscure = true;

  //1.1 Máquina estados / o Cerebro de la animación
  StateMachineController? _controller; //seguridad nulo - Nullsafety // permitir que sea nulo para que no falle
  //StateMachineInput
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  //3.2 timer para detener el recorrido de la mirada
  Timer? _typingDebounce;

  //2.1 Creat variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  //4.1 - controllers para manipular lo que escribe el usuario
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  //4.2 Errores para mostrar en la UI (eliminados por regla OWASP: sin errores por campo en Login)
  //5.9 Error de credenciales: solo se muestra como texto rojo global, sin marcar campos
  String? authError;

  //5.2 Variable para mostrar el CircularProgressIndicador mientras carga
  bool _isLoading = false;

  // 4.3 Validadores (en Login solo verificamos que no estén vacíos según OWASP)

  //4.4 Dar acción al botón
  //5.3 Convertir _onLogin en asíncrono (Future<void> ... async)
  Future<void> _onLogin() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    setState(() {
      authError = null;
    });

    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    // Validar únicamente que los campos no estén vacíos (OWASP)
    if (email.isEmpty || pass.isEmpty) {
      setState(() {
        authError = 'Credenciales inválidas. Verifica tu correo y contraseña.';
      });
      _trigFail?.fire();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 1) Login en Firebase (correo + contraseña)
    try {
      await Future.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        authError = 'Credenciales inválidas. Verifica tu correo y contraseña.';
      });
      _trigFail?.fire();
      return;
    }

    // 2) Login en el backend del restaurante con las credenciales configuradas
    try {
      await ApiClient.loginWithEnvCredentials();
    } catch (e) {
      debugPrint('Error en login de Spring Boot: $e');
      if (!mounted) return;
      await FirebaseAuth.instance.signOut();
      setState(() {
        _isLoading = false;
        authError = 'Credenciales inválidas. Verifica tu correo y contraseña.';
      });
      _trigFail?.fire();
      return;
    }

    // 3) Todo bien: éxito del osito y navegación a Productos
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    _trigSuccess?.fire();
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProductsScreen()),
    );
  }

  //----
  //2.2 crear los oyentes (listeners)
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp?.change(false);
          //3.3 Mirada neutral
          _numLook?.value = 50.0;
        }
      }
    });
    _passwordFocus.addListener(() {
      //Manos arriba en password
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }
  //error: > BottomOverFlowed = desbordamiento de

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size; //obtiene el tamaño de la pantalla

    return Scaffold( // nos ayuda a cuidar - safe area / rap significa envolver
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: screenSize.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear-animation.riv',
                    stateMachines: ['Login Machine'],
                    //1.2 Vincular la animación
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );
                      //1.3 Verificar que inició bien
                      if (_controller == null) return;
                      //Agregar el controlador al escenario
                      artboard.addController(_controller!);
                      //1.4 Vincular las variabnles
                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),
                //para separar elementos
                SizedBox(height: 10),
                //email
                TextField(
                  //4.8 Vinvular el controller
                  controller: emailCtrl,
                  //2.3 Asignar el focus al textfield
                  focusNode: _emailFocus,
                  //1.5 Vincular a campo de texto
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      //No tapes los ojos al ver el email
                      //_isHandsUp!.change(false);
                    }
                    //Si isCheking es null
                    if (_isChecking == null) return;
                    //Activa el modo chismoso
                    _isChecking!.change(true);
                    //3.4 Implementar recorrido de mirada
                    //Ajuste de límites del 0 al 100
                    //80 medidad de calibración
                    final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                    _numLook?.value = look;
                    //3.5 Debounce: si vuelve a teclear, reinicia el contador
                    _typingDebounce?.cancel();
                    //Crear nuevo timer
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      //si se cierra la pantalla, termina la ejecución
                      if (!mounted) return;
                      //Mirada nuetra / digamos que pasan los 3 segundos
                      _isChecking?.change(false);
                    }); //(duracion, callback)
                  },
                  decoration: InputDecoration(
                    //4.9 Sin errorText individual en Login (OWASP)
                    hintText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      //propiedas para redondear los bordes
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // contraseña
                TextField(
                  //4.8 Vinvular el controller
                  controller: passCtrl,
                  //2.3 Asignar el focus al textfield
                  focusNode: _passwordFocus,
                  //1.5 Vincular a campo de texto
                  onChanged: (value) {
                    if (_isChecking != null) {
                      //No actives el modo chismoso
                      //_isChecking!.change(false);
                    }
                    //Si handsup no es null
                    if (_isHandsUp == null) return;
                    //Tapa los ojos
                    _isHandsUp!.change(true);
                  },
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    //4.9 Sin errorText individual en Login (OWASP)
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        //Refrescar el icono
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    border: OutlineInputBorder(
                      //propiedas para redondear los bordes
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                //5.10 Mensaje de credenciales incorrectas (solo texto, sin marcar la casilla)
                if (authError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        authError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: screenSize.width,
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 10),
                MaterialButton(
                  minWidth: screenSize.width,
                  height: 50,
                  color: const Color.fromARGB(255, 70, 255, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _isLoading ? null : _onLogin,
                  //5.9 Mostrar CircularProgressIndicador si está cargando, o el texto Login
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: screenSize.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?"),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_)=> const SignUpScreen()),
                          );
                        },
                        child: Text(
                          "Register",
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 45, 220),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    //2.4 Liberar memoria/recurso en los focusNode y TextEditingControllers
    _emailFocus.dispose();
    _passwordFocus.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    //3.5 Liberar timer
    _typingDebounce?.cancel();
    super.dispose();
  }
}