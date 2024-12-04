import 'package:flutter/material.dart';
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
    return Scaffold(
      body: ListView(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 120.0),
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/snake_pixel');
              },
              style: ElevatedButton.styleFrom(
                shadowColor: Colors.blue,
                // 按钮背景颜色
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // 设置圆角
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                // 内边距
                elevation: 5, // 阴影效果
              ),
              child: const Text('复古像素贪吃蛇'),
            ),
          ),
        ],
      ),
    );
  }
}
