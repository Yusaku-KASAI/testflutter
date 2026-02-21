import 'package:flutter/material.dart';
import '../screens/add_todo_screen.dart';

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
        onPressed: () async {
          // 画面遷移し、戻ってきたら結果（新規 Todo）を受け取る
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTodoScreen()),
          );

          // 返却されたデータが Todo であればリストへ追加
          if (result != null) {
            // 後々使うので一旦コメントアウト
            // _todoListKey.currentState?.addTodo(result);
          }
        }, // 画面遷移については次の章で実装します
        backgroundColor: const Color.fromARGB(
          255,
          0,
          0,
          255,
        ), // ボタン色（RGBAでも指定できます）
        foregroundColor: Colors.white,
        child: const Icon(Icons.add), // Flutter標準の「＋」アイコン
      ),
    );
  }
}
