import '../adapter/architecture_adapter.dart';

/// A component in the Codrel registry.
class CliComponent {
  /// Unique slug, used with `codrel add <id>`.
  final String id;

  /// Display name.
  final String name;

  /// File name the component is written to, e.g. `swipe_card_deck.dart`.
  final String fileName;

  /// Short summary of the interaction.
  final String description;

  /// Difficulty tier: `Beginner`, `Intermediate` or `Advanced`.
  final String complexity;

  /// Filter tags such as `gestures` or `physics`.
  final List<String> tags;

  /// Number of installs through the CLI.
  final int downloadsCount;

  /// Vanilla Flutter source code.
  final String codeTemplate;

  /// When the component was added to the registry.
  final DateTime? createdAt;

  /// Compile-verified architecture variants keyed by [Architecture.flag].
  final Map<String, String> architectureTemplates;

  /// Creates a component description.
  const CliComponent({
    required this.id,
    required this.name,
    required this.fileName,
    required this.description,
    this.complexity = 'Intermediate',
    this.tags = const [],
    this.downloadsCount = 0,
    required this.codeTemplate,
    this.createdAt,
    this.architectureTemplates = const {},
  });

  /// Alias of [id].
  String get slug => id;

  /// Alias of [name].
  String get title => name;

  /// Parses a registry row.
  factory CliComponent.fromJson(Map<String, dynamic> json) {
    final componentId = (json['id'] ?? json['slug']) as String;
    return CliComponent(
      id: componentId,
      name: (json['name'] ?? json['title']) as String,
      fileName: (json['file_name'] ?? json['fileName']) as String? ??
          '${componentId.replaceAll('-', '_')}.dart',
      description: json['description'] as String? ?? '',
      complexity: json['complexity'] as String? ?? 'Intermediate',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      downloadsCount:
          ((json['downloads_count'] ?? json['downloadsCount']) as num?)
                  ?.toInt() ??
              0,
      codeTemplate:
          (json['code_template'] ?? json['codeTemplate']) as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null),
      architectureTemplates: {
        for (final entry
            in ((json['architecture_templates'] as Map?) ?? const {}).entries)
          if (entry.value is String)
            entry.key.toString(): entry.value as String,
      },
    );
  }

  /// Serializes to the registry row format.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'file_name': fileName,
        'description': description,
        'complexity': complexity,
        'tags': tags,
        'downloads_count': downloadsCount,
        'code_template': codeTemplate,
        'created_at': createdAt?.toIso8601String(),
      };
}
