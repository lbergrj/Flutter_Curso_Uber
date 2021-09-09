import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:firebase_auth/firebase_auth.dart';
import "package:google_maps_flutter/google_maps_flutter.dart";
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:uber/model/destino.dart';
import 'package:uber/model/requisicao.dart';
import 'package:uber/model/usuario.dart';
import 'package:uber/util/UtilPosition.dart';
import 'package:uber/util/marcador.dart';
import 'package:uber/util/status_requisicao.dart';
import 'package:uber/util/usuario_firebase.dart';

class ScreenPassageiro extends StatefulWidget {
  @override
  _ScreenPassageiroState createState() => _ScreenPassageiroState();
}

class _ScreenPassageiroState extends State<ScreenPassageiro> {
  List<String>_menuItens = ["Configurações", "Deslogar"];
  FirebaseAuth auth = FirebaseAuth.instance;
  TextEditingController _controllerDestino = TextEditingController(
    text:  "Av. Paulista, 807",
  );
  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _position;
  Set<Marker> _markers = {};
  String _idRequisicao;
  Position _localPassageiro;
  Requisicao _requisicao;
  StreamSubscription<DocumentSnapshot> _requisicaoStreamer;
  Marcador marcador ;

  //Controles para exibição na Tela
  bool _showAdressTextField = true;
  String _textButton = "Chamar Uber";
  Color _colorButton = Color(0xff1ebbd8);
  Function _functionButton;


  _chosedItem (String chosed){
    switch(chosed){
      case "Deslogar" :
        _logOff();
       break;

      case "Configurações" :
        break;
    }
  }

