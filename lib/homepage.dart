import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zerosound/dB/realtiledb.dart';
import 'package:zerosound/main.dart';

import 'dB/multipointdb.dart';
import 'audioplayer/player.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    var doc;

    //Load the saved offset value
    FirebaseFirestore.instance
        .collection('offsets')
        .doc(auth.currentUser!.email)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        doc = documentSnapshot.data();
        offset = doc['offset'];
      }
    });


    return Scaffold(
      appBar: AppBar(
        title: Text('ZeroSound App'),
        actions: [
          Row(
            children: [
              PopupMenuButton<MenuItem>(
                onSelected: (item) => onSelected(context, item),
                itemBuilder: (context) => [
                  ...MenuItems.itemsFirst.map(buildItem).toList(),
                ],
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [

          TextButton(
            child: Text('Multi-Point data collection'),
            onPressed: (){
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => MultiDB(),
                ),
              );
            },
          ),
          TextButton(
            child: Text('Anti-Siren Demo'),
            onPressed: (){
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => Playback(),
                ),
              );
            },
          ),
        ],
      )
    );
  }
}


PopupMenuItem<MenuItem> buildItem(MenuItem item) => PopupMenuItem<MenuItem>(
  value: item,
  child: Row(
    children: [
      Icon(item.icon, color: Colors.black),
      const SizedBox(width: 12,),
      Text(item.text),
    ],
  ),
);

void onSelected(BuildContext context, MenuItem item){
  switch (item) {
    case MenuItems.itemLogout:
      FirebaseAuth.instance.signOut();
      break;
    case MenuItems.itemSettings:
      Navigator.pushNamed(context, '/settings');
      print('settings');
      break;

    case MenuItems.itemCalibrate:
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => NoiseApp(),
        ),
      );
      break;
  //Navigator.pushNamed(context, '/settings');

  }
}


class MenuItem{
  final String text;
  final IconData icon;

  const MenuItem({
    required this.text,
    required this.icon,
  });

}

class MenuItems{
  static const List<MenuItem> itemsFirst = [
    itemCalibrate,
    itemSettings,
    itemLogout,
  ];

  static const List<MenuItem> itemsSecond = [
    itemLogout
  ];

  static const itemSettings = MenuItem(text: 'Settings', icon: Icons.settings);
  static const itemLogout = MenuItem(text: 'Logout', icon: Icons.logout);
  static const itemCalibrate = MenuItem(text: 'Calibrate', icon: Icons.add);

}