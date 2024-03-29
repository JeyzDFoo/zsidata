
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';
import 'login.dart';

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

var quietmic_lat;
var quietmic_long;
var noiseymic_lat;
var noiseymic_long;
var panel_lat;
var panel_long;
var noisesource_lat;
var noisesource_long;

var offset = 0; //16 for Jeremy's A13


Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(SoundApp());

}


class SoundApp extends StatefulWidget {
  @override
  _SoundAppState createState() => _SoundAppState();
}

class _SoundAppState extends State<SoundApp> {
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
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot){
          if (snapshot.hasData){
            return HomePage();
          } else {
            return LoginWidget();
          }

        },
      ),
    );
  }
}
