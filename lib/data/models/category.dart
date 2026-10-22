/// Expense category. Base categories have a null [userId].
class Category {
  const Category({
    this.id,
    this.userId,
    required this.name,
    required this.icon,
    required this.color,
  });

  final int? id;
  final int? userId;
  final String name;

  /// Icon key, resolved to a Material icon by the UI.
  final String icon;
  final int color;

  bool get isBase => userId == null;

  factory Category.fromMap(Map<String, Object?> m) => Category(
    id: m['id'] as int?,
    userId: m['user_id'] as int?,
    name: m['name'] as String,
    icon: m['icon'] as String,
    color: m['color'] as int,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name,
    'icon': icon,
    'color': color,
  };

  Category copyWith({int? id, String? name, String? icon, int? color}) =>
      Category(
        id: id ?? this.id,
        userId: userId,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
      );
}
