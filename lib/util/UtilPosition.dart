
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UtilPosition{

  static LatLngBounds getLatLngBounds(LatLng p1, LatLng p2){

    double longitude1 = p1.longitude;
    double latitude1 = p1.latitude;

    double longitude2 = p2.longitude;
    double latitude2 = p2.latitude;


    // Mostrar marcador Passageiro
    Position positionDestino = Position(
        latitude: latitude1,
        longitude: longitude1);


    // Mostrar marcador Motorista
    Position positionMotorista = Position(
        latitude: latitude2,
        longitude: longitude2);
    var nLat, nLon, sLat, sLon;

    if(latitude2 <= latitude1){
      sLat = latitude2;
      nLat = latitude1;
    }

    else{
      sLat = latitude1;
      nLat = latitude2;
    }


    if(longitude2 <= longitude1){
      sLon = longitude2;
      nLon = longitude1;
    }

    else{
      sLon = longitude1;
      nLon = longitude2;
    }

    return  LatLngBounds(
        northeast: LatLng(nLat, nLon),
        southwest: LatLng(sLat,sLon)

    );

  }
}