import 'package:flutter/material.dart';

import '../models/todo.dart';

class AddTodoScreen extends StatefulWidget {
  const AddTodoScreen({super.key});

  @override
  AddTodoScreenState createState() => AddTodoScreenState();
}

class AddTodoScreenState extends State<AddTodoScreen> {
  // controllerをTextFormFieldに渡して、入力値を取り出せるようにしよう
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _dateController =
      TextEditingController(); // 選んだ期日を表示する

  DateTime? _selectedDate; // DatePickerで選んだ期日（Todo作成に使う）

  // validate()で入力チェックを走らせるために使う
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isFormValid = false; // 全項目入力済みならtrue→作成ボタンを押せるようにする

  @override
  void initState() {
    super.initState();
    // 入力が変わったら、ボタンの活性/非活性を更新しよう
    _titleController.addListener(_updateFormValid);
    _detailController.addListener(_updateFormValid);
    _dateController.addListener(_updateFormValid);
  }

  // タイトル・詳細・期日が揃ったら、作成ボタンを押せるようにしよう
  void _updateFormValid() {
    setState(() {
      _isFormValid =
          _titleController.text.isNotEmpty &&
          _detailController.text.isNotEmpty &&
          _selectedDate != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新しいタスクを追加')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // validate()でまとめて入力チェックできるように、Formにkeyを渡そう
          child: Column(
            children: [
              // タイトル：controllerで入力値を取り、validatorで未入力を弾こう
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タスクのタイトル',
                  hintText: '20文字以内で入力してください',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // 入力チェック
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  } else if (value.length > 20) {
                    return '20文字以内で入力してください';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 詳細：未入力チェックを入れて必須にしよう
              TextFormField(
                controller: _detailController,
                decoration: const InputDecoration(
                  labelText: 'タスクの詳細',
                  hintText: '3行以内で入力してください',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  // 入力チェック
                  if (value == null || value.isEmpty) {
                    return '詳細を入力してください';
                  } else if (value.split('\n').length > 3) {
                    return '3行以内で入力してください';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 期日：タップしたらDatePickerを開き、選んだ日付を表示＆保持しよう
              TextFormField(
                controller: _dateController,
                readOnly: true, // 直接入力ではなくDatePickerで選ばせよう
                decoration: const InputDecoration(
                  labelText: '期日',
                  hintText: '年/月/日',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  // 日付選択ダイアログを開く
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    // 選択した日付をコントローラに反映
                    _selectedDate = picked;
                    _dateController.text =
                        '${picked.year}/${picked.month}/${picked.day}';

                    // 期日を選んだあともフォーム状態を再評価
                    _updateFormValid();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '期日を選択してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 全項目が揃っているときだけ、作成ボタンを押せるようにしよう
              ElevatedButton(
                onPressed: _isFormValid ? _saveTodo : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid
                      ? const Color.fromARGB(255, 0, 0, 255)
                      : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'タスクを追加',
                  style: TextStyle(
                    color: _isFormValid ? Colors.white : Colors.grey,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 入力チェック→Todo生成→前の画面へ返す、の流れを作ろう
  void _saveTodo() {
    if (_formKey.currentState!.validate()) {
      Todo newTodo = Todo(
        title: _titleController.text,
        detail: _detailController.text,
        dueDate: _selectedDate!,
      );

      // 作成したTodoを戻り値として渡そう（前画面で受け取れる）
      Navigator.pop(context, newTodo);
    }
  }

  @override
  void dispose() {
    // 画面を閉じるときにcontrollerを破棄して、メモリリークを防ごう
    _titleController.dispose();
    _detailController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初期表示でもボタン状態が合うように、最初に一度評価しておこう
    _updateFormValid();
  }
}
