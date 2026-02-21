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

  late final AnimationController _dismissController;

  // ── スワイプ閾値 ────────────────────────────────
  /// 右スワイプで完了が発火するドラッグ距離 (px)
  static const double _completeTrigger = 80.0;
  /// 左スワイプで延長が発火するドラッグ距離 (px)
  static const double _extendTrigger = 70.0;
  /// +1週間プレビューに切り替わる左ドラッグ距離 (px)
  static const double _weekModeDistance = 130.0;
  /// 高速スワイプと判定する速度 (px/s)
  static const double _fastVelocity = 600.0;

  // ── レイアウト定数 ──────────────────────────────
  static const double _cardHeight = 150.0;
  static const double _vertPadding = 8.0; // 上下 4px ずつ
  static const double _progressBarHeight = 10.0;
  static const double _itemHeight =
      _cardHeight + _vertPadding + _progressBarHeight; // 168px

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
    super.dispose();
  }

  // ── ドラッグハンドラ ───────────────────────────

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    setState(() => _dragOffset += details.delta.dx);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_isDismissing) return;
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
    if (_dragOffset < -_extendTrigger) {
      await HapticFeedback.mediumImpact();
      // 速度で +1日 / +1週間 を決定（速い = スナッチ = +1日、遅い = +1週間）
      final days = velocity.abs() > _fastVelocity ? 1 : 7;
      setState(() => _dragOffset = 0);
      widget.onExtend(days);
      return;
    }

    // 閾値未満 → 元に戻す
    setState(() => _dragOffset = 0);
  }

  // ── ビルド ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dismissController,
      builder: (context, _) {
        final p = _dismissController.value;
        final screenW = MediaQuery.of(context).size.width;

        // 完了アニメーション中：カードを右へ飛ばしながら高さを縮める
        final double slideOffset =
            _isDismissing ? _dragOffset + (screenW * 1.3) * p : _dragOffset;
        final double itemHeight =
            _isDismissing ? _itemHeight * (1.0 - p) : _itemHeight;
        final double opacity =
            _isDismissing ? (1.0 - p).clamp(0.0, 1.0) : 1.0;

        // スワイプ方向と背景の決定
        final bool swipingRight = slideOffset > 5;
        final bool swipingLeft = slideOffset < -5 && !_isDismissing;
        final bool weekMode = -slideOffset >= _weekModeDistance;

        String revealLabel = '';
        Color revealColor = Colors.green.shade500;
        if (swipingRight) {
          revealLabel = '完了 ✓';
          revealColor = Colors.green.shade500;
        } else if (swipingLeft) {
          revealLabel = weekMode ? '+1週間延長' : '+1日延長';
          revealColor =
              weekMode ? Colors.teal.shade600 : Colors.blue.shade500;
        }

        return GestureDetector(
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: ClipRect(
            child: SizedBox(
              height: itemHeight,
              child: Opacity(
                opacity: opacity,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  child: Column(
                    children: [
                      // ── カードエリア（背景ラベル ＋ スライドカード）──
                      SizedBox(
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
                            // ドラッグされるカード本体
                            Transform.translate(
                              offset: Offset(slideOffset, 0),
                              child: TodoCard(todo: widget.todo),
                            ),
                          ],
                        ),
                      ),
                      // ── 左スワイプ中の延長ゲージ ──
                      SizedBox(
                        height: _progressBarHeight,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 120),
                          opacity: swipingLeft ? 1.0 : 0.0,
                          child: _ExtendProgressBar(
                            dragDistance: -slideOffset,
                            isWeekMode: weekMode,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 左スワイプ中に表示する延長期間ゲージ
// ─────────────────────────────────────────────────────────────────────────────

class _ExtendProgressBar extends StatelessWidget {
  final double dragDistance; // ドラッグ距離（正の値）
  final bool isWeekMode; // +1週間モードかどうか

  const _ExtendProgressBar({
    required this.dragDistance,
    required this.isWeekMode,
  });

  @override
  Widget build(BuildContext context) {
    const double maxDist = 220.0;
    final double progress = dragDistance.clamp(0.0, maxDist) / maxDist;

    final Color fillColor =
        isWeekMode ? Colors.teal.shade500 : Colors.blue.shade500;
    final Color labelColor =
        isWeekMode ? Colors.teal.shade800 : Colors.blue.shade800;
    final String label = isWeekMode ? '+1週間' : '+1日';

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // トラック
          ClipRRect(
            borderRadius: BorderRadius.circular(3.5),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              minHeight: 7,
            ),
          ),
          // ラベル（バー上に白文字で重ねる）
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: progress > 0.3 ? Colors.white : labelColor,
              shadows: const [Shadow(color: Colors.black38, blurRadius: 2)],
            ),
          ),
        ],
      ),
    );
  }
}
