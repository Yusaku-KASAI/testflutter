import 'package:uuid/uuid.dart';

/// タスクの緊急度を表す列挙型
enum Urgency {
  urgent, // 炎上状態：今日が期限 or 期限切れ
  caution, // 注意状態：3日以内
  calm, // 落ち着いた状態：余裕あり
}

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

  /// 期限に基づき緊急度を判定するゲッター
  Urgency get urgency {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;

    if (diff <= 0) return Urgency.urgent; // 今日 or 期限切れ → 炎上
    if (diff <= 3) return Urgency.caution; // 3日以内 → 注意
    return Urgency.calm; // 余裕あり → 落ち着いた
  }

  /// 緊急度の日本語ラベル
  String get urgencyLabel {
    switch (urgency) {
      case Urgency.urgent:
        return '炎上状態';
      case Urgency.caution:
        return '注意状態';
      case Urgency.calm:
        return '落ち着いた状態';
    }
  }

  // 既存のTodoを一部変更したコピーを作成するメソッド
  Todo copyWith({
    String? title,
    String? detail,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return Todo(
      id: id, // idは引き継いで同一タスクとして扱う
      title: title ?? this.title,
      detail: detail ?? this.detail,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
