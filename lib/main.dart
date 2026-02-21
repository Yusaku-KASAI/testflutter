import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/list_screen.dart';
import 'services/todo_service.dart';

void main() async {
  // Flutter のプラグイン初期化。非同期処理を行う場合は必須
  WidgetsFlutterBinding.ensureInitialized();

  // TodoCard内で DateFormat(..., 'ja') を使うので、起動時に一度だけ初期化しよう
  await initializeDateFormatting('ja'); // 英語表記なら "en" など

  // ① 端末保存（SharedPreferences）を使えるようにしよう
  final prefs = await SharedPreferences.getInstance();

  // ② prefs を渡して TodoService を作り、保存/読み込みの窓口を1つにまとめよう
  final todoService = TodoService(prefs);

  // ③ todoService をアプリ全体へ渡して、どの画面からでも使えるようにしよう
  runApp(MyApp(todoService: todoService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.todoService});

  // アプリ全体で共有する TodoService
  final TodoService todoService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ListScreen にtodoServiceを引数としてわたす
      home: ListScreen(todoService: todoService),
    );
  }
}
