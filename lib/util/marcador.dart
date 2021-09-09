import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Marcador{
 BuildContext context;

 Marcador(this.context);


   Future<Marker> setMarker (LatLng latLng, String icone, String infoWindow) async {
    Marker marker;
     double pixelRatio = MediaQuery
        .of(context)
        .devicePixelRatio;
    await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: pixelRatio),
        icone
    ).then((BitmapDescriptor bitmapDescriptor) {
      marker =   Marker(
        markerId: MarkerId(icone),
        position: latLng,
        infoWindow: InfoWindow(
          title: infoWindow,
        ),
        icon: bitmapDescriptor,
      );
    });
    return marker;
  }

}