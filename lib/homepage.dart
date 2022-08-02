import 'package:flutter/material.dart';
import 'package:zerosound/dB/realtiledb.dart';
import 'package:zerosound/main.dart';

import 'dB/multipointdb.dart';
import 'audioplayer/player.dart';

enum Menu { Calibrate, LogOut}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedMenu = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ZeroSound App'),
        actions: <Widget>[
          PopupMenuButton<Menu>(
            // Callback that sets the selected popup menu item.
              onSelected: (Menu item) {
                setState(() {
                  _selectedMenu = item.name;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
                const PopupMenuItem<Menu>(
                  value: Menu.Calibrate,
                  child: Text('Calibrate dB meter'),
                ),
                const PopupMenuItem<Menu>(
                  value: Menu.LogOut,
                  child: Text('Log out'),
                ),

              ])
        ],

      ),
      body: Column(
        children: [
          TextButton(
            child: Text('Realtime dB Meter'),
            onPressed: (){
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => NoiseApp(),
                ),
              );
            },
          ),
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
