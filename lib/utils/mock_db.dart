class MockDB {
  static final Map<String, Map<String, dynamic>> users = {
    'admin': {
      'password': 'admin',
      'prenom': 'Admin',
      'nom': 'System',
      'isValidated': true,
    },
    'test': {
      'password': 'test1234',
      'prenom': 'Test',
      'nom': 'Utilisateur',
      'isValidated': true,
    }
  };
}