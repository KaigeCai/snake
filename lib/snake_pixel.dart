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
                width: 120.0,
                height: 150.0,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              '手动模式',
                              style: TextStyle(
                                fontSize: 38.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          width: 1,
                          height: double.infinity,
                          color: Colors.black,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            setState(() {
                              isManualMode = false;
                            });
                            startGame();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 12.0),
                            child: const Text(
                              'AI模式',
                              style: TextStyle(
                                fontSize: 38.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 设置按钮（右上角）
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
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: squaresPerRow * squaresPerCol,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: squaresPerRow,
            childAspectRatio: 1.0, // 保持正方形单元格
          ),
          itemBuilder: (BuildContext context, int index) {
            if (snake.contains(index)) {
              if (index == snake.first) {
                return SnakeHead(direction: direction);
              } else {
                return Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Container(color: Colors.green[500]),
                  ),
                );
              }
            }
            if (index == food) {
              return Padding(
                padding: const EdgeInsets.all(1.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: Container(color: Colors.red),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class SnakeHead extends StatelessWidget {
  final String direction; // 方向参数，控制蛇头旋转

  const SnakeHead({super.key, required this.direction});

  @override
  Widget build(BuildContext context) {
    // 定义旋转角度
    double rotationAngle;
    switch (direction) {
      case 'up':
        rotationAngle = 0.0;
        break;
      case 'down':
        rotationAngle = pi;
        break;
      case 'left':
        rotationAngle = -pi / 2;
        break;
      case 'right':
        rotationAngle = pi / 2;
        break;
      default:
        rotationAngle = 0.0;
    }

    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Transform.rotate(
        angle: rotationAngle,
        child: Stack(
          clipBehavior: Clip.none, // 允许舌头超出布局范围
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: Container(
                color: Colors.green[500],
                child: const Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 左眼
                    Positioned(
                      top: 0.2,
                      left: 1.0,
                      child: Text(
                        '.',
                        style: TextStyle(
                          fontSize: 32.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          height: 0.1,
                          wordSpacing: 0.0,
                        ),
                      ),
                    ),
                    // 右眼
                    Positioned(
                      top: 0.2,
                      right: 1.0,
                      child: Text(
                        '.',
                        style: TextStyle(
                          fontSize: 32.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          height: 0.1,
                          wordSpacing: 0.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 舌头
            const Positioned(
              top: -12.0,
              left: 0.2,
              right: 0.2,
              child: Text(
                'Y',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.w300,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
                textHeightBehavior: TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
