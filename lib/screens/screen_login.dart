import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uber/model/usuario.dart';
import 'package:uber/screens/screen_cadastro.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScreenLogin extends StatefulWidget {
  @override
  _ScreenLoginState createState() => _ScreenLoginState();
}

class _ScreenLoginState extends State<ScreenLogin> {
  TextEditingController _controllerEmail = TextEditingController(text: "lberg@gmail.com");
  TextEditingController _controllerSenha = TextEditingController(text: "123456");
  FirebaseFirestore db ;
  String _mensagem = "";
  bool _loadding  = false;
  bool _complete = false;

  _showMessagem (String mensagem) async{

    setState(() {
      _mensagem = mensagem;
    });
    Timer timer = Timer (
        Duration (seconds: 3),
            (){
          setState(() {
            _mensagem = "";
          });
        }
    );
    //timer.cancel();
  }

  _redirectScreen(String idUsuario )async {
    DocumentSnapshot snapshot = await db.collection("usuarios")
        .doc(idUsuario)
        .get();
    Map<String,dynamic>  dados = snapshot.data();
    String tipoUsuario = dados["tipoUsuario"];
    setState(() {
      _loadding = false;
    });

    switch(tipoUsuario){
      case "Motorista" :
        Navigator.pushReplacementNamed(context, "/motorista");
        break;

      case "Passageiro" :
        Navigator.pushReplacementNamed(context, "/passageiro");
        break;
    }

  }


  _login (Usuario usuario) async{
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    setState(() {
      _loadding = true;
    });
    FirebaseAuth auth = FirebaseAuth.instance;
    auth.signInWithEmailAndPassword(
        email: usuario.email, 
        password: usuario.senha
    ).then((user){
      _redirectScreen(user.user.uid);
    }).catchError((onError){
      _showMessagem(onError.toString());
    });
  }

  _validation(){
    String email =  _controllerEmail.text;
    String senha =  _controllerSenha.text;
      if(email.length > 6 &&  email.contains(".") && email.contains("@")){
        if(senha.length > 3){
          Usuario usuario = Usuario();
          usuario.email = email;
          usuario.senha = senha;
          _login(usuario);
        }
        else{
          _showMessagem("Informe uma com ao menos 4 caractéres");
        }
      }
      else{
        _showMessagem("Informe um email válido");
      }
  }

  _checkLogedUser()async{
    FirebaseAuth auth = FirebaseAuth.instance;
    User userLogged = await auth.currentUser;
    if(userLogged != null){
      String idUsuario =  userLogged.uid;
      _redirectScreen(idUsuario);
    }
    else{
      setState(() {
        _complete = true;
      });
    }

  }

  _iniciar() async{
    await  Firebase.initializeApp();
     db =  await FirebaseFirestore.instance;
     _checkLogedUser();
  }
  @override
  void initState() {
    // TODO: implement initState
    _iniciar();
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/fundo.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child:  _complete
              ?SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: Image.asset(
                    "assets/images/logo.png",
                    width: 200,
                    height: 150,
                  ),
                ),
                TextField(
                  controller: _controllerEmail,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    hintText: "E-mail",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: TextField(
                    controller: _controllerSenha,
                    obscureText: true,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "Senha",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 15),
                  child: RaisedButton(
                      color: Color(0xff1ebbd8),
                      child: Text(
                        "Entrar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      shape: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      onPressed: () {
                        _validation();
                      }),
                ),
                Center(
                  child: GestureDetector(
                    child: Text(
                      "Cadastrar nova conta",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, "/cadastro");
                    },
                  ),
                ),
                _loadding
                    ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.white,
                    ),
                  ),
                )
                    : Container(),
                Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Center(
                    child: Text(
                      _mensagem,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          )
          : CircularProgressIndicator(
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
