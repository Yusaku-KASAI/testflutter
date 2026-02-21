import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // 日本語などロケール情報を読み込む
import 'screens/list_screen.dart';

void main() async {
  // DateFormat で日本語表記を使えるようロケールを初期化
  await initializeDateFormatting('ja'); // 他言語の場合は"en"などに変更
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ListScreen());
  }
}
