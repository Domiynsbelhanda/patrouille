class Alerte {
  final int id;
  final String pseudo;
  final String telephone;
  final double latitude;
  final double longitude;
  final String status;
  final int patrouilleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Alerte({
    required this.id,
    required this.pseudo,
    required this.telephone,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.patrouilleId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor pour créer une instance d'Alerte à partir d'un objet JSON
  factory Alerte.fromJson(Map<String, dynamic> json) {
    return Alerte(
      id: json['id'],
      pseudo: json['pseudo'],
      telephone: json['telephone'],
      latitude: double.parse(json['latitude']),
      longitude: double.parse(json['longitude']),
      status: json['status'],
      patrouilleId: json['patrouille_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Méthode pour convertir l'objet en map, utile pour le debugging ou l'envoi de données
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pseudo': pseudo,
      'telephone': telephone,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'patrouille_id': patrouilleId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
