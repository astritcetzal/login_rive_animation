import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //3.1 Importar el Timer
//5.1 Importar Firebase Auth y la pantalla de productos
import 'package:firebase_auth/firebase_auth.dart';
import 'products_screen.dart';

class LoginScreen extends StatefulWidget {
  const new({super.key});

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

  //4.2 Errores para mostrar en la UI
  String? emailError;
  String? passError;

  //5.2 Variable para mostrar el CircularProgressIndicador mientras carga
  bool _isLoading = false;

  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }
  
    //4.4 Dar acción al botón
  //5.3 Convertir _onLogin en asíncrono (Future<void> ... async)
  Future<void> _onLogin() async {
    //4.5 De lo que escribió el usuario, quitar espacios en blanco
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    //4.6 Evaluar los errores
    final eError = isValidEmail(email) ? null : "Invalid email";
    final pError = isValidPassword(pass) ? null : "Invalid password";

    //4.7 Avisar que hubo cambios
    setState(() {
      emailError = eError;
      passError = pError;
    });

    //4.8 Cerrar el teclado y bajar las manos
    FocusScope.of(context).unfocus(); //Quita el foco
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //4.9 Si algún campo tiene formato inválido, activar fallo y detener aquí
    if (eError != null || pError != null) {
      _trigFail?.fire();
      return;
    }

    //5.4 Activar el CircularProgressIndicator
    setState(() {
      _isLoading = true;
    });

    try {
      //5.5 Autenticar usuario en Firebase (esperamos un par de segundos para ver el loading)
      await Future.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      //5.6 Apagar loading, disparar éxito del osito y esperar a que termine su animación
      setState(() {
        _isLoading = false;
      });
      _trigSuccess?.fire();
      await Future.delayed(const Duration(seconds: 2));

      //5.7 Navegar a la pantalla de productos de Spring Boot
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } catch (e) {
      //5.8 Si Firebase rechaza el login, apagar loading y mostrar al osito triste
      setState(() {
        _isLoading = false;
        passError = "Invalid Firebase credentials";
      });
      _trigFail?.fire();
    }
  }
  //2.2 crear los oyentes (listeners)
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener((){
      if(_emailFocus.hasFocus){
        if(_isHandsUp != null){
          _isHandsUp?.change(false);
          //3.3 Mirada neutral
          _numLook?.value = 50.0;
        }
      }
    });
    _passwordFocus.addListener((){
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
                  child: RiveAnimation.asset('assets/login-bear-animation.riv',
                    stateMachines:['Login Machine'],
                    //1.2 Vincular la animación
                    onInit:(artboard){
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );
                      //1.3 Verificar que inició bien
                      if(_controller == null) return;
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
                SizedBox(height:10),
                //email
                TextField(
                  //4.8 Vinvular el controller
                  controller: emailCtrl,
                  //2.3 Asignar el focus al textfield
                  focusNode: _emailFocus,
                  //1.5 Vincular a campo de texto
                  onChanged: (value){
                    if(_isHandsUp != null){
                      //No tapes los ojos al ver el email
                      //_isHandsUp!.change(false);
                    }
                    //Si isCheking es null
                    if(_isChecking == null) return;
                    //Activa el modo chismoso
                    _isChecking!.change(true);
                    //3.4 Implementar recorrido de mirada
                    //Ajuste de límites del 0 al 100
                    //80 medidad de calibración
                    final look =  (value.length / 80.0 * 100.0).clamp(0.0,100.0);
                    _numLook?.value = look;
                    //3.5 Debounce: si vuelve a teclear, reinicia el contador
                    _typingDebounce?.cancel();
                    //Crear nuevo timer
                    _typingDebounce =  Timer(const Duration(seconds: 3), (){
                      //si se cierra la pantalla, termina la ejecución
                      if(!mounted) return;
                      //Mirada nuetra / digamos que pasan los 3 segundos
                      _isChecking?.change(false);
                    }); //(duracion, callback)
                  },
                  decoration: InputDecoration(
                    //4.9   Mostrar el error
                    errorText: emailError,
                    hintText:"Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      //propiedas para redondear los bordes
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const  SizedBox(height: 10),
                // contraseña
                TextField(
                  //4.8 Vinvular el controller
                  controller: passCtrl,
                  //2.3 Asignar el focus al textfield
                  focusNode: _passwordFocus,
                  //1.5 Vincular a campo de texto
                  onChanged: (value){
                    if(_isChecking != null){
                      //No actives el modo chismoso
                      //_isChecking!.change(false);
                    }
                    //Si handsup no es null
                    if(_isHandsUp == null) return;
                    //Tapa los ojos
                    _isHandsUp!.change(true);
                  },
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    //4.9 Mostrar el error
                    errorText: passError,
                    hintText:"Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: (){
                        //Refrescar el icono
                        setState((){
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
                const SizedBox(height:10),
                SizedBox(
                  width: screenSize.width,
                  child: const Text("Forgot password?", 
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height:10),
                MaterialButton(
                  minWidth: screenSize.width,
                  height: 50,
                  color: Colors.amberAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _onLogin,
                  //5.9 Mostrar CircularProgressIndicador si está cargando, o el texto Login
                  child: _isLoading
                    ?const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                    "Login",
                    style: TextStyle(color:Colors.white, fontSize: 18),
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
                        onPressed: (){}, 
                        child: Text("Register",
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 139, 45),
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
    //2.4 Liberar memoria/recurso en los focusNode
    _emailFocus.dispose();
    _passwordFocus.dispose();
    //3.5 Liberar timer
    _typingDebounce?.cancel();
    super.dispose();
  }
}