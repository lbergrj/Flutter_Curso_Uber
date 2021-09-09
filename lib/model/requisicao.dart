import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'destino.dart';
import 'usuario.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Requisicao{

  String _id;
  String _status;
  Usuario _passageiro;
  Usuario _motorista;
  Destino _destino;
  LatLng _origem;



  Requisicao(){
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference ref = db.collection("requisicoes").doc();
    this.id = ref.id;
  }

  Requisicao.fromMap(Map<String,dynamic> map){
    this.id = map["id"];
    this.status =  map["status"];
    Map<String, dynamic> mapPassageiro = map["passageiro"];
    Map<String, dynamic> mapMotorista = map["motorista"];
    Map<String, dynamic> mapdestino = map["destino"];
    this.passageiro = Usuario.fromMapDB(mapPassageiro);
    this.destino = Destino.fromMapDB( mapdestino);
    if(map["origem"] != null){
      double lat = map["origem"]["latitude"];
      double lon = map["origem"]["longitude"];
      this._origem = LatLng(lat,lon);
    }
    else this._origem = null;


    if( mapMotorista   != null ){
      this.motorista =  Usuario.fromMapDB(mapMotorista);
    }
    else{
      this.motorista = null;
    }



  }

  LatLng get origem => _origem;

  set origem(LatLng value) {
    _origem = value;
  }


  String get id => _id;

  set id(String value) {
    _id = value;
  }



  String get status => _status;

  set status(String value) {
    _status = value;
  }

  Usuario get passageiro => _passageiro;

  set passageiro(Usuario value) {
    _passageiro = value;
  }

  Usuario get motorista => _motorista;

  set motorista(Usuario value) {
    _motorista = value;
  }

  Destino get destino => _destino;

  set destino(Destino value) {
    _destino = value;
  }
  Map<String, dynamic> toMap(){


    Map<String, dynamic> dadosRequisicao = {
      "id" : this.id,
      "status" : this.status,
      "passageiro" :  this._passageiro.toMapWithId(),
      "motorista" : null,
      "destino" : this.destino.toMap(),
      "origem" : null,
    };

    return dadosRequisicao;
  }
}