import '../data/drug_interaction_ar.dart';
import 'api_service.dart';
import 'auth_service.dart';


class DrugInteraction {
  final String ingredientA;
  final String ingredientB;
  final String severity; // minor | moderate | major | contraindicated
  final String description;
  final String recommendation;

  DrugInteraction({
    required this.ingredientA,
    required this.ingredientB,
    required this.severity,
    required this.description,
    required this.recommendation,
  });

  factory DrugInteraction.fromJson(Map<String, dynamic> json) {
    return DrugInteraction(
      ingredientA: (json['ingredient_a'] ?? '').toString(),
      ingredientB: (json['ingredient_b'] ?? '').toString(),
      severity: (json['severity'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      recommendation: (json['recommendation'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'ingredient_a': ingredientA,
        'ingredient_b': ingredientB,
        'severity': severity,
        'description': description,
        'recommendation': recommendation,
      };

  String get ingredientAAr => ingredientNameAr(ingredientA);
  String get ingredientBAr => ingredientNameAr(ingredientB);

  
  String get descriptionAr =>
      interactionTextAr(ingredientA, ingredientB)?.descriptionAr ?? description;

  
  String get recommendationAr =>
      interactionTextAr(ingredientA, ingredientB)?.recommendationAr ?? recommendation;

  int get severityOrder => severityRank(severity);
}


class DrugInteractionService {
  final AuthService _authService = AuthService();

  
  List<String> _resolveGenericNames(List<String> rawNames) {
    final resolved = <String>{};
    for (final raw in rawNames) {
      final matches = extractKnownIngredients(raw);
      if (matches.isNotEmpty) {
        resolved.addAll(matches);
      } else {
        final trimmed = raw.trim().toLowerCase();
        if (trimmed.isNotEmpty) resolved.add(trimmed);
      }
    }
    return resolved.toList();
  }


  Future<List<DrugInteraction>> checkInteractions(
      List<String> genericNames) async {
    final names = _resolveGenericNames(genericNames);

    if (names.length < 2) return [];

    final token = await _authService.getToken();

    final payload = await ApiService.postJson(
      '/interactions/check',
      body: {'generic_names': names},
      token: token,
    );

    final list = payload['interactions'] is List
        ? List<Map<String, dynamic>>.from(payload['interactions'])
        : <Map<String, dynamic>>[];

    final interactions = list.map((e) => DrugInteraction.fromJson(e)).toList();
    interactions.sort((a, b) => b.severityOrder.compareTo(a.severityOrder));
    return interactions;
  }

  
  Future<List<DrugInteraction>> checkNewMedication(
    String newMedName,
    List<String> existingMedNames,
  ) async {
    final others = existingMedNames
        .map((n) => n.trim())
        .where((n) =>
            n.isNotEmpty && n.toLowerCase() != newMedName.trim().toLowerCase())
        .toSet()
        .toList();

    if (others.isEmpty) return [];

    return checkInteractions([newMedName.trim(), ...others]);
  }
}