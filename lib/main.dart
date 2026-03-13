import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:trackst/location.dart';
import 'package:trackst/audio_layer_player.dart';

final AudioLayerPlayer audioLayerPlayer = AudioLayerPlayer();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.green),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _counter = 0;
  double _distance = 1000;
  double _bearing = 0;

  int _locationIntensityLevel = 0;
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    audioLayerPlayer.initialize(); // intentionally unawaited – fire-and-forget startup
    setState(() => _distance = 997);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("Starting Location Subscription");

      _locationSubscription = getLocationStream().listen(_onLocationUpdate);
      print("got location stream");
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    audioLayerPlayer.dispose();
    super.dispose();
  }

  void _onLocationUpdate(LocationData data) {
    if (data.latitude == null || data.longitude == null) return;
    print("location updated@@ to ${data.latitude} ${data.longitude}");

    final distance = calculateDistance(
      data.latitude!,
      data.longitude!,
      targetLatitude,
      targetLongitude,
    );
    final bearing = calculateBearing(
      data.latitude!,
      data.longitude!,
      targetLatitude,
      targetLongitude,
    );
    print("Distance is $distance");
    final intensityLevel = getProximityIntensity(distance, numLevels: layerAssets.length);
    setState(() {
      _distance = distance;
      _bearing = bearing;
    });
    if (intensityLevel == _locationIntensityLevel) return;
    setState(() => _locationIntensityLevel = intensityLevel);
    audioLayerPlayer.setIntensityLevel(intensityLevel);
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            LocationTracker("t"),
            Text(
              '$_distance',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              '${_bearing.toStringAsFixed(1)}°',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
