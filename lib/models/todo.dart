import 'package:uuid/uuid.dart'; // 一意なIDを生成するライブラリ

class Todo {
  final String id; // タスクを識別するためのID（同じタイトルでも区別できる）
  final String title; // タスクのタイトル（例：「レポートを書く」）
  final String detail; // タスクの詳細（例：「心理学のレポート、2000字」）
  final DateTime dueDate; // 期日（例：DateTime(2025, 4, 1)）
  final bool isCompleted; // チェック済みかどうか（true: 完了, false: 未完了）

  // コンストラクタ（TODOを作成する時の決まり）
  Todo({
    String? id, // IDが指定されない場合は自動生成
    required this.title, // タイトルは必須
    required this.detail, // 詳細も必須
    required this.dueDate, // 期日も必須
    this.isCompleted = false, // デフォルトは「未完了」
  }) : id = id ?? const Uuid().v4(); // IDの自動生成

  // 既存のTodoを一部変更したコピーを作成するメソッド
  Todo copyWith({
    String? title,
    String? detail,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return Todo(
      id: id, // idは引き継いで同一タスクとして扱う
      // 引数がnullなら元の値を使う（??）→ 必要なものだけ更新できる
      title: title ?? this.title,
      detail: detail ?? this.detail,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
