class CliComponent {
  final String id;
  final String name;
  final String fileName;
  final String description;
  final String complexity;
  final List<String> tags;
  final int downloadsCount;
  final String codeTemplate;
  final DateTime? createdAt;

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
  });

  String get slug => id;
  String get title => name;

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
    );
  }

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
