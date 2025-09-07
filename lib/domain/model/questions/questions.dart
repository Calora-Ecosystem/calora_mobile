class QuestionsModel {
  final String? name;
  final String? gender;
  final List<int>? purposeIds;
  final DateTime? birthDate;
  final double? height;
  final double? weight;
  final double? bmi;
  final double? targetWeight;
  final String? activityHours;
  final String? photo;
  final String? language;

  const QuestionsModel({
    this.name,
    this.gender,
    this.purposeIds,
    this.birthDate,
    this.height,
    this.weight,
    this.bmi,
    this.targetWeight,
    this.activityHours,
    this.photo,
    this.language,
  });

  QuestionsModel copyWith({
    String? name,
    String? gender,
    List<int>? purposeIds,
    DateTime? birthDate,
    double? height,
    double? weight,
    double? bmi,
    double? targetWeight,
    String? activityHours,
    String? photo,
    String? language,
  }) {
    return QuestionsModel(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      purposeIds: purposeIds ?? this.purposeIds,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      targetWeight: targetWeight ?? this.targetWeight,
      activityHours: activityHours ?? this.activityHours,
      photo: photo ?? this.photo,
      language: language ?? this.language,
    );
  }

  /// fromJson
  factory QuestionsModel.fromJson(Map<String, dynamic> json) {
    return QuestionsModel(
      name: json['name'] as String,
      gender: json['gender'] as String,
      purposeIds: (json['purposeIds'] as List<dynamic>).map((e) => e as int).toList(),
      birthDate: DateTime.parse(json['birthDate'] as String),
      height: (json['height'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      bmi: (json['bmi'] as num).toDouble(),
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      activityHours: json['activityHours'] as String?,
      photo: json['photo'] as String,
      language: json['language'] as String,
    );
  }

  /// toJson
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'purposeIds': purposeIds,
      'birthDate': birthDate?.toIso8601String(),
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'targetWeight': targetWeight,
      'activityHours': activityHours,
      'photo': photo,
      'language': language,
    };
  }

  @override
  String toString() {
    return 'Questions(name: $name, gender: $gender, purposeIds: $purposeIds, '
        'birthDate: $birthDate, height: $height, weight: $weight, bmi: $bmi, '
        'targetWeight: $targetWeight, activityHours: $activityHours, '
        'photo: $photo, language: $language)';
  }
}
