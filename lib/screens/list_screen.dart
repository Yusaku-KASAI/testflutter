import 'package:flutter/material.dart';
import '../services/todo_service.dart';
import '../screens/add_todo_screen.dart';
import '../widgets/todo_list.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({
    super.key,
    // ❗️ 引数としてtodoServiceを受け取るようにしましょう（必須であることを示す required を忘れずに！）
    required this.todoService,
  });

  // ❗️ ListScreen で利用する TodoService を引数として受け取るために変数として定義しましょう
  final TodoService todoService;

  @override
  State<ListScreen> createState() => ListScreenState();
}

class ListScreenState extends State<ListScreen> {
  // ❗️ TodoList の状態を操作するための UniqueKey を変数として定義しましょう
  // ❗️ ここでは _todoListKey という名前で定義してみましょう
  Key _todoListKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TODOリスト')),
      body: TodoList(
        // ❗️ 作成した UniqueKey を引数として渡してみましょう
        key: _todoListKey,
        // ❗️ 続いて todoService を引数として渡してみましょう（widget.todoService は引数として受け取った todoService を参照するためのキーワードです）
        todoService: widget.todoService,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 画面遷移し、戻ってきたら結果（新規 Todo）を受け取る
          final updated = await Navigator.push(
            // ←追加　Todoに追加があったらtrueを返す
            context,
            MaterialPageRoute(
              builder: (context) => AddTodoScreen(
                // ❗️ ここでも AddTodoScreen でTodoが追加されたら状態を更新するため、todoService を引数として渡してみましょう
                todoService: widget.todoService,
              ),
            ),
          );

          // 追加があったら再描画（TodoList を再取得）  // ←追加
          if (updated == true) {
            setState(() {
              _todoListKey = UniqueKey(); // 新しいキーで TodoList を再構築
            });
          }
        },
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
