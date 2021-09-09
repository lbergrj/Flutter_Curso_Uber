import 'package:firebase_auth/firebase_auth.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:uber/model/usuario.dart';

class UsuarioFirebase{

  static Future<User> getUsuarioAtual()async{
    FirebaseAuth auth = FirebaseAuth.instance;
    return await auth.currentUser;

  }

  static Future<Usuario> getDadosUsuarioAtual()async{
    User user = await getUsuarioAtual();
    String idUsuario = user.uid;
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot snapshot = await db.collection("usuarios")
      .doc(idUsuario)
      .get();
    Map<String, dynamic> map = snapshot.data();

   Usuario usuario = Usuario.fromMap(map);
   usuario.idUsuario =  idUsuario;
   return usuario;

  }

  static atualizarDadosLocalizacaoMotorista(String idRequisicao, double lat, double long)async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    Usuario motorista = await getDadosUsuarioAtual();
    motorista.latitude = lat;
    motorista.longitude = long;
    db.collection("requisicoes")
        .doc(idRequisicao)
        .update({
      "motorista": motorista.toMapWithId(),
    });
  }

    static atualizarDadosLocalizacaoPassageiro(String idRequisicao, double lat, double long)async{
      FirebaseFirestore db = FirebaseFirestore.instance;
      Usuario passageiro = await getDadosUsuarioAtual();
      passageiro.latitude = lat;
      passageiro.longitude = long;
      db.collection("requisicoes")
          .doc(idRequisicao)
          .update({
        "passageiro" : passageiro.toMapWithId(),
      });



  }

}