import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用パッケージ
import '../models/todo.dart';

class TodoCard extends StatelessWidget {
  final Todo todo; // 表示する Todo データ
  final VoidCallback? onToggle; // 完了トグル用コールバック（任意）
  const TodoCard({super.key, required this.todo, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: SizedBox(
        width: double.infinity, // コンポーネントの領域をスマホの横幅に合わせて横幅いっぱいに取る
        height: 150,
        child: Row(
          // ❗️ Rowクラスを使用してみましょう
          mainAxisAlignment: MainAxisAlignment.start, // add
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 左端：チェックアイコン（タップでトグル）
            IconButton(
              // ❗️ IconButtonクラスを使用してみましょう
              // add
              iconSize: 24,
              icon: const Icon(Icons.radio_button_unchecked),
              onPressed: () {
                onToggle!();
              },
            ),
            const SizedBox(width: 8),
            // ── テキスト群
            Expanded(
              // ↓Expandedを利用し、利用できる水平領域をすべて埋めるようにする
              child: Column(
                // ❗️ Columnクラスを使用してみましょう
                // add
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(todo.title),
                  SizedBox(height: 4),
                  Text(todo.detail),
                  SizedBox(height: 4),
                  Text(todo.dueDate.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
