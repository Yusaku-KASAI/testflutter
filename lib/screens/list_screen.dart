import 'package:flutter/material.dart';

import '../widgets/todo_list.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  ListScreenState createState() => ListScreenState();
}

class ListScreenState extends State<ListScreen> {
  // TodoList の状態を操作するためのキー
  final GlobalKey<TodoListState> _todoListKey = GlobalKey<TodoListState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TODOリスト')),
      body: TodoList(key: _todoListKey), // TodoList ウィジェットを配置
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // 画面遷移については次の章で実装します
        backgroundColor: const Color.fromARGB(
          255,
          0,
          0,
          255,
        ), // ボタンの背景色（RGBAでも指定できます）
        foregroundColor: Colors.white, // アイコンやテキストなど、ボタン内の要素の色
        child: const Icon(Icons.add), // Flutter標準の「＋」アイコン
      ),
    );
  }
}
