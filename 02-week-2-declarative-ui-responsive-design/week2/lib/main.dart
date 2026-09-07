import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';

import 'lirik_page.dart';

void main() {
  runApp(
    DevicePreview(enabled: true, builder: (context) => const RakagaliApp()),
  );
}

class RakagaliApp extends StatelessWidget {
  const RakagaliApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Lirik Lagu')),
        body: const LirikPage(),
        bottomNavigationBar: Container(
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous),
                color: Colors.blue,
                iconSize: 36.0,
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.play_arrow),
                color: Colors.green,
                iconSize: 48.0,
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.pause),
                color: Colors.amber,
                iconSize: 48.0,
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.skip_next),
                color: Colors.blue,
                iconSize: 36.0,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
