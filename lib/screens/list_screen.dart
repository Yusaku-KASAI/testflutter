import 'package:flutter/material.dart';
import '../widgets/todo_list.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  ListScreenState createState() => ListScreenState();
}

class ListScreenState extends State<ListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TODOリスト')),
      body: TodoList(), // TodoList ウィジェットを配置
    );
  }
}
