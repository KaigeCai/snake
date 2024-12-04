import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snake/snake_pixel.dart';

void main() {
  runApp(const SnakeApp());
}

class SnakeApp extends StatelessWidget {
  const SnakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/snake_pixel': (context) => const SnakeGame(),
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return Scaffold(
      body: ListView(
        children: const <Widget>[
          Button(txt: '贪吃蛇A'),
        ],
      ),
    );
  }
}

class Button extends StatelessWidget {
  const Button({super.key, required this.txt});

  final String txt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 120.0),
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/snake_pixel');
        },
        style: ElevatedButton.styleFrom(
          shadowColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          elevation: 12,
        ),
        child: Text(
          txt,
          style: const TextStyle(fontSize: 32.0, color: Colors.black),
        ),
      ),
    );
  }
}
