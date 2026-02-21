import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/todo.dart';
import '../services/todo_service.dart';
import 'todo_card.dart';

class TodoList extends StatefulWidget {
  const TodoList({super.key, required this.todoService});

  final TodoService todoService;

  @override
  State<TodoList> createState() => TodoListState();
}

class TodoListState extends State<TodoList> {
  List<Todo> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final todos = await widget.todoService.getTodos();
    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

  /// 追加画面から呼ばれる（後方互換性のために残す）
  void addTodo(Todo newTodo) async {
    setState(() => _todos.add(newTodo));
    await widget.todoService.saveTodos(_todos);
  }

  /// タスクを完了済みにしてリストから削除し、永続化する
  Future<void> _completeTodo(String id) async {
    setState(() => _todos.removeWhere((t) => t.id == id));
    await widget.todoService.saveTodos(_todos);
  }

  /// タスクの期限を指定日数だけ延長し、永続化する
  Future<void> _extendTodo(String id, int days) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final updated = _todos[index].copyWith(
      dueDate: _todos[index].dueDate.add(Duration(days: days)),
    );
    setState(() => _todos[index] = updated);
    await widget.todoService.saveTodos(_todos);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todos.isEmpty) {
      return const Center(
        child: Text(
          'タスクがありません\n＋ボタンで追加しましょう',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _todos.length,
      itemBuilder: (context, index) {
        final todo = _todos[index];
        return _SwipeableCardItem(
          key: ValueKey(todo.id),
          todo: todo,
          onComplete: () => _completeTodo(todo.id),
          onExtend: (days) => _extendTodo(todo.id, days),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// カスタムスワイプ対応のカードラッパー
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeableCardItem extends StatefulWidget {
  final Todo todo;
  final VoidCallback onComplete;
  final ValueChanged<int> onExtend; // 延長する日数

  const _SwipeableCardItem({
    super.key,
    required this.todo,
    required this.onComplete,
    required this.onExtend,
  });

  @override
  State<_SwipeableCardItem> createState() => _SwipeableCardItemState();
}

class _SwipeableCardItemState extends State<_SwipeableCardItem>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isDismissing = false;
  bool _isDraggingLeft = false;

  late final AnimationController _dismissController;

  // ── 経過時間管理 ────────────────────────────────
  final Stopwatch _dragStopwatch = Stopwatch();
  Timer? _updateTimer;
  int _extendDays = 0;

  // ── スワイプ閾値 ────────────────────────────────
  /// 右スワイプで完了が発火するドラッグ距離 (px)
  static const double _completeTrigger = 80.0;
  /// 左スワイプで延長が発火するドラッグ距離 (px)
  static const double _extendTrigger = 50.0;
  /// 高速スワイプと判定する速度 (px/s)
  static const double _fastVelocity = 600.0;

  // ── レイアウト定数 ──────────────────────────────
  static const double _cardHeight = 150.0;
  static const double _vertPadding = 8.0;
  static const double _itemHeight = _cardHeight + _vertPadding;

  // ── 円弧軌道パラメータ ───────────────────────────
  /// 仮想円の半径（カード下方の中心からの距離）
  static const double _arcRadius = 600.0;
  /// 最大回転角度（度）
  static const double _maxAngleDeg = 18.0;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _dismissController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  // ── ドラッグハンドラ ───────────────────────────

  void _onDragStart(DragStartDetails details) {
    if (_isDismissing) return;
    _dragStopwatch.reset();
    _extendDays = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    setState(() {
      _dragOffset += details.delta.dx;

      // 左スワイプ開始を検出してタイマー開始
      if (_dragOffset < -10 && !_isDraggingLeft) {
        _isDraggingLeft = true;
        _dragStopwatch.start();
        _startExtendTimer();
      }

      // 左スワイプ終了（右方向に戻った場合）
      if (_dragOffset >= -10 && _isDraggingLeft) {
        _isDraggingLeft = false;
        _dragStopwatch.stop();
        _updateTimer?.cancel();
        _extendDays = 0;
      }
    });
  }

  void _startExtendTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isDraggingLeft) return;
      final seconds = _dragStopwatch.elapsedMilliseconds / 1000.0;
      final newDays = (seconds.ceil()).clamp(1, 7);
      if (newDays != _extendDays) {
        HapticFeedback.selectionClick();
        setState(() => _extendDays = newDays);
      }
    });
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_isDismissing) return;

    _dragStopwatch.stop();
    _updateTimer?.cancel();
    _isDraggingLeft = false;

    final velocity = details.primaryVelocity ?? 0;

    // 右スワイプ → 完了
    if (_dragOffset > _completeTrigger ||
        (_dragOffset > 20 && velocity > _fastVelocity)) {
      await HapticFeedback.mediumImpact();
      setState(() => _isDismissing = true);
      await _dismissController.forward();
      if (mounted) widget.onComplete();
      return;
    }

    // 左スワイプ → 期限延長
    if (_dragOffset < -_extendTrigger && _extendDays > 0) {
      await HapticFeedback.mediumImpact();
      final days = _extendDays;
      setState(() {
        _dragOffset = 0;
        _extendDays = 0;
      });
      widget.onExtend(days);
      return;
    }

    // 閾値未満 → 元に戻す
    setState(() {
      _dragOffset = 0;
      _extendDays = 0;
    });
  }

  // ── 円弧軌道の座標計算 ─────────────────────────

  Offset _calculateArcOffset(double dragX, double screenWidth) {
    // ドラッグ量を正規化（-1.0 〜 +1.0）
    final normalizedDrag = (dragX / screenWidth).clamp(-1.0, 1.0);

    // 最大角度をラジアンに変換
    final maxAngleRad = _maxAngleDeg * (pi / 180);

    // 現在の回転角度
    final angle = normalizedDrag * maxAngleRad;

    // 円弧上の新しい座標を計算
    // x = sin(angle) * radius
    // y = radius - cos(angle) * radius = radius * (1 - cos(angle))
    final newX = sin(angle) * _arcRadius;
    final newY = _arcRadius * (1 - cos(angle));

    return Offset(newX, newY);
  }

  // ── ビルド ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _dismissController,
      builder: (context, _) {
        final p = _dismissController.value;

        // 完了アニメーション中の座標計算
        final double animatedDragOffset =
            _isDismissing ? _dragOffset + (screenW * 1.3) * p : _dragOffset;

        final arcOffset = _calculateArcOffset(animatedDragOffset, screenW);

        final double itemHeight =
            _isDismissing ? _itemHeight * (1.0 - p) : _itemHeight;
        final double opacity =
            _isDismissing ? (1.0 - p).clamp(0.0, 1.0) : 1.0;

        // スワイプ方向と背景の決定
        final bool swipingRight = _dragOffset > 5;
        final bool swipingLeft = _dragOffset < -5 && !_isDismissing;

        String revealLabel = '';
        Color revealColor = Colors.green.shade500;
        if (swipingRight) {
          revealLabel = '完了 ✓';
          revealColor = Colors.green.shade500;
        } else if (swipingLeft) {
          revealLabel = '';  // 左スワイプ時は円形ゲージで表示
          revealColor = _getExtendColor(_extendDays);
        }

        return GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: ClipRect(
            child: SizedBox(
              height: itemHeight,
              child: Opacity(
                opacity: opacity,
                child: Stack(
                  children: [
                    // カード本体
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      child: SizedBox(
                        height: _cardHeight,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // アクションラベル背景
                            if (revealLabel.isNotEmpty)
                              Positioned.fill(
                                child: _RevealBackground(
                                  color: revealColor,
                                  label: revealLabel,
                                  alignRight: !swipingRight,
                                ),
                              ),
                            // 左スワイプ時の背景（色のみ表示）
                            if (swipingLeft)
                              Positioned.fill(
                                child: _RevealBackground(
                                  color: revealColor,
                                  label: '',
                                  alignRight: true,
                                ),
                              ),
                            // ドラッグされるカード本体（円弧軌道）
                            Transform(
                              transform: Matrix4.translationValues(arcOffset.dx, arcOffset.dy, 0)
                                ..rotateZ(_calculateRotation(animatedDragOffset, screenW)),
                              alignment: Alignment.bottomCenter,
                              child: TodoCard(todo: widget.todo),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 円形ゲージオーバーレイ
                    if (swipingLeft && _extendDays > 0)
                      _CircularGaugeOverlay(
                        days: _extendDays,
                        progress: _extendDays / 7.0,
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

  double _calculateRotation(double dragX, double screenWidth) {
    final normalizedDrag = (dragX / screenWidth).clamp(-1.0, 1.0);
    final maxAngleRad = _maxAngleDeg * (pi / 180);
    return normalizedDrag * maxAngleRad;
  }

  Color _getExtendColor(int days) {
    if (days <= 2) return Colors.blue.shade500;
    if (days <= 4) return Colors.green.shade500;
    if (days <= 6) return Colors.orange.shade500;
    return Colors.red.shade500;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 円形ゲージオーバーレイ
// ─────────────────────────────────────────────────────────────────────────────

class _CircularGaugeOverlay extends StatelessWidget {
  final int days;
  final double progress; // 0.0 〜 1.0

  const _CircularGaugeOverlay({
    required this.days,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: 1.0,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              painter: _CircularGaugePainter(
                progress: progress,
                color: _getGaugeColor(days),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+$days',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      days == 7 ? '週間' : '日',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getGaugeColor(int days) {
    if (days <= 2) return Colors.blue.shade400;
    if (days <= 4) return Colors.green.shade400;
    if (days <= 6) return Colors.orange.shade400;
    return Colors.red.shade400;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 円形ゲージのカスタムペインター
// ─────────────────────────────────────────────────────────────────────────────

class _CircularGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularGaugePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    // 背景の円弧（グレー）
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // プログレスの円弧
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // 上から開始
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// アクション名を表示する背景ウィジェット
// ─────────────────────────────────────────────────────────────────────────────

class _RevealBackground extends StatelessWidget {
  final Color color;
  final String label;
  final bool alignRight; // true → ラベルを右寄せ（左スワイプ時）

  const _RevealBackground({
    required this.color,
    required this.label,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: label.isNotEmpty
          ? Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
