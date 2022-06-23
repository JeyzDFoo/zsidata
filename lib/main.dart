import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zerosound/noiseapp.dart';

//git add .
//git commit -m "notes"
//git push

//firebase init
//select project
// build/web
// single-page app? Yes
//auto deploys? No
//overwrite? Yes
// flutter build web
//firebase deploy



void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debugShowCheckedModeBanner: false,
      title: 'ZeroSound',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.black54,
        fontFamily: 'Georgia',
      ),
      home: NoiseApp(),
    );
  }
}