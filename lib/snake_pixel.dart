import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  late int squaresPerRow = 10; // 每行方格的数量(列数)
  late int squaresPerCol = 10; // 每列方格的数量(行数)

  List<int> snake = [];
  String direction = ''; // 初始方向
  String tailDir = ''; // 蛇尾方向
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

    // 在 Windows 系统上监听键盘事件
    if (Platform.isWindows || Platform.isMacOS) {
      HardwareKeyboard.instance.addHandler((KeyEvent event) {
        final key = event.logicalKey;

        if (!isPlaying) startGame();

        // 使用上下左右键控制方向
        if (key == LogicalKeyboardKey.arrowUp && direction != 'down') {
          direction = 'up';
        } else if (key == LogicalKeyboardKey.arrowDown && direction != 'up') {
          direction = 'down';
        } else if (key == LogicalKeyboardKey.arrowLeft && direction != 'right') {
          direction = 'left';
        } else if (key == LogicalKeyboardKey.arrowRight && direction != 'left') {
          direction = 'right';
        }

        if (key == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
        return true;
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isMacOS) {
      HardwareKeyboard.instance.removeHandler((_) {
        return false;
      });
    }
    super.dispose();
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

  // AI控制蛇运动方向

  String _getBestDirection() {
    int head = snake.first;
    int targetFood = food;

    // 计算蛇头与食物的相对位置
    int headRow = head ~/ squaresPerRow;
    int headCol = head % squaresPerRow;
    int foodRow = targetFood ~/ squaresPerRow;
    int foodCol = targetFood % squaresPerRow;

    // 先计算蛇头的四个可能的移动方向
    List<String> directions = ['up', 'down', 'left', 'right'];
    List<String> safeDirections = []; // 用来存放安全的移动方向

    // 判断每个方向是否安全
    for (String direction in directions) {
      int newHead;
      switch (direction) {
        case 'up':
          newHead = head - squaresPerRow;
          break;
        case 'down':
          newHead = head + squaresPerRow;
          break;
        case 'left':
          newHead = head - 1;
          break;
        case 'right':
          newHead = head + 1;
          break;
        default:
          newHead = head;
          break;
      }

      // 如果蛇撞墙，处理穿墙逻辑
      newHead = _handleWallCollision(newHead, direction);

      // 判断新头部是否会与蛇身发生碰撞
      if (newHead >= 0 && newHead < squaresPerRow * squaresPerCol && !snake.contains(newHead)) {
        safeDirections.add(direction); // 如果方向安全，则加入到安全方向列表
      }
    }

    // 如果没有安全的方向，表示游戏结束或无法继续
    if (safeDirections.isEmpty) {
      return '';
    }

    // 计算包围圈，判断是否有被困的风险
    if (_isSnakeTrapped(head)) {
      return _findEscapePath(head); // 如果蛇被困，寻找逃生路径
    }

    // 如果蛇头与食物相对位置存在差距，优先选择靠近食物的方向
    if (safeDirections.contains('up') && foodRow < headRow) {
      return 'up'; // 食物在蛇头上方，优先选择上
    } else if (safeDirections.contains('down') && foodRow > headRow) {
      return 'down'; // 食物在蛇头下方，优先选择下
    } else if (safeDirections.contains('left') && foodCol < headCol) {
      return 'left'; // 食物在蛇头左侧，优先选择左
    } else if (safeDirections.contains('right') && foodCol > headCol) {
      return 'right'; // 食物在蛇头右侧，优先选择右
    }

    // 如果无法选择食物方向，选择第一个安全方向
    return safeDirections.first; // 选择第一个安全方向
  }

// 处理蛇的穿墙逻辑
  int _handleWallCollision(int newHead, String direction) {
    // 如果蛇头出界，进行穿墙处理
    if (direction == 'up' && newHead < 0) {
      // 如果向上走并且出界，将蛇从下边界穿过
      newHead = (squaresPerRow * squaresPerCol) - squaresPerRow + (newHead % squaresPerRow);
    } else if (direction == 'down' && newHead >= squaresPerRow * squaresPerCol) {
      // 如果向下走并且出界，将蛇从上边界穿过
      newHead = newHead % squaresPerRow;
    } else if (direction == 'left' && newHead % squaresPerRow < 0) {
      // 如果向左走并且出界，将蛇从右边界穿过
      newHead = (squaresPerRow * squaresPerCol) - 1 - (newHead % squaresPerRow);
    } else if (direction == 'right' && newHead % squaresPerRow >= squaresPerRow) {
      // 如果向右走并且出界，将蛇从左边界穿过
      newHead = newHead % squaresPerRow;
    }

    return newHead;
  }

// 判断蛇是否被困住
  bool _isSnakeTrapped(int head) {
    // 判断蛇是否被困的条件可以是：没有任何安全的方向可以移动
    List<String> directions = ['up', 'down', 'left', 'right'];
    for (String direction in directions) {
      int newHead;
      switch (direction) {
        case 'up':
          newHead = head - squaresPerRow;
          break;
        case 'down':
          newHead = head + squaresPerRow;
          break;
        case 'left':
          newHead = head - 1;
          break;
        case 'right':
          newHead = head + 1;
          break;
        default:
          newHead = head;
          break;
      }

      // 如果有一个安全的方向可走，返回false，说明蛇没被困住
      if (newHead >= 0 && newHead < squaresPerRow * squaresPerCol && !snake.contains(newHead)) {
        return false;
      }
    }
    // 如果四个方向都被封锁，说明蛇被困住了
    return true;
  }

// 寻找逃生路径（突破口）
  String _findEscapePath(int head) {
    // 使用广度优先搜索（BFS）来寻找逃生路径，确保找到最短的路径
    List<String> directions = ['up', 'down', 'left', 'right'];
    Set<int> visited = {}; // 记录已经访问过的方格
    Queue<int> queue = Queue<int>(); // BFS队列
    Map<int, String> previousMove = {}; // 记录每个位置的前一个移动方向

    // 起点为蛇头位置，开始BFS搜索
    queue.add(head);
    visited.add(head);

    while (queue.isNotEmpty) {
      int current = queue.removeFirst();

      // 判断当前方格是否安全且未被蛇身占据
      for (String direction in directions) {
        int nextHead;
        switch (direction) {
          case 'up':
            nextHead = current - squaresPerRow;
            break;
          case 'down':
            nextHead = current + squaresPerRow;
            break;
          case 'left':
            nextHead = current - 1;
            break;
          case 'right':
            nextHead = current + 1;
            break;
          default:
            nextHead = current;
            break;
        }

        if (nextHead >= 0 &&
            nextHead < squaresPerRow * squaresPerCol &&
            !snake.contains(nextHead) &&
            !visited.contains(nextHead)) {
          visited.add(nextHead);
          queue.add(nextHead);
          previousMove[nextHead] = direction;

          // 如果找到一个安全出口，就返回这个方向
          if (!_isSnakeTrapped(nextHead)) {
            return direction;
          }
        }
      }
    }

    // 如果没有找到逃生路径，就返回空，表示无法逃脱
    return '';
  }

  void moveSnake() {
    if (!isManualMode) {
      direction = _getBestDirection(); // 使用AI控制蛇的方向
    }

    if (snake.length > 1) {
      int secondLast = snake[snake.length - 2];
      tailDir = _getTailDirection(secondLast); // 获取蛇尾方向
    }

    // 先旋转蛇头，再根据新的方向移动蛇
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

  String _getTailDirection(int secondLast) {
    int last = snake.last;
    int diff = last - secondLast;
    String tailDirection = '';

    if (diff == 1) {
      tailDirection = 'right';
    } else if (diff == -1) {
      tailDirection = 'left';
    } else if (diff == squaresPerRow) {
      tailDirection = 'down';
    } else if (diff == -squaresPerRow) {
      tailDirection = 'up';
    }

    // 根据尾部方向进行旋转
    if (tailDirection == 'up') {
      return 'up'; // 旋转180度
    } else if (tailDirection == 'down') {
      return 'down'; // 不旋转
    } else if (tailDirection == 'left') {
      return 'right'; // 向右旋转90度
    } else if (tailDirection == 'right') {
      return 'left'; // 向左旋转90度
    }
    return ''; // 默认返回值
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

  // 根据屏幕尺寸动态设置网格的维度，保证充满整个屏幕
  void _updateGridDimensions() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // 设定每个方格的最小宽高
    const double gridSize = 24.0; // 每个方格的大小

    // 计算每行和每列能容纳的方格数
    squaresPerRow = (screenWidth / gridSize).floor();
    squaresPerCol = (screenHeight / gridSize).floor();

    // 如果屏幕方向是横屏，调整网格方向
    if (screenWidth > screenHeight) {
      // 横屏：确保每行的方格数量多，列数少
      squaresPerRow = (screenWidth / gridSize).floor();
      squaresPerCol = (screenHeight / gridSize).floor();
    } else {
      // 竖屏：确保每列的方格数量多，行数少
      squaresPerRow = (screenWidth / gridSize).floor();
      squaresPerCol = (screenHeight / gridSize).floor();
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
                return SnakeHead(direction: direction); // 蛇头
              } else if (index == snake.last) {
                return SnakeTail(tailDir: tailDir); // 蛇尾
              } else {
                return const SnakeBody(); // 蛇身
              }
            }
            // 食物
            if (index == food) {
              return Padding(
                padding: const EdgeInsets.all(0.8),
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

class SnakeBody extends StatelessWidget {
  const SnakeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: Container(color: Colors.green[500]),
      ),
    );
  }
}

class SnakeHead extends StatelessWidget {
  const SnakeHead({super.key, required this.direction});

  final String direction; // 方向参数，控制蛇头旋转

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
      padding: const EdgeInsets.all(0.8),
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
                      top: -2.0,
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
                      top: -2.0,
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
              top: -12.5,
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

class SnakeTail extends StatelessWidget {
  const SnakeTail({super.key, required this.tailDir});

  final String tailDir;

  @override
  Widget build(BuildContext context) {
    // 定义旋转角度
    double rotationAngle;
    switch (tailDir) {
      case 'up':
        rotationAngle = 0.0;
        break;
      case 'down':
        rotationAngle = pi;
        break;
      case 'left':
        rotationAngle = pi / 2;
        break;
      case 'right':
        rotationAngle = -pi / 2;
        break;
      default:
        rotationAngle = 0.0;
    }

    return Transform.rotate(
      angle: rotationAngle,
      child: CustomPaint(
        painter: RoundedTrianglePainter(),
      ),
    );
  }
}

class RoundedTrianglePainter extends CustomPainter {
  double distanceFactor = 0.2;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.green[500]!
      ..style = PaintingStyle.fill;

    Point p1 = Point(size.width / 2, 0);
    Point p2 = Point(0, size.width);
    Point p3 = Point(size.width, size.width);

    Point p1p2Start = getLinePoint(p1, p2, closeToStart: true);
    Point p1p2End = getLinePoint(p1, p2, closeToStart: false);

    Point p2p3Start = getLinePoint(p2, p3, closeToStart: true);
    Point p2p3End = getLinePoint(p2, p3, closeToStart: false);

    Point p3p1Start = getLinePoint(p3, p1, closeToStart: true);
    Point p3p1End = getLinePoint(p3, p1, closeToStart: false);

    canvas.drawPath(
      Path()
        ..moveTo(
          p1p2Start.x.toDouble(),
          p1p2Start.y.toDouble(),
        )
        ..lineTo(
          p1p2End.x.toDouble(),
          p1p2End.y.toDouble(),
        )
        ..quadraticBezierTo(
          p2.x.toDouble(),
          p2.y.toDouble(),
          p2p3Start.x.toDouble(),
          p2p3Start.y.toDouble(),
        )
        ..lineTo(
          p2p3End.x.toDouble(),
          p2p3End.y.toDouble(),
        )
        ..quadraticBezierTo(
          p3.x.toDouble(),
          p3.y.toDouble(),
          p3p1Start.x.toDouble(),
          p3p1Start.y.toDouble(),
        )
        ..lineTo(
          p3p1End.x.toDouble(),
          p3p1End.y.toDouble(),
        )
        ..quadraticBezierTo(
          p1.x.toDouble(),
          p1.y.toDouble(),
          p1p2Start.x.toDouble(),
          p1p2Start.y.toDouble(),
        ),
      paint,
    );
  }

  Point getLinePoint(Point start, Point end, {required bool closeToStart}) {
    final double correctedDistanceFactor = closeToStart ? distanceFactor : (1 - distanceFactor);
    int x = (start.x * (1 - correctedDistanceFactor) + end.x * correctedDistanceFactor).round();
    int y = (start.y * (1 - correctedDistanceFactor) + end.y * correctedDistanceFactor).round();
    return Point(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
