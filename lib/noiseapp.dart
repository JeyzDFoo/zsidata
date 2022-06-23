
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'meter.dart';

class NoiseApp extends StatefulWidget {
  @override
  _NoiseAppState createState() => _NoiseAppState();
}

class _NoiseAppState extends State<NoiseApp> {
  //variable declarations
  Timer? timer;
  bool _isRecording = false; //controls state of app
  StreamSubscription<NoiseReading>? _noiseSubscription; //required stream of noise information
  late NoiseMeter _noiseMeter;
  double? maxDB;
  double? meanDB;
  List<_ChartData> chartData = <_ChartData>[];
  List<_RecordData> recordData = <_RecordData>[];
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

    //capture data for chart
    chartData.add(
      _ChartData(
        maxDB,
        meanDB,
        ((DateTime.now().millisecondsSinceEpoch - previousMillis) / 1000)
            .toDouble(),
      ),
    );

    //capture data to use for averaging a location
    recordData.add(
      _RecordData(
        maxDB,
        meanDB,
        ((DateTime.now().millisecondsSinceEpoch - previousMillis) / 1000)
            .toDouble(),
      ),
    );

  }

  void average() {
    print('called');
    timer = Timer.periodic(Duration(seconds: 3), (timer){
      print('timer complete');
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
    bool _isDark = Theme.of(context).brightness == Brightness.light;
    if (chartData.length >= 25) {
      chartData.removeAt(0);
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isDark ? Colors.green : Colors.green.shade800,
        title: const Text('Sound Pressure (dB)'),
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
            Text('Average:'),
            Text('Test value'),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  maxDB != null ? maxDB!.toStringAsFixed(2) : 'Press start',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 36),
                ),
              ),
            ),
            Text(
              meanDB != null
                  ? 'Mean: ${meanDB!.toStringAsFixed(2)}'
                  : 'Awaiting data',
              style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 14),
            ),
            const Expanded(
              child: Text('Test')

              // SfCartesianChart(
              //   series: <LineSeries<_ChartData, double>>[
              //     LineSeries<_ChartData, double>(
              //         dataSource: chartData,
              //         xAxisName: 'Time',
              //         yAxisName: 'dB',
              //         name: 'dB values over time',
              //         xValueMapper: (_ChartData value, _) => value.frames,
              //         yValueMapper: (_ChartData value, _) => value.maxDB,
              //         animationDuration: 0),
              //   ],
              // ),
            ),
            const SizedBox(
              height: 68,
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

class _RecordData {
  final double? maxDB;
  final double? meanDB;
  final double frames;

  _RecordData(this.maxDB, this.meanDB, this.frames);
}