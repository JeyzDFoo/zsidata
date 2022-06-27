import 'package:flutter/material.dart';
import 'package:zerosound/dB/realtiledb.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ZeroSound App'),
      ),
      body: Column(
        children: [
          TextButton(
            child: Text('dB Meter'),
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
                  builder: (BuildContext context) => NoiseApp(),
                ),
              );
            },
          ),
        ],
      )
    );
  }
}
