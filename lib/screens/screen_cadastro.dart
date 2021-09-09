import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/usuario.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScreenCadastro extends StatefulWidget {
  @override
  _ScreenCadastroState createState() => _ScreenCadastroState();
}

class _ScreenCadastroState extends State<ScreenCadastro> {
  String _mensagem = "";
  TextEditingController _controllerEmail = TextEditingController();
  TextEditingController _controllerSenha = TextEditingController();
  TextEditingController _controllerNome = TextEditingController();
  bool _tipoUsuario = false;

  _showMessagem (String mensagem) {
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

  }

  _cadastrarUsuario(Usuario usuario)async {

    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore db =   FirebaseFirestore.instance;
   final User user = await  auth.createUserWithEmailAndPassword(
        email: usuario.email,
        password: usuario.senha,
    ).then((firebaseUser){
      db.collection("usuarios")
       .doc(firebaseUser.user.uid)
       .set(usuario.toMap());
      switch (usuario.tipoUsuario){
        case "Motorista" : Navigator.pushNamedAndRemoveUntil(context, "/motorista",(_) => false);
        break;
        case "Passageiro" : Navigator.pushNamedAndRemoveUntil(context, "/passageiro",(_) => false);
        break;
      }
    }).catchError((onError){
     _showMessagem("Não foi possível Logar");
   });
  }

  _validation(){
    String nome =  _controllerNome.text;
    String email =  _controllerEmail.text;
    String senha =  _controllerSenha.text;

    if(nome.isNotEmpty){
      if(email.length > 6 &&  email.contains(".") && email.contains("@")){
        if(senha.length > 3){
        //Cadastrar usuario
          Usuario usuario = Usuario();
          usuario.nome = nome;
          usuario.email = email;
          usuario.senha = senha;
          usuario.tipoUsuario = usuario.getTipoUsuario(_tipoUsuario);
          _cadastrarUsuario(usuario);
        }
        else{
          _showMessagem("Informe uma com ao menos 4 caractéres");
        }
      }
      else{
        _showMessagem("Informe um email válido");
      }
    }
    else{
      _showMessagem("Informe o seu nome");
    }
  }

  _iniciar() async{
    Firebase.initializeApp();
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _iniciar();
  }

  @override
  Widget build(BuildContext context) {    return Scaffold(
      appBar: AppBar(
      // backgroundColor: Color(0xff1ebbd8),
        title: Text ("Cadastro"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: TextField(
                    controller: _controllerNome,
                    keyboardType: TextInputType.text,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "Nome",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                TextField(
                  controller: _controllerEmail,
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
                    padding:EdgeInsets.only(top:20, bottom: 20),
                  child: Row(
                    children: [
                      Text("Passageiro",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            //color: Colors.white,
                          ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 5, right: 5),
                        child: Switch(
                          value: _tipoUsuario,
                          onChanged: (bool valor){
                            setState(() {
                              _tipoUsuario = valor;
                            });
                          },
                        ),
                      ),
                      Text("Motorista",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          //color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: RaisedButton(
                      color: Color(0xff1ebbd8),
                      child: Text(
                        "Cadastar",
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
                        }
                      ),
                ),

                Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 10),
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
          ),
        ),
      ),
    );
  }
}
