import 'package:flutter/material.dart';
import 'package:uber/screens/routes.dart';
import 'package:uber/screens/screen_cadastro.dart';
import 'package:uber/screens/screen_login.dart';
import 'screens/screen_home.dart';
import '';

void main() {
  final ThemeData theme = ThemeData(
    primaryColor: Color(0xff37474f),
    accentColor: Color(0xff546e7a),
  );
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ScreenLogin(),
    theme: theme,
    initialRoute: "/",
    onGenerateRoute: Routes.createRoutes,
    title: "Uber",
  ));
}

