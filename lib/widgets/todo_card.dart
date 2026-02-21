import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

class TodoCard extends StatefulWidget {
  final Todo todo;
  final VoidCallback? onToggle; // 完了トグル用コールバック（任意）

  const TodoCard({super.key, required this.todo, this.onToggle});

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant TodoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todo.urgency != widget.todo.urgency) {
      _syncPulse();
    }
  }

  /// 緊急度に合わせてパルスアニメーションを開始／停止する
  void _syncPulse() {
    if (widget.todo.urgency == Urgency.urgent) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// 緊急度に応じたグラデーションカラー
  List<Color> get _gradientColors {
    switch (widget.todo.urgency) {
      case Urgency.urgent:
        // 炎上：オレンジ→赤の鮮やかなグラデーション
        return [const Color(0xFFFF6B35), const Color(0xFFD32F2F)];
      case Urgency.caution:
        // 注意：琥珀→オレンジ
        return [const Color(0xFFFFC107), const Color(0xFFEF6C00)];
      case Urgency.calm:
        // 落ち着き：明るい青→深いインディゴ
        return [const Color(0xFF42A5F5), const Color(0xFF283593)];
    }
  }

  Color get _shadowColor => _gradientColors.last.withValues(alpha: 0.45);

  Widget _buildCardBody() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 左端：チェックアイコン
          IconButton(
            iconSize: 32,
            icon: Icon(
              widget.todo.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: Colors.white,
            ),
            onPressed: widget.onToggle,
          ),
          const SizedBox(width: 8),
          // ── テキスト群
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.todo.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.todo.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('M月d日(E)', 'ja').format(widget.todo.dueDate),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 緊急度バッジ
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.todo.urgencyLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 炎上状態のみパルスアニメーションを適用
    if (widget.todo.urgency == Urgency.urgent) {
      return ScaleTransition(scale: _pulseScale, child: _buildCardBody());
    }
    return _buildCardBody();
  }
}
