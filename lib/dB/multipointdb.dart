
import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'meter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

//TODO:
//this value is added to the reading for calibration
var offset = 20;


class MultiDB extends StatefulWidget {
  @override
  _MultiDBState createState() => _MultiDBState();
}

class _MultiDBState extends State<MultiDB> {
  int iteration = 1;
  List<double> data = <double>[];
  final _title = TextEditingController();
  int readingNumber = 0; //iterates up with each reading
  double readingValue = 0; //the value save
  final _offsetController = TextEditingController();
  double  averageDB = 0;
  Timer? timer; //used to adjust averaging time
  bool _isRecording = false; //controls state of app
  StreamSubscription<NoiseReading>? _noiseSubscription; //required stream of noise information
  late NoiseMeter _noiseMeter;
  double? maxDB; //from meter.dart
  double? meanDB; //from meter.dart, not used for the average.
  var recordData = []; //Used with timer for averaging
  // ChartSeriesController? _chartSeriesController;
  late int previousMillis;
  var db = FirebaseFirestore.instance;


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
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        title: const Text('Sound Pressure (dB)'),
        backgroundColor: Colors.black54,
      ),

      body: Container(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  meanDB != null ? meanDB!.toStringAsFixed(2)+" dB" : 'ZeroSound App',
                  style: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                ),
                Text(
                  meanDB != null
                      ? '${averageDB.toStringAsFixed(1)}' + 'dB'
                      : '0.0',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                ),
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
                IconButton(
                    icon: _isRecording ? Icon(Icons.stop) : Icon(Icons.play_arrow),
                    onPressed: _isRecording ? stop : start,
                )
              ],
            ),
            Row(
              children: [
                Text('Title:  '),
                SizedBox(
                  height: 20,
                  width: 300,
                  child: TextField(
                    controller: _title,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SaveData(title: _title.text, data: data),
                TextButton(
                    child: Text('Undo'),
                    onPressed: (){
                      data.removeLast();
                      iteration = iteration - 1;
                      setState(() {});
                    }
                ),
                TextButton(
                    child: Text('Add'),
                    onPressed: (){
                      data.add(averageDB);
                      iteration = iteration + 1;
                      setState(() {});
                    }
                ),

              ],
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: data.length,
                  itemBuilder: (context, index){
                    return ListTile(
                      title: Text('Reading: '+ index.toString()),
                      trailing: Text(data[index].toStringAsFixed(1)+" dB"),
                    );
                  }
              ),
            ),

          ],
        ),
      ),
    );
  }
}


//Save Data to Cloud Firestore
class SaveData extends StatelessWidget {
  final String title;
  List<double> data;

  SaveData({required this.title, required this.data});

  @override



  Widget build(BuildContext context) {
    // Create a CollectionReference called users that references the firestore collection
    CollectionReference datasets = FirebaseFirestore.instance.collection('DataSets');
    final FirebaseAuth auth = FirebaseAuth.instance;

    Future<void> _success() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: SingleChildScrollView(
              child: ListBody(
                children: const <Widget>[
                  Text('Data has been saved to the cloud.'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Done'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    Future<void> _fail() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Failed'),
            content: SingleChildScrollView(
              child: ListBody(
                children: const <Widget>[
                  Text('Failed to push data to the cloud.'),
                  Text('Make sure you have an internet connection.')
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    Future<void> addData() {
      return datasets
          .add({
        'title': title,
        'data': data,
        'datetime': DateTime.now(),
        'createdby': auth.currentUser!.email,
      })
          .then((value) => _success())
          .catchError((error) => _fail());
    }

    return TextButton(
      onPressed: (){
        addData();
      },
      child: Text(
        "Save Data",
      ),
    );
  }
}