import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  final int squaresPerRow = 20;
  final int squaresPerCol = 43;

  List<int> snake = [];
  var direction = 'down'; // 初始方向
  var isPlaying = false;
  int food = 0;
  Timer? gameTimer;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showGameStartDialog(context);
    });
    resetGame();
    super.initState();
  }

  void resetGame() {
    snake = [(squaresPerRow * squaresPerCol / 2).floor()];
    direction = 'down';
    food = Random().nextInt(squaresPerRow * squaresPerCol);
    while (snake.contains(food)) {
      food = Random().nextInt(squaresPerRow * squaresPerCol);
    }
  }

  void startGame() {
    setState(() {
      isPlaying = true;
    });

    gameTimer =
        Timer.periodic(const Duration(milliseconds: 200), (Timer timer) {
      setState(() {
        moveSnake();
        if (checkGameOver()) {
          timer.cancel();
          isPlaying = false;
          showGameOverDialog();
        }
        if (snake.first == food) {
          snake.add(food); // 吃到食物，蛇增长
          generateNewFood();
        }
      });
    });
  }

  String _getBestDirection() {
    int head = snake.first;
    int targetFood = food;

    // 计算蛇头与食物的相对位置
    int headRow = head ~/ squaresPerRow;
    int headCol = head % squaresPerRow;
    int foodRow = targetFood ~/ squaresPerRow;
    int foodCol = targetFood % squaresPerRow;

    // 判断食物的位置相对蛇头，选择最合适的移动方向
    if (foodRow < headRow) {
      return 'up'; // 食物在蛇头上方，移动方向为上
    } else if (foodRow > headRow) {
      return 'down'; // 食物在蛇头下方，移动方向为下
    } else if (foodCol < headCol) {
      return 'left'; // 食物在蛇头左侧，移动方向为左
    } else {
      return 'right'; // 食物在蛇头右侧，移动方向为右
    }
  }

  void moveSnake() {
    // 使用AI控制蛇的方向
    String aiDirection = _getBestDirection();

    // 结合用户手动控制与AI控制
    // 如果用户改变了方向，优先使用用户输入的方向
    if (direction != aiDirection) {
      // 保证蛇不会直接掉头
      if (aiDirection == 'up' && direction != 'down') {
        direction = 'up';
      } else if (aiDirection == 'down' && direction != 'up') {
        direction = 'down';
      } else if (aiDirection == 'left' && direction != 'right') {
        direction = 'left';
      } else if (aiDirection == 'right' && direction != 'left') {
        direction = 'right';
      }
    }

    switch (direction) {
      case 'down':
        if (snake.first >= squaresPerRow * (squaresPerCol - 1)) {
          snake.insert(0, snake.first - squaresPerRow * (squaresPerCol - 1));
        } else {
          snake.insert(0, snake.first + squaresPerRow);
        }
        break;
      case 'up':
        if (snake.first < squaresPerRow) {
          snake.insert(0, snake.first + squaresPerRow * (squaresPerCol - 1));
        } else {
          snake.insert(0, snake.first - squaresPerRow);
        }
        break;
      case 'left':
        if (snake.first % squaresPerRow == 0) {
          snake.insert(0, snake.first + squaresPerRow - 1);
        } else {
          snake.insert(0, snake.first - 1);
        }
        break;
      case 'right':
        if ((snake.first + 1) % squaresPerRow == 0) {
          snake.insert(0, snake.first - squaresPerRow + 1);
        } else {
          snake.insert(0, snake.first + 1);
        }
        break;
    }

    if (snake.length > 1) {
      snake.removeLast(); // 防止蛇在开始时生长
    }
  }

  void generateNewFood() {
    food = Random().nextInt(squaresPerRow * squaresPerCol);
    while (snake.contains(food)) {
      food = Random().nextInt(squaresPerRow * squaresPerCol);
    }
  }

  bool checkGameOver() {
    for (int i = 1; i < snake.length; i++) {
      if (snake[i] == snake.first) {
        return true;
      }
    }
    return false;
  }

  void showGameStartDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32.0),
            child: SizedBox(
              height: 150.0,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              alignment: Alignment.center,
                              color: Colors.white,
                              child: const Text(
                                '手动模式',
                                style: TextStyle(
                                  fontSize: 32.0,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: double.infinity,
                          color: Colors.black,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              startGame();
                            },
                            child: Container(
                              alignment: Alignment.center,
                              color: Colors.white,
                              child: const Text(
                                'AI模式',
                                style: TextStyle(
                                  fontSize: 32.0,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('游戏结束'),
          content: Text(
            '你的分数: ${snake.length}',
            style: const TextStyle(fontSize: 24.0),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '排行榜',
                style: TextStyle(fontSize: 24.0),
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 100.0),
            TextButton(
              child: const Text(
                '重新开始',
                style: TextStyle(fontSize: 24.0),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  resetGame();
                });
                showGameStartDialog(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return GestureDetector(
      onTap: () {
        if (!isPlaying) startGame();
      },
      onVerticalDragUpdate: (DragUpdateDetails details) {
        if (!isPlaying) startGame();
        if (details.primaryDelta! > 0 && direction != 'up') {
          direction = 'down';
        } else if (details.primaryDelta! < 0 && direction != 'down') {
          direction = 'up';
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!isPlaying) startGame();
        if (details.primaryDelta! > 0 && direction != 'left') {
          direction = 'right';
        } else if (details.primaryDelta! < 0 && direction != 'right') {
          direction = 'left';
        }
      },
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: squaresPerRow * squaresPerCol,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: squaresPerRow,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (BuildContext context, int index) {
          if (snake.contains(index)) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(2.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5.0),
                  child: Container(color: Colors.green[500]),
                ),
              ),
            );
          }
          if (index == food) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(2.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(color: Colors.red),
                ),
              ),
            );
          }
          return Container();
        },
      ),
    );
  }
}
