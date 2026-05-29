class PasswordEntity {
  final String id;
  final String title;
  final String username;
  final String password;
  final String? website;
  final String? notes;
  final DateTime createdAt;

  const PasswordEntity({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.website,
    this.notes,
    required this.createdAt,
  });

  PasswordEntity copyWith({
    String? title,
    String? username,
    String? password,
    String? website,
    String? notes,
  }) =>
      PasswordEntity(
        id: id,
        title: title ?? this.title,
        username: username ?? this.username,
        password: password ?? this.password,
        website: website ?? this.website,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}
