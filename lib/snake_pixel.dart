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
  late int squaresPerRow = 20; // 每行方格的数量(列数)
  late int squaresPerCol = 43; // 每列方格的数量(行数)

  List<int> snake = [];
  String direction = ''; // 初始方向
  bool isPlaying = false;
  int food = 0;
  Timer? gameTimer;
  bool isManualMode = true; // 控制是否是手动模式

  late Color backgroundColor; // 背景色状态

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showGameStartDialog(context);
    });
    resetGame();
    backgroundColor = Colors.black; // 默认背景色为黑色
    super.initState();
  }

  void showGameStartDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32.0),
              child: SizedBox(
                height: 150.0,
                child: Stack(
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
                                setState(() {
                                  isManualMode = false;
                                });
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
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          showBackgroundColorDialog(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showBackgroundColorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择背景色'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('黑色'),
                onTap: () {
                  setState(() {
                    backgroundColor = Colors.black;
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('白色'),
                onTap: () {
                  setState(() {
                    backgroundColor = Colors.white;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void resetGame() {
    snake = [(squaresPerRow * squaresPerCol / 2).floor()];
    direction = '';
    food = Random().nextInt(squaresPerRow * squaresPerCol);
    while (snake.contains(food)) {
      food = Random().nextInt(squaresPerRow * squaresPerCol);
    }
  }

  void startGame() {
    setState(() {
      isPlaying = true;
    });

    gameTimer = Timer.periodic(const Duration(milliseconds: 200), (Timer timer) {
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
    if (!isManualMode) {
      direction = _getBestDirection(); // 使用AI控制蛇的方向
    }

    switch (direction) {
      case 'up':
        if (snake.first < squaresPerRow) {
          snake.insert(0, snake.first + squaresPerRow * (squaresPerCol - 1));
        } else {
          snake.insert(0, snake.first - squaresPerRow);
        }
        break;
      case 'down':
        if (snake.first >= squaresPerRow * (squaresPerCol - 1)) {
          snake.insert(0, snake.first - squaresPerRow * (squaresPerCol - 1));
        } else {
          snake.insert(0, snake.first + squaresPerRow);
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

    if (snake.first == food) {
      HapticFeedback.mediumImpact(); // 震动反馈
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

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
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
          ),
        );
      },
    );
  }

  // 根据屏幕方向调整网格的维度
  void _updateGridDimensions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 判断屏幕方向，竖屏时设置为 20 x 43，横屏时设置为 43 x 20
    if (screenWidth > screenHeight) {
      // 横屏
      squaresPerRow = 43;
      squaresPerCol = 20;
    } else {
      // 竖屏
      squaresPerRow = 20;
      squaresPerCol = 43;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    _updateGridDimensions();

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
      child: Container(
        color: backgroundColor,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: squaresPerRow * squaresPerCol,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: squaresPerRow,
            childAspectRatio: 1.0, // 保持正方形单元格
          ),
          itemBuilder: (BuildContext context, int index) {
            if (snake.contains(index)) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(1.0),
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
                  padding: const EdgeInsets.all(1.0),
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
      ),
    );
  }
}
