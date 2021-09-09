class Usuario{

  String _idUsuario;
  String _nome;
  String _email;
  String _senha;
  String _tipoUsuario;
  double _longitude;
  double _latitude;





  Usuario( );

  Usuario.fromMap( Map<String, dynamic> map){
    this._tipoUsuario = map["tipoUsuario"];
    this._email = map["email"];
    this._nome = map["nome"];

  }

  Usuario.fromMapDB( Map<String, dynamic> map){
    if(map != null) {
      this._tipoUsuario = map["tipoUsuario"];
      this._email = map["email"];
      this._nome = map["nome"];
      this._idUsuario = map["idUsuario"];
      this.latitude = map["latitude"];
      this.longitude = map["longitude"];
    }


  }

  double get longitude => _longitude;

  set longitude(double value) {
    _longitude = value;
  }

  String get idUsuario => _idUsuario;

  String getTipoUsuario(bool entrada){
    return entrada ? "Motorista" : "Passageiro";

  }
  Map<String,dynamic> toMap(){
    return {
      "nome" : this.nome,
      "email" : this.email,
      "tipoUsuario" : this.tipoUsuario
    };
  }

  Map<String,dynamic> toMapWithId(){
    return {
      "nome" : this.nome,
      "email" : this.email,
      "tipoUsuario" : this.tipoUsuario,
      "idUsuario" : this._idUsuario,
      "latitude" : this._latitude,
      "longitude" : this._longitude,
    };
  }


  set idUsuario(String value) {
    _idUsuario = value;
  }

  String get nome => _nome;

  set nome(String value) {
    _nome = value;
  }

  String get email => _email;

  set email(String value) {
    _email = value;
  }

  String get senha => _senha;

  set senha(String value) {
    _senha = value;
  }

  String get tipoUsuario => _tipoUsuario;

  set tipoUsuario(String value) {
    _tipoUsuario = value;
  }

  double get latitude => _latitude;

  set latitude(double value) {
    _latitude = value;
  }
}
