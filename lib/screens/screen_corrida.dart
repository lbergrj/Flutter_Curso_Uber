import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uber/model/requisicao.dart';
import 'package:uber/model/usuario.dart';
import 'package:uber/util/UtilPosition.dart';
import 'package:uber/util/marcador.dart';
import 'package:uber/util/status_requisicao.dart';
import 'package:uber/util/usuario_firebase.dart';

class ScreenCorrida extends StatefulWidget {

String _idRequisicao;


  ScreenCorrida(this._idRequisicao);

  @override
  _ScreenCorridaState createState() => _ScreenCorridaState();
}

class _ScreenCorridaState extends State<ScreenCorrida> {
  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _cameraPosition;
  Position  _position;
  Set<Marker> _markers = {};
  FirebaseFirestore db = FirebaseFirestore.instance;
  Requisicao _requisicao;
  String _idRequisicao;
  Position _localMotorista;
  String _statusRequisicao = StatusRequisicao.AGUARDANDO;
  Marcador marcador ;
  StreamSubscription<DocumentSnapshot> _requisicaoStreamer;

  //Controles para exibição na Tela
  String _textButton = "Aceitar Corrida";
  Color _colorButton = Color(0xff1ebbd8);
  Function _functionButton;
  String _mensagemStaus = "";


  _onMapCreated(GoogleMapController controller){
    _controller.complete(controller);
  }

  _recoverLastPosition()async{
    Position position = await Geolocator().getLastKnownPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
      if(position != null){
        setState(() {
          _localMotorista = position;
        });

      }
    }




  _addListenerPosition(){
    var geolocator  = Geolocator();
    var locationOptions = LocationOptions(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10
    );
    geolocator.getPositionStream(locationOptions).listen((pos) {
      if(pos != null){
        if(_idRequisicao != null && _idRequisicao.isNotEmpty &&_statusRequisicao != StatusRequisicao.AGUARDANDO ){
                UsuarioFirebase.atualizarDadosLocalizacaoMotorista(
                _idRequisicao,
                pos.latitude,
                pos.longitude
            );
        }

        else {
          setState(() {
            _localMotorista = pos;
            print(pos);
          });
        }

      }

    });

  }

  CameraPosition _initialCameraPosition(){
    return CameraPosition(
        target: LatLng(_localMotorista.latitude, _localMotorista.longitude),
      zoom: 18
    );

  }

