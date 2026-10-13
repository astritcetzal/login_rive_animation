import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
class LoginScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
            ],
          ),
        ))
    );
  }
}