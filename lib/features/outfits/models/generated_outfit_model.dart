import 'package:cloud_firestore/cloud_firestore.dart';

class GeneratedOutfit {
  final String id;
  final String userId;
  final String topId;
  final String bottomId;
  final String topImageUrl;
  final String bottomImageUrl;
  final double score;
  final String explanation;
  final double temperature;
  final String weatherCondition;
  final bool isFavorited;
  final DateTime createdAt;

  GeneratedOutfit({
    required this.id,
    required this.userId,
    required this.topId,
    required this.bottomId,
    required this.topImageUrl,
    required this.bottomImageUrl,
    required this.score,
    required this.explanation,
    required this.temperature,
    required this.weatherCondition,
    this.isFavorited = false,
    required this.createdAt,
  });

  factory GeneratedOutfit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GeneratedOutfit(
      id: doc.id,
      userId: data['userId'] ?? '',
      topId: data['topId'] ?? '',
      bottomId: data['bottomId'] ?? '',
      topImageUrl: data['topImageUrl'] ?? '',
      bottomImageUrl: data['bottomImageUrl'] ?? '',
      score: (data['score'] ?? 0).toDouble(),
      explanation: data['explanation'] ?? '',
      temperature: (data['temperature'] ?? 20).toDouble(),
      weatherCondition: data['weatherCondition'] ?? 'Clear',
      isFavorited: data['isFavorited'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'topId': topId,
    'bottomId': bottomId,
    'topImageUrl': topImageUrl,
    'bottomImageUrl': bottomImageUrl,
    'score': score,
    'explanation': explanation,
    'temperature': temperature,
    'weatherCondition': weatherCondition,
    'isFavorited': isFavorited,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  GeneratedOutfit copyWith({
    String? id,
    String? userId,
    String? topId,
    String? bottomId,
    String? topImageUrl,
    String? bottomImageUrl,
    double? score,
    String? explanation,
    double? temperature,
    String? weatherCondition,
    bool? isFavorited,
    DateTime? createdAt,
  }) {
    return GeneratedOutfit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topId: topId ?? this.topId,
      bottomId: bottomId ?? this.bottomId,
      topImageUrl: topImageUrl ?? this.topImageUrl,
      bottomImageUrl: bottomImageUrl ?? this.bottomImageUrl,
      score: score ?? this.score,
      explanation: explanation ?? this.explanation,
      temperature: temperature ?? this.temperature,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      isFavorited: isFavorited ?? this.isFavorited,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
