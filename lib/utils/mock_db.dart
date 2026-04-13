// lib/utils/mock_db.dart

class MockDB {
  // Notre fausse base de données stocke maintenant plus d'infos :
  // Le mot de passe, le nom, le prénom, et le statut de validation.
  static final Map<String, Map<String, dynamic>> users = {
    'admin': {
      'password': 'admin',
      'prenom': 'Admin',
      'nom': 'System',
      'isValidated': true, // Déjà validé
    },
    'test': {
      'password': 'test1234',
      'prenom': 'Test',
      'nom': 'Utilisateur',
      'isValidated': true, // Déjà validé
    }
  };
}