import 'package:flutter/material.dart';

class AddTodoScreen extends StatefulWidget {
  const AddTodoScreen({super.key});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBarのtitleに「新しいタスクを追加」を設定して、画面の役割が分かるようにしよう
      appBar: AppBar(title: const Text('新しいタスクを追加')),
      body: const Center(child: Text('ここにフォームを作成していきます')), // 仮置き
    );
  }
}
