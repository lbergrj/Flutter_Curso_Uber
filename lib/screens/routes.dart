import 'package:flutter/material.dart';
import 'package:uber/screens/screen_corrida.dart';
import '../screens/screen_motorista.dart';
import '../screens/screen_passageiro.dart';
import '../screens/screen_login.dart';
import '../screens/screen_cadastro.dart';
import '../screens/screen_home.dart';

class Routes{

  static Route<dynamic> createRoutes(RouteSettings settings){

    final args = settings.arguments;

    switch (settings.name){
      case "/" :
        return MaterialPageRoute(
            builder: (_) => ScreenLogin()
        );

      case "/cadastro" :
        return MaterialPageRoute(
            builder: (_) => ScreenCadastro()
        );

      case "/passageiro" :
        return MaterialPageRoute(
            builder: (_) => ScreenPassageiro()
        );

      case "/motorista" :
        return MaterialPageRoute(
            builder: (_) => ScreenMotorista()
        );
      case "/corrida" :
        return MaterialPageRoute(
            builder: (_) => ScreenCorrida(args)
        );

      default: _erroRota();
    }

  }

  static Route<dynamic> _erroRota(){
    return MaterialPageRoute(
        builder: (_){
          return Scaffold(
            appBar: AppBar(
              title: Text("Tela não encontrada"),
            ),
            body : Center(
              child: Text("Tela não encontrada",
                style: TextStyle(
                  fontSize: 20
                ),
              ),
            ),
          );
        },
    );
  }

}