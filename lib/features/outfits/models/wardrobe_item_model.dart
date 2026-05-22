import 'package:cloud_firestore/cloud_firestore.dart';

enum WardrobeCategory {
  top,
  bottom,
}

enum WardrobeStyle {
  casual,
  formal,
  vintage,
  streetwear,
  minimalist,
}

class WardrobeItemModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String imageBase64;
  final WardrobeCategory category;
  final String color;
  final WardrobeStyle style;
  final DateTime createdAt;

  const WardrobeItemModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.imageBase64 = '',
    required this.category,
    required this.color,
    required this.style,
    required this.createdAt,
  });

  factory WardrobeItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'];
    return WardrobeItemModel(
      id: doc.id,
      userId: data['userId'] as String,
      imageUrl: data['imageUrl'] as String? ?? '',
      imageBase64: data['imageBase64'] as String? ?? '',
      category: WardrobeCategoryExtension.fromString(
        data['category']?.toString() ?? '',
      ),
      color: data['color'] as String? ?? '',
      style: WardrobeStyleExtension.fromString(
        data['style']?.toString() ?? '',
      ),
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse(createdAt?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'category': category.name,
      'color': color,
      'style': style.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  WardrobeItemModel copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? imageBase64,
    WardrobeCategory? category,
    String? color,
    WardrobeStyle? style,
    DateTime? createdAt,
  }) {
    return WardrobeItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      category: category ?? this.category,
      color: color ?? this.color,
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WardrobeItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

extension WardrobeCategoryExtension on WardrobeCategory {
  String get displayName {
    switch (this) {
      case WardrobeCategory.top:
        return 'Top';
      case WardrobeCategory.bottom:
        return 'Bottom';
    }
  }

  static WardrobeCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'top':
        return WardrobeCategory.top;
      case 'bottom':
        return WardrobeCategory.bottom;
      default:
        return WardrobeCategory.top;
    }
  }
}

extension WardrobeStyleExtension on WardrobeStyle {
  String get displayName {
    switch (this) {
      case WardrobeStyle.casual:
        return 'Casual';
      case WardrobeStyle.formal:
        return 'Formal';
      case WardrobeStyle.vintage:
        return 'Vintage';
      case WardrobeStyle.streetwear:
        return 'Streetwear';
      case WardrobeStyle.minimalist:
        return 'Minimalist';
    }
  }

  int get formalityValue {
    switch (this) {
      case WardrobeStyle.formal:
        return 9;
      case WardrobeStyle.vintage:
        return 6;
      case WardrobeStyle.minimalist:
        return 5;
      case WardrobeStyle.casual:
        return 4;
      case WardrobeStyle.streetwear:
        return 3;
    }
  }

  static WardrobeStyle fromString(String value) {
    switch (value.toLowerCase()) {
      case 'casual':
        return WardrobeStyle.casual;
      case 'formal':
        return WardrobeStyle.formal;
      case 'vintage':
        return WardrobeStyle.vintage;
      case 'streetwear':
        return WardrobeStyle.streetwear;
      case 'minimalist':
        return WardrobeStyle.minimalist;
      default:
        return WardrobeStyle.casual;
    }
  }
}
