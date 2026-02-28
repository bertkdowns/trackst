import 'package:flutter/material.dart';
import 'package:trackst/location.dart';
import 'package:trackst/midi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackst',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MyHomePage(title: 'Trackst'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _proximity = 0;

  @override
  void initState() {
    super.initState();
    MidiLoopController.instance.startLoop();
  }

  @override
  void dispose() {
    MidiLoopController.instance.stopLoop();
    super.dispose();
  }

  Future<void> _setProximity(double value) async {
    await MidiLoopController.instance.applyProximity(value);
    setState(() {
      _proximity = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LocationTracker('t'),
            Text('Proximity: ${(_proximity * 100).round()}%'),
            Slider(
              value: _proximity,
              min: 0,
              max: 1,
              onChanged: (double value) {
                _setProximity(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
