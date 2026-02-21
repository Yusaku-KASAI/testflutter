import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // 日本語などロケール情報を読み込む
import 'screens/list_screen.dart';
import 'services/todo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Flutter のプラグイン初期化。非同期処理を行う場合は必須
  WidgetsFlutterBinding.ensureInitialized();

  // ❗️ SharedPreferences のインスタンスを作成してみましょう
  final prefs = await SharedPreferences.getInstance();

  // ❗️ 作成した prefs を引数として TodoService のインスタンスを作成してみましょう
  final todoService = TodoService(prefs);

  runApp(
    MyApp(
      // ❗️ 最後にMyAppへtodoServiceを引数として渡してみましょう
      todoService: todoService,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.todoService, // 引数として TodoService を受け取るようにします（required は引数として必須であることを示すキーワードです）
  });

  // アプリ全体で共有する TodoService を引数として受け取るために変数として定義します
  final TodoService todoService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ListScreen(
        // ❗️ ListScreen へ todoService を引数としてわたしてみましょう
        todoService: todoService,
      ),
    );
  }
}