  _moveCamera (CameraPosition cameraPosition) async{
    GoogleMapController googleMapController  = await _controller.future;
    googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition)
    );
  }

  _moveCameraBounds (LatLngBounds latLngBounds) async{
    GoogleMapController googleMapController  = await _controller.future;
    googleMapController.animateCamera(
        CameraUpdate.newLatLngBounds(latLngBounds, 60)
    );
  }




  _showMarker(Position position, String icone, String infoWindow) async{
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRatio),
       icone
    ).then((BitmapDescriptor bitmapDescriptor){
      Marker marker = Marker(
        markerId: MarkerId(icone),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(
          title: infoWindow,
        ),
        icon: bitmapDescriptor,
      );
      setState(() {
        _markers.add(marker);
      });
    });

  }



  _setButton (String text, Color color, Function function){
    setState(() {
      _textButton = text;
      _colorButton = color;
      _functionButton = function;

    });
  }

  _aceitarCorrida()async{

    Usuario motorista = await UsuarioFirebase.getDadosUsuarioAtual();
    motorista.latitude = _localMotorista.latitude;
    motorista.longitude = _localMotorista.longitude;

    String idRequidicao = _requisicao.id;
    await db.collection("requisicoes")
    .doc(idRequidicao).update({
      "status" : StatusRequisicao.A_CAMINHO,
      "motorista" : motorista.toMapWithId(),
    }).then((_) {
      String idPassageiro = _requisicao.passageiro.idUsuario;
       db.collection("requisicao_ativa")
      .doc(idPassageiro)
      .update({
        "status" : StatusRequisicao.A_CAMINHO,
      });

      String idMotorista = motorista.idUsuario;
       db.collection("requisicao_ativa_motorista")
          .doc(idMotorista)
          .set({
            "status" : StatusRequisicao.A_CAMINHO,
            "id_requisicao" : idRequidicao,
            "id_usuario" : idMotorista,
          });
          
      });

  }

  _iniciarCorrida(){
    db.collection("requisicoes")
        .doc(_idRequisicao)
        .update({
      "status" : StatusRequisicao.EM_VIAGEM,
      "origem" :{
        "latitude": _requisicao.motorista.latitude,
        "longitude": _requisicao.motorista.longitude,
      }
    });

    db.collection("requisicao_ativa")
        .doc(_requisicao.passageiro.idUsuario)
        .update({
      "status" : StatusRequisicao.EM_VIAGEM
    });

    db.collection("requisicao_ativa_motorista")
        .doc(_requisicao.motorista.idUsuario)
        .update({
      "status" : StatusRequisicao.EM_VIAGEM
    });
  }

  _finalizarCorrida(){
      db.collection("requisicoes")
      .doc(_requisicao.id)
      .update({
        "status" : StatusRequisicao.FINALIZADA
      });

      db.collection("requisicao_ativa")
          .doc(_requisicao.passageiro.idUsuario)
          .update({
        "status" : StatusRequisicao.FINALIZADA
      });

      db.collection("requisicao_ativa_motorista")
          .doc(_requisicao.motorista.idUsuario)
          .update({
        "status" : StatusRequisicao.FINALIZADA
      });
  }

  _confirmarCorrida(){

    db.collection("requisicoes")
        .doc(_requisicao.id)
        .update({
      "status" : StatusRequisicao.CONFIRMADA
    });

    db.collection("requisicao_ativa")
        .doc(_requisicao.passageiro.idUsuario)
        .delete();


    db.collection("requisicao_ativa_motorista")
        .doc(_requisicao.motorista.idUsuario)
        .delete();
    Navigator.pushReplacementNamed(context, "/motorista");
  }


  _statusAguardando(){
    _mensagemStaus = "Aceitar Corrida";
    _setButton(
        "Aceitar Corrida",
        Color(0xff1ebbd8),
            (){
          _aceitarCorrida();
        }
    );

    Position position = Position(
      latitude: _localMotorista.latitude ,
      longitude: _localMotorista.longitude,
    );

    _showMarker(
        position,
        "assets/images/motorista.png",
        "Motorista"
    );

    _moveCamera(
        CameraPosition(
          target: LatLng( position.latitude, position.longitude),
          zoom: 19,
        )
    );

  }

  _statusACaminho()async{
    _mensagemStaus = "A caminho do passageiro";
    _setButton(
        "Iniciar Corrida",
      Color(0xff1ebbd8),
        (){
          _iniciarCorrida();
        },

    );
    LatLng latLngDestino = LatLng(_requisicao.passageiro.latitude,_requisicao.passageiro.longitude );
    LatLng latLngMotorista = LatLng(_requisicao.motorista.latitude,_requisicao.motorista.longitude );
    Marker markMotorista = await marcador.setMarker(latLngMotorista,
        "assets/images/motorista.png",
        "Motorista"
    );

    Marker markPassageiro = await marcador.setMarker(latLngDestino,
        "assets/images/passageiro.png",
        "Passageiro"
    );

    LatLngBounds latLngBounds = UtilPosition.getLatLngBounds(latLngDestino,latLngMotorista);

    setState(() {
      _markers.add(markMotorista);
      _markers.add(markPassageiro);
      _moveCameraBounds(latLngBounds);

    });

  }

  _statusEmViagem()async{
    _markers = {};
    _mensagemStaus = "Em viagem";
    _setButton(
      "Finalizar Corrida",
      Color(0xff1ebbd8),
          (){
        _finalizarCorrida();
      },

    );

    LatLng latLngDestino = LatLng(_requisicao.destino.latitude,_requisicao.destino.longitude );
    LatLng latLngMotorista = LatLng(_requisicao.motorista.latitude,_requisicao.motorista.longitude );
    Marker markMotorista = await marcador.setMarker(latLngMotorista,
        "assets/images/motorista.png",
        "Motorista"
    );

    Marker markDestino = await marcador.setMarker(latLngDestino,
        "assets/images/destino.png",
        "Destino"
    );

    LatLngBounds latLngBounds = UtilPosition.getLatLngBounds(latLngDestino,latLngMotorista);

    setState(() {
      _markers.add(markMotorista);
      _markers.add(markDestino);
      _moveCameraBounds(latLngBounds);

    });

  }

  _statusFinalizada()async{
    _markers = {};
    var f =  NumberFormat("#,##0.00", "pt_BR");


    //Mede a distância entre doi pontos
    double distanciaKm = await Geolocator().distanceBetween(
        _requisicao.origem.latitude,
        _requisicao.origem.longitude,
        _requisicao.destino.latitude,
        _requisicao.destino.longitude
    ) /1000;


    //Valor cobrado R$ 8,00 por Km
    double valor = 8 * distanciaKm;
    var valorFormatado = f.format(valor);


    _mensagemStaus = "Viagem Finalizada";
    _setButton(
      "Confirmar - R\$  ${valorFormatado}",
      Color(0xff1ebbd8),
          (){
        _confirmarCorrida();
      },
    );

    Position position = Position(
      latitude: _requisicao.destino.latitude ,
      longitude: _requisicao.destino.longitude,
    );

    _showMarker(
        position,
        "assets/images/destino.png",
        "Destino"
    );

    _moveCamera(
        CameraPosition(
          target: LatLng( position.latitude, position.longitude),
          zoom: 19,
        )
    );

  }

  _statusConfirmada(){

  }


  _addListenerRequisicao() async{
    String idRequisicao = widget._idRequisicao;
   _requisicaoStreamer =  await db.collection("requisicoes")
    .doc(idRequisicao).snapshots().listen((snapshot) {
        if(snapshot.data() != null){

          Map<String,dynamic> map = snapshot.data();
         _requisicao = Requisicao.fromMap(map);
         _statusRequisicao = _requisicao.status;


          print ("Status " + _statusRequisicao );
          switch(_statusRequisicao){
            case StatusRequisicao.AGUARDANDO:
              _statusAguardando();
              break;
            case StatusRequisicao.A_CAMINHO:
              _statusACaminho();
              break;
            case StatusRequisicao.EM_VIAGEM:
              _statusEmViagem();
              break;
            case StatusRequisicao.FINALIZADA:
              _statusFinalizada();
              break;
            case StatusRequisicao.CONFIRMADA:
              _statusConfirmada();
              break;
          }

        }
    });
  }

  _recoverRequisicao()async{
    String idRequsicao = widget._idRequisicao;   
    DocumentSnapshot documentSnapshot  = await db.collection("requisicoes")
    .doc(idRequsicao).get();

  }



  iniciar()async{

    _idRequisicao = widget._idRequisicao;
    marcador = Marcador(context);
    await _recoverLastPosition();
   _addListenerRequisicao();
   _addListenerPosition();
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    iniciar();


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Uber - " + _mensagemStaus),
      ),

      body: Container(
        child: _localMotorista == null
        ? Center(
            child: CircularProgressIndicator()
        )
        : Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition:  _initialCameraPosition(),
              onMapCreated: _onMapCreated,
              //myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: _markers,
            ),

            Positioned(
              bottom:0,
              left: 0,
              right: 0,
              child: Container(

                margin: EdgeInsets.only(bottom: 10,  left:60, right:60),
                height: 50,
                width: double.infinity,
                child:RaisedButton(
                  color: _colorButton,
                  child: Text(
                    _textButton,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  shape: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  //padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                  onPressed:  _functionButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _requisicaoStreamer.cancel();
  }
}
