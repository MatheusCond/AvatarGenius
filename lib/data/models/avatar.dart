/// Um avatar salvo: a caricatura gerada e a personalidade do personagem.
///
/// A imagem fica num armazenamento separado ([ImageStore]); aqui só vão os
/// metadados, para a listagem ser rápida.
class Avatar {
  const Avatar({
    required this.id,
    required this.name,
    required this.personality,
    required this.createdAt,
  });

  factory Avatar.fromJson(Map<String, Object?> json) {
    return Avatar(
      id: json['id']! as String,
      name: json['name']! as String,
      personality: json['personality']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }

  final String id;
  final String name;
  final String personality;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'personality': personality,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is Avatar &&
      other.id == id &&
      other.name == name &&
      other.personality == personality &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, personality, createdAt);
}
