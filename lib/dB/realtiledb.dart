
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerosound/main.dart';
import 'meter.dart';

//TODO:
//add offset value to calibrate dB
//make average dB selectable

//this value is added to the reading for calibration

class NoiseApp extends StatefulWidget {
  @override
  _NoiseAppState createState() => _NoiseAppState();
}

class _NoiseAppState extends State<NoiseApp> {
  //variable declarations
  final _offsetController = TextEditingController();
  double  averageDB = 0;
  Timer? timer; //used to adjust averaging time
  bool _isRecording = false; //controls state of app
  StreamSubscription<NoiseReading>? _noiseSubscription; //required stream of noise information
  late NoiseMeter _noiseMeter;
  double? maxDB; //from meter.dart
  double? meanDB; //from meter.dart, not used for the average.
  List<_ChartData> chartData = <_ChartData>[]; //chart data not used
  var recordData = []; //Used with timer for averaging
  // ChartSeriesController? _chartSeriesController;
  late int previousMillis;

  @override
  void initState() {
    super.initState();
    _noiseMeter = NoiseMeter(onError);
  }

  //setState is called to refresh the UI when recording
  void onData(NoiseReading noiseReading) {
    setState(() {
      if (!_isRecording) _isRecording = true;
    });
    maxDB = noiseReading.maxDecibel;
    meanDB = noiseReading.meanDecibel;

    //capture data to use for averaging
    recordData.add(meanDB);

  }

  void average() {
    timer = Timer.periodic(Duration(seconds: 1), (timer){
      averageDB = recordData.reduce((a, b) => a+b) / recordData.length;
      recordData = [];
    });
  }


  void onError(Object e) {
    print(e.toString());
    _isRecording = false;
  }

  void start() async {
   average();
    previousMillis = DateTime.now().millisecondsSinceEpoch;
    try {
      _noiseSubscription = _noiseMeter.noiseStream.listen(onData);
    } catch (e) {
      print(e);
    }
  }

  //Stop everything, called when the stop button is pushed
  void stop() async {
    try {
      _noiseSubscription!.cancel();
      _noiseSubscription = null;
      timer?.cancel();

      setState(() => _isRecording = false);
    } catch (e) {
      print('stopRecorder error: $e');
    }
    previousMillis = 0;
    chartData.clear();
  }

  //this is for charting? I don't think it's needed.
  void copyValue(
      bool theme,
      ) {
    Clipboard.setData(
      ClipboardData(
          text: 'It\'s about ${maxDB!.toStringAsFixed(1)}dB loudness'),
    ).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2500),
          content: Row(
            children: [
              Icon(
                Icons.check,
                size: 14,
                color: theme ? Colors.white70 : Colors.black,
              ),
              const SizedBox(width: 10),
              const Text('Copied')
            ],
          ),
        ),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    if (chartData.length >= 25) {
      chartData.removeAt(0);
    }
    CollectionReference offsets = FirebaseFirestore.instance.collection('offsets');
    final FirebaseAuth auth = FirebaseAuth.instance;

    Future<void> addOffset() {
      // Call the user's CollectionReference to update the offset
      return offsets
      .doc(auth.currentUser!.email)
          .set({
        'offset': offset, // db offset

      })
          .then((value) => print("Offset Updated"))
          .catchError((error) => print("Failed to update offset: $error"));
    }


    return Scaffold(
      appBar: AppBar(

        title: const Text('Sound Meter Calibration'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: (){
            stop(); //stop the recording so it's not running in the background
            Navigator.pop(context);
          },
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        label: Text(_isRecording ? 'Stop' : 'Start'),
        onPressed: _isRecording ? stop : start,
        icon: !_isRecording ? const Icon(Icons.circle) : null,
        backgroundColor: _isRecording ? Colors.red : Colors.green,
      ),

      body: Container(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text('Increase/Decrease the offset until the reading'),
            Text('matches a dB meter.'),
            SizedBox(
              height: 50,
            ),
            Text('Be sure to STOP and SAVE!'),
            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: (){
                    setState(() {
                      offset = offset - 1;
                    });
                  },
                ),
                Text('dB Offset: ' + offset.toString()),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: (){
                    setState(() {
                      offset = offset + 1;
                    });
                  },
                ),
              ],
            ),


            Text(
              meanDB != null
                  ? 'Average/Second:'
                  : 'Press Start',
              style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 28),
            ),
            Text(
              meanDB != null
                  ? '${averageDB.toStringAsFixed(1)}' + 'dB'
                  : '0.0',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
            ),
            SizedBox(height: 20,),
            TextButton(
              child: Text('Save Offset'),
              onPressed: addOffset,
            ),

          ],
        ),
      ),
    );
  }
}

class _ChartData {
  final double? maxDB;
  final double? meanDB;
  final double frames;

  _ChartData(this.maxDB, this.meanDB, this.frames);
}


