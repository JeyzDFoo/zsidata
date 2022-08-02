
import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zerosound/main.dart';
import 'meter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';

enum Menu { Ambient, SupressionON, SupressionOFF }
enum Hardware { QuietMic, NoiseyMic, Panel, NoiseSource }

//TODO:
//this value is added to the reading for calibration

class MultiDB extends StatefulWidget {
  @override
  _MultiDBState createState() => _MultiDBState();
}

class _MultiDBState extends State<MultiDB> {
  int iteration = 1;
  List<Reading> Readings = <Reading>[];
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
  Location location = Location(); //used for location service initialization
  var currentLocation; //current location of device, updated every second
  String readingtype = 'unknown'; //ambient, suppression on, suppression off


@override

  void initState() {
    super.initState();
    _noiseMeter = NoiseMeter(onError);
  }

  Future<void> getLocation() async{
    var _serviceEnabled = await location.serviceEnabled();

    //check the status of location services
    if (!_serviceEnabled){
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled){
        return;
      }
    }

    var _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied){
      _permissionGranted = await location.requestPermission();

      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    var myLocation = await location.getLocation();

    setState(() {
      currentLocation = myLocation;
    });

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
      getLocation();
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
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0 , 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PopupMenuButton<Menu>(
                    // Callback that sets the selected popup menu item.
                      child: Text('Reading Type: ' + readingtype.toString()),
                      onSelected: (Menu item) {
                        setState(() {
                          readingtype = item.name;
                        });
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
                        const PopupMenuItem<Menu>(
                          value: Menu.Ambient,
                          child: Text('Ambient'),
                        ),
                        const PopupMenuItem<Menu>(
                          value: Menu.SupressionON,
                          child: Text('Suppression ON'),
                        ),
                        const PopupMenuItem<Menu>(
                          value: Menu.SupressionOFF,
                          child: Text('Suppression OFF'),
                        ),

                      ]),
                  PopupMenuButton<Hardware>(
                    // Callback that sets the selected popup menu item.
                      child: Text('Hardware Locations'),
                      onSelected: (Hardware item) {
                        setState(() {
                          if (item == Hardware.QuietMic){
                            quietmic_lat = currentLocation.latitude;
                            quietmic_long = currentLocation.longitude;
                          } else if (item == Hardware.NoiseyMic){
                            noiseymic_lat = currentLocation.latitude;
                            noiseymic_long = currentLocation.longitude;
                          } else if (item == Hardware.Panel){
                            panel_lat = currentLocation.latitude;
                            panel_long = currentLocation.longitude;
                          } else if (item == Hardware.NoiseSource){
                            noisesource_lat = currentLocation.latitude;
                            noisesource_long = currentLocation.longitude;
                          }
                        });
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<Hardware>>[
                        const PopupMenuItem<Hardware>(
                          value: Hardware.QuietMic,
                          child: Text('Quiet Mic'),
                        ),
                        const PopupMenuItem<Hardware>(
                          value: Hardware.NoiseyMic,
                          child: Text('NoiseyMic'),
                        ),
                        const PopupMenuItem<Hardware>(
                          value: Hardware.Panel,
                          child: Text('Panel'),
                        ),
                        const PopupMenuItem<Hardware>(
                          value: Hardware.NoiseSource,
                          child: Text('Noise Source'),
                        ),

                      ]),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SaveData(title: _title.text, readings: Readings),
                TextButton(
                    child: Text('Undo'),
                    onPressed: (){
                      Readings.removeLast();
                      iteration = iteration - 1;
                      setState(() {});
                    }
                ),
                TextButton(
                    child: Text('Add'),
                    onPressed: (){
                      Readings.add(
                          Reading(
                              readingNumber: iteration,
                              db: averageDB,
                              lat: currentLocation.latitude,
                              long: currentLocation.longitude,
                              accuracy: currentLocation.accuracy,
                              time: DateTime.now(),
                              readingtype: readingtype,
                          )
                      );
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
                  //reverse: true,
                  itemCount: Readings.length,
                  itemBuilder: (context, index){
                    return ListTile(
                      title: Text('Reading: '+ Readings[index].readingNumber.toString()),
                      subtitle: Text('Accuracy: ' + Readings[index].accuracy!.toStringAsFixed(2) + ' m'),
                      trailing: Text('dB: ' + Readings[index].db!.toStringAsFixed(1)),
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
  List<Reading> readings;

  SaveData({required this.title, required this.readings});

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
                 // Navigator.of(context).pop();

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
      List<Map<String, dynamic>> JSONdata = [];

      toJSON(){
        for (var i = 0; i < readings.length; i++){
          Map<String, dynamic> linedata = {
            'reading': readings[i].readingNumber,
            'db': readings[i].db,
            'lat': readings[i].lat,
            'long': readings[i].long,
            'time': readings[i].time,
            'accuracy': readings[i].accuracy,
            'readingtype': readings[i].readingtype,
          };
          JSONdata.add(linedata);
        }
      }

      toJSON();


     return datasets
          .add({
        'title': title,
        'readings': JSONdata,
        'created': DateTime.now(),
        'createdby': auth.currentUser!.email,
        'quietmic_lat': quietmic_lat,
        'quietmic_long': quietmic_long,
         'noiseymic_lat': noiseymic_lat,
         'noiseymic_long': noiseymic_long,
         'panel_lat': panel_lat,
         'panel_long': panel_long,
         'noisesource_lat': noisesource_lat,
         'noisesource_long': noisesource_long,
      })
          .then((value) => _success())
          //.catchError((error) => print(error)
          .catchError((error) => _fail()
      );
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

class Reading {
  int? readingNumber;
  double? db;
  double? lat;
  double? long;
  double? accuracy;
  var time;
  String readingtype;

  Reading({
    required this.readingNumber,
    required this.db,
    required this.lat,
    required this.long,
    required this.accuracy,
    required this.time,
    required this.readingtype,
  });


}