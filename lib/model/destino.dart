
class Destino {
  String _rua;
  String _numero;
  String _cidade;
  String _bairro;
  String _cep;
  double _latitude;
  double _longitude;

  String get rua => _rua;

  set rua(String value) {
    _rua = value;
  }


  String get numero => _numero;

  set numero(String value) {
    _numero = value;
  }

  String get cidade => _cidade;

  set cidade(String value) {
    _cidade = value;
  }

  String get bairro => _bairro;

  set bairro(String value) {
    _bairro = value;
  }

  String get cep => _cep;

  set cep(String value) {
    _cep = value;
  }

  double get latitude => _latitude;

  set latitude(double value) {
    _latitude = value;
  }

  double get longitude => _longitude;

  set longitude(double value) {
    _longitude = value;
  }
  Destino();

  Destino.fromMapDB(Map<String, dynamic> map){
    this.rua = map["rua"];
    this.numero = map["numero"];
    this.bairro = map["bairro"];
    this.cep = map["cep"];
    this.latitude = map["latitude"];
    this.longitude = map["longitude"];


  }

  Map<String, dynamic> toMap(){
    return {
      "rua" : this.rua,
      "numero" : this.numero,
      "bairro" : this.bairro,
      "cep" : this.cep,
      "latitude" : this.latitude,
      "longitude" : this.longitude,
    };
  }
}