import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:uber/model/usuario.dart';
import 'package:uber/util/status_requisicao.dart';
import 'package:uber/util/usuario_firebase.dart';

class ScreenMotorista extends StatefulWidget {
  @override
  _ScreenMotoristaState createState() => _ScreenMotoristaState();
}

class _ScreenMotoristaState extends State<ScreenMotorista> {

  List<String>_menuItens = ["Configurações", "Deslogar"];
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;
  final _coontroller = StreamController<QuerySnapshot>.broadcast();
   bool _flagWait = true;
  StreamSubscription<QuerySnapshot> _requisicoesStream;

  _chosedItem (String chosed){
    switch(chosed){
      case "Deslogar" :
        _logOff();
        break;

      case "Configurações" :
        break;
    }
  }

  StreamController<QuerySnapshot> _addListenserRequisicoes(){
    final stream  = db.collection("requisicoes")
     .where("status", isEqualTo:  StatusRequisicao.AGUARDANDO)
      .snapshots();
    _requisicoesStream =  stream.listen((dados){
    _coontroller.add(dados);
    });
  }

  _recuperarRequisicaoAtiva()async{
   Usuario motorista = await UsuarioFirebase.getDadosUsuarioAtual();
   DocumentSnapshot documentSnapshot = await db.collection("requisicao_ativa_motorista")
   .doc(motorista.idUsuario)
   .get();
   var dadosRequisicao = await documentSnapshot.data();
   if(dadosRequisicao == null){
      await _addListenserRequisicoes();
      setState(() {
        _flagWait = false;
      });

   }else{
    String idRequisicao = dadosRequisicao["id_requisicao"];
     Navigator.pushReplacementNamed(context,
         "/corrida",
         arguments:  idRequisicao);
   }


  }


  _logOff() async{
    await auth.signOut();

    Navigator.pushReplacementNamed(context, "/");
  }

  _iniciar() async{
    Firebase.initializeApp();
    await _recuperarRequisicaoAtiva();

  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _iniciar();
  }
  Widget showLoading (){
    return Center (
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text("Carregando Requisições"),
          ),
        ],
      ),
    );
  }

  Widget showMessage (String mensagem){
    return Center (
      child:  Text(mensagem,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Uber - Motorista"),
        actions: [
          PopupMenuButton<String>(
            onSelected: _chosedItem,
            itemBuilder: (context){
              return _menuItens.map((String item) {
                return PopupMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList();
            },
          ),
        ],
      ),

      body: _flagWait == true
      ?  showLoading ()
      : Container(
        child:StreamBuilder<QuerySnapshot>(
          stream: _coontroller.stream,
          builder: (context, snapshot){
            switch(snapshot.connectionState){
              case ConnectionState.none:


              case ConnectionState.waiting:
                  showLoading ();
                break;
              case ConnectionState.active:

              case ConnectionState.done:
                if(snapshot.hasError){

                  return showMessage("Erro ao carregar os dados");
                }
                else{
                  QuerySnapshot querySnapshot = snapshot.data;
                  if( querySnapshot.docs.length ==0){
                    return  showMessage("Não há requisições :(");
                  }
                  else{
                    return ListView.separated(
                      itemCount: querySnapshot.docs.length,
                      separatorBuilder: (context,indice) => Divider (
                        height: 2,
                        color: Colors.grey,
                      ),
                      itemBuilder: (context, index){
                        List<DocumentSnapshot> requisicoes = querySnapshot.docs.toList();
                        DocumentSnapshot item = requisicoes[index];

                        String idRequisicao = item["id"];
                        String nomePassageiro = item["passageiro"]["nome"];
                        String rua = item["destino"]["rua"];
                        String numero = item["destino"]["numero"];
                        return ListTile(
                          title: Text(nomePassageiro),
                          subtitle: Text("Destino:  $rua , $numero"),
                          onTap: (){
                            Navigator.pushNamed(context,
                                "/corrida",
                            arguments:  idRequisicao);
                          },
                        );
                      },



                    );
                  }
                }
                break;

            }

          },
        ),

      ),
    );
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    if(_requisicoesStream != null) {
      _requisicoesStream.cancel();
      //_coontroller.close();
    }

  }
}
