# Superviseur App 🏠📊

**Superviseur App** est une application mobile développée avec **Flutter** permettant de superviser et de gérer intelligemment la consommation d'énergie et les équipements d'un bâtiment ou d'une maison connectée.

L'application offre une interface intuitive pour visualiser les données en temps réel, consulter des statistiques détaillées par pièce et simuler des scénarios de consommation.

## 🚀 Fonctionnalités

- **Tableau de Bord en Temps Réel** : Visualisation globale de l'état de la maison.
- **Détails par Pièce** : Contrôle et monitoring spécifique pour chaque pièce configurée.
- **Statistiques & Graphiques** : Analyse de la consommation via des graphiques interactifs (propulsé par fl_chart).
- **Simulateur de Consommation** : Outil intégré pour estimer l'impact énergétique de différents équipements.
- **Notifications Locales** : Alertes en temps réel sur l'état du système.
- **Gestion du Profil** : Authentification sécurisée (Login/Signup) et personnalisation de l'utilisateur.
- **Logs de l'Activité** : Historique complet des événements du système.

## 🛠️ Stack Technique

- **Framework** : Flutter (Dart)
- **UI/UX** : 
  - fl_chart : Pour les rendus statistiques.
  - sleek_circular_slider : Curseurs circulaires pour le contrôle des équipements.
  - cupertino_icons : Design moderne.
- **Communication** :
  - http : Requêtes API REST.
  - web_socket_channel : Communication bidirectionnelle en temps réel.
- **Stockage local** : shared_preferences pour les réglages utilisateur.
- **Utilitaires** :
  - image_picker : Gestion des photos de profil.
  - flutter_local_notifications : Système de notifications.

## 📂 Structure du Projet
```
lib/  
  ├── models/      # Modèles de données (User, Room, Device, etc.)  
  ├── screens/     # Écrans de l'application (Home, Login, Stats, Simulator...)  
  ├── services/    # Logique de communication API et WebSockets  
  ├── utils/       # Fonctions d'aide et constantes  
  ├── widgets/     # Composants UI réutilisables  
  └── main.dart    # Point d'entrée de l'application  
```
## ⚙️ Installation

1. **Prérequis** :
   - Flutter SDK installé sur votre machine.
   - Un émulateur (Android/iOS) ou un appareil physique.

2. **Cloner le dépôt** :
   git clone https://github.com/JasonGagnard/superviseur_app.git
   cd superviseur_app

3. **Installer les dépendances** :
   flutter pub get

4. **Lancer l'application** :
   flutter run

## 📊 Composition du Code

- **Dart** : 76.3% (Cœur de l'application)
- **C++/CMake** : ~21% (Configurations natives)
- **Autres** : Swift, HTML, C (Supports plateformes)
