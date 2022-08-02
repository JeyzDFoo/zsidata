import 'package:flutter/material.dart';

class Calibrate extends StatefulWidget {
  const Calibrate({Key? key}) : super(key: key);

  @override
  State<Calibrate> createState() => _CalibrateState();
}

class _CalibrateState extends State<Calibrate> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('dB Offset:  '),
              SizedBox(
                width: 50,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '20',
                  ),
                  controller: _offsetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  onSubmitted: (value){
                    offset = double.parse(value).toInt();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
