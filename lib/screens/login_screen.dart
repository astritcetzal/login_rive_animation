import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
class LoginScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //control para mostrar o ocultar contraseña
bool _isObscure = true;
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size; //obtiene el tamaño de la pantalla
  
    return Scaffold( // nos ayuda a cuidar - safe area / rap rignifia envorlver
      body:SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: screenSize.width,
                height: 200,
                child: RiveAnimation.asset('assets/login-bear-animation.riv')),
              //para separar elementos
              SizedBox(height:10),
              //email
              TextField(
                decoration: InputDecoration(
                  hintText:"Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    //propiedas para redondear los bordes
                    borderRadius: BorderRadius.circular(12)
                  )
                ),
              ),
              const  SizedBox(height: 10),
              // contraseña
              TextField(
                obscureText: _isObscure,
                decoration: InputDecoration(
                  hintText:"Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: (){
                    //Refrescar el icono
                    setState((){
                      _isObscure = !_isObscure;
                    });
                  }, icon: Icon(
                    _isObscure ? Icons.visibility : Icons.visibility_off
                  )),
                  border: OutlineInputBorder(
                    //propiedas para redondear los bordes
                    borderRadius: BorderRadius.circular(12)
                  )
                ),
              ),

            ],
          ),
        ))
    );
  }
}