  _recoverLastPosition()async{
    Position position = await Geolocator().getLastKnownPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      if(position != null){
        _localPassageiro = position;
      }
    });
  }

  _addListenerPosition()async {
    var geolocator  = Geolocator();
    var locationOptions =  LocationOptions(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10
    );
    geolocator.getPositionStream(locationOptions).listen((Position pos)async {

      if(_idRequisicao != null && _idRequisicao.isNotEmpty){
        print("Position ${pos.latitude} ${pos.longitude}");
        await UsuarioFirebase.atualizarDadosLocalizacaoPassageiro(
            _idRequisicao,
            pos.latitude,
            pos.longitude
        );
      }
      else if (pos != null){
        setState(() {
          _localPassageiro = pos;
          print(pos);
        });
      }

    });
  }
  
  _moveCamera (CameraPosition cameraPosition) async{
    GoogleMapController googleMapController  = await _controller.future;
    googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition)
    );
  }


  _recuperarRequisicaoAtiva()async {
    User user = await UsuarioFirebase.getUsuarioAtual();
    FirebaseFirestore db =  FirebaseFirestore.instance;
    DocumentSnapshot snapshot =  await  db.collection("requisicao_ativa")
    .doc(user.uid)
    .get();
    Map<String, dynamic> map = snapshot.data();
    if(snapshot.exists && map != null ){
      _idRequisicao = map["id_requisicao"];
      if(_requisicaoStreamer == null){
        _addListenerRequisicao(_idRequisicao );
      }

    }
    else{

      _statusUberNaoChamado();
    }

  }

  _addListenerRequisicao(String idRequisicao)async{
      FirebaseFirestore db = FirebaseFirestore.instance;
      _requisicaoStreamer = db.collection("requisicoes")
          .doc(idRequisicao).snapshots().listen((snapshot) {
          Map<String,dynamic> map = snapshot.data();
          _requisicao = Requisicao.fromMap(map);
        if (  map != null){
          String status = map["status"];
          print("Listener");
          switch(status){
            case StatusRequisicao.AGUARDANDO:
              _statusAguardando();
              break;
            case StatusRequisicao.CANCELADA:
              _statusUberNaoChamado();
              break;
            case StatusRequisicao.A_CAMINHO:
              print ("a caminho");
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
        else{
          _statusUberNaoChamado();
        }

      });
    }


  _statusUberNaoChamado()async {
    _showAdressTextField = true;
    _markers = {};
    _setButton(
        "Chamar Uber",
        Color(0xff1ebbd8),
            () {
          _chamarUber();
        }
    );


    Marker markPassageiro = await marcador.setMarker(
        LatLng(_localPassageiro.latitude, _localPassageiro.longitude),
        "assets/images/passageiro.png",
        "Passageiro"
    );

    _moveCamera(_cameraPosition(_localPassageiro, 15));
    setState(() {
      _markers.add(markPassageiro);

    });

  }

  _statusAguardando()async{
    _showAdressTextField = false;
    _markers = {};
    _setButton(
        "Cancelar",
        Colors.red,
            (){
          _cancelarUber();
        }

    );
    await _recuperarRequisicaoAtiva();

    //Usa os dados da requisição para posisionra o passageiro
    double passageiroLatitude = _requisicao.passageiro.latitude;
    double passageiroLongitude = _requisicao.passageiro.longitude;
    Position passageiroPosition = Position(
        latitude: passageiroLatitude,
        longitude: passageiroLongitude
    );

    Marker markPassageiro = await marcador.setMarker(
        LatLng(_requisicao.passageiro.latitude, _requisicao.passageiro.longitude),
        "assets/images/passageiro.png",
        "Passageiro"
    );
    setState(() {
      _markers.add(markPassageiro);
    });

    //_showMarkerPassageiro(passageiroPosition);


    _moveCamera(_cameraPosition(passageiroPosition, 15));
  }

  _statusACaminho()async{
    _showAdressTextField = false;
    _setButton(
        "Motorista a caminho",
        Colors.grey,
            (){

        }
    );

    LatLng latLngPassageiro = LatLng(_requisicao.passageiro.latitude, _requisicao.passageiro.longitude);
    LatLng latLngMotorista = LatLng(_requisicao.motorista.latitude, _requisicao.motorista.longitude);

    Marker markMotorista = await marcador.setMarker(latLngMotorista,
        "assets/images/motorista.png",
        "Motorista"
    );

    Marker markPassageiro = await marcador.setMarker(latLngPassageiro,
        "assets/images/passageiro.png",
        "Passageiro"
    );

    LatLngBounds latLngBounds = UtilPosition.getLatLngBounds(latLngMotorista, latLngPassageiro);

    setState(() {
      _markers ={};
      _moveCameraBounds(latLngBounds);
      _markers.add( markMotorista);
      _markers.add(markPassageiro);
    });

  }

  _statusEmViagem()async{
    _markers = {};
    _showAdressTextField = false;
    _setButton(
      "Em Viagem",
        Colors.grey,
          (){
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
    _showAdressTextField = false;
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

    _setButton(
      "R\$  ${valorFormatado}",
      Color(0xff1ebbd8),
          (){
        null;
      },
    );

    LatLng latLngDestino= LatLng(
      _requisicao.destino.latitude ,
      _requisicao.destino.longitude,
    );


    Marker markDestino = await marcador.setMarker(latLngDestino,
        "assets/images/destino.png",
        "Destino"
    );

    _moveCamera(
        CameraPosition(
          target:  latLngDestino,
          zoom: 19,
        )
    );
    setState(() {
      _markers.add( markDestino);
    });

  }

  _statusConfirmada()async{
    if(_requisicaoStreamer != null){
      _requisicaoStreamer.cancel();
      _requisicaoStreamer = null;
      _requisicao = null;
      _idRequisicao = null;
      await _statusUberNaoChamado();


    }

  }

  _saveRequisicao(Destino destino) async{

    Usuario passageiro = await UsuarioFirebase.getDadosUsuarioAtual() ;
    passageiro.latitude = _localPassageiro.latitude;
    passageiro.longitude = _localPassageiro.longitude;
    Requisicao requisicao = Requisicao();
    requisicao.destino = destino;
    requisicao.passageiro = passageiro;
    requisicao.status = StatusRequisicao.AGUARDANDO;

    //Salva Requisicao
    FirebaseFirestore db = FirebaseFirestore.instance;
    await db.collection("requisicoes")
      .doc(requisicao.id)
      .set(requisicao.toMap());

    Map<String, dynamic> dadosRequisicaoAdiva = {
      "id_requisicao" : requisicao.id,
      "id_usuario" : passageiro.idUsuario,
      "status": StatusRequisicao.AGUARDANDO,
    };
    _requisicao = requisicao;
    _idRequisicao = requisicao.id;
    //Salva Requisicao
    await db.collection("requisicao_ativa")
        .doc(passageiro.idUsuario)
        .set(dadosRequisicaoAdiva);
    await _statusAguardando();
  }

  _chamarUber()async{
    String endDestino = _controllerDestino.text;
    if(endDestino.isNotEmpty){
      List<Placemark> listaEnderecos = await Geolocator()
          .placemarkFromAddress(endDestino);
      if(listaEnderecos != null && listaEnderecos.isNotEmpty){
        Placemark endereco = listaEnderecos[0];
        Destino destino = Destino();
        destino.cidade = endereco.administrativeArea;
        destino.cep = endereco.postalCode;
        destino.bairro = endereco.subLocality;
        destino.rua = endereco.thoroughfare;
        destino.numero = endereco.subThoroughfare;
        destino.latitude = endereco.position.latitude;
        destino.longitude = endereco.position.longitude;

        String endConfirmacao = "\n Cidade: " + destino.cidade;
        endConfirmacao += "\n Rua: " + destino.rua + ", " + destino.numero;
        endConfirmacao += "\n Bairro: " + destino.bairro;
        endConfirmacao += "\n Cep:  " + destino.cep;

        showDialog(
          context: context,
          builder: (context){
            return AlertDialog(
              title: Text("Confirmação de endereço"),
              content: Text(endConfirmacao),
              contentPadding: EdgeInsets.all(16),
              actions: [
                FlatButton(
                    child: Text("Cancelar",
                      style: TextStyle (
                        color: Colors.red
                      ),
                    ),
                  onPressed:() => Navigator.pop(context),
                ),

                FlatButton(
                  child: Text("Confirmar",
                    style: TextStyle (
                        color: Colors.green
                    ),
                  ),
                  onPressed:() {
                    _saveRequisicao(destino);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  _cancelarUber () async{

    Usuario passageiro = await UsuarioFirebase.getDadosUsuarioAtual() ;
    FirebaseFirestore db = FirebaseFirestore.instance;
    print ("ID Requisicao $_idRequisicao");
   await db.collection("requisicoes")
    .doc(_idRequisicao)
    .update({
      "status" : StatusRequisicao.CANCELADA,
    }).then((_) async{
        await db.collection("requisicao_ativa")
          .doc(passageiro.idUsuario)
          .delete();
   });
   _requisicaoStreamer = null;
   await _recuperarRequisicaoAtiva();
   setState(() {
   });
  }



  _setButton (String text, Color color, Function function){
      setState(() {
        _textButton = text;
        _colorButton = color;
        _functionButton = function;

      });
  }

  CameraPosition _cameraPosition(Position position, double zoom){
    return  CameraPosition(
      target: LatLng( position.latitude, position.longitude),
      zoom: zoom,
    );

  }

  _moveCameraBounds (LatLngBounds latLngBounds) async{
    GoogleMapController googleMapController  = await _controller.future;
    googleMapController.animateCamera(
        CameraUpdate.newLatLngBounds(latLngBounds, 80)
    );
  }


  _logOff() async{
    await auth.signOut();

    Navigator.pushReplacementNamed(context, "/");
  }

  _iniciar() async{
    Firebase.initializeApp();
    marcador = Marcador(context);
    await _recoverLastPosition();
    await _recuperarRequisicaoAtiva();
    _addListenerPosition();
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
     _iniciar();
  }


  _onMapCreated(GoogleMapController controller){
    _controller.complete(controller);
  }

  Widget wait(){
    return Center(
      child: CircularProgressIndicator(

      ),
    );
  }

  @override

  Widget build(BuildContext context) {
    return
   Scaffold(
      appBar: AppBar(
        title: Text("Uber - Passageiro"),
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

      body: Container(
        child:  _localPassageiro == null
            ? wait()
            :
        Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition:  _cameraPosition(_localPassageiro, 10),
              onMapCreated: _onMapCreated,
             // myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: _markers,
            ),

            Visibility(
                visible: _showAdressTextField,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        //padding: EdgeInsets.all(10),
                        margin: EdgeInsets.all(10),
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey[700]
                          ),
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.grey[50],
                        ),
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                              icon: Container(
                                margin: EdgeInsets.only(bottom:15, left: 20, right: 20),
                                width: 10,
                                height: 10,
                                child: Icon(Icons.location_on,
                                  color: Colors.green,
                                ),
                              ),
                              hintText: "Meu Local",
                              border: InputBorder.none
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top:60,
                      left: 0,
                      right: 0,
                      child: Container(
                        //padding: EdgeInsets.all(10),
                        margin: EdgeInsets.all(10),
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey[700]
                          ),
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.grey[50],
                        ),
                        child: TextField(
                          controller: _controllerDestino,
                          readOnly: false,
                          decoration: InputDecoration(
                              icon: Container(
                                margin: EdgeInsets.only(bottom:15, left: 20, right: 20),
                                width: 10,
                                height: 10,
                                child: Icon(Icons.local_taxi_sharp,
                                  color: Colors.black,
                                ),
                              ),
                              hintText: "Informe o Destino",
                              border: InputBorder.none
                          ),
                        ),
                      ),
                    )
                  ],
                ),
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
