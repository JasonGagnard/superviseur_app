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


## BIBLIOTHÈQUE DES DÉPENDANCES FLUTTER (DICTIONNAIRE TECHNIQUE)

1. [INTERFACE UTILISATEUR & DESIGN (UI/UX)]
    fl_chart                     : Permet de générer des graphiques interactifs et esthétiques. 
                               Utilisé pour afficher les historiques de température ou 
                               les courbes du simulateur de consommation.
    sleek_circular_slider        : Composant visuel sous forme de jauge circulaire. Utilisé 
                               pour régler la température cible dans les scénarios de 
                               manière fluide et ergonomique.
    cupertino_icons              : Bibliothèque d'icônes par défaut d'Apple. Utilisée pour 
                               compléter les icônes "Material" et donner un rendu premium.

2. [COMMUNICATION RÉSEAU & IOT]
    http                         : Gestion des requêtes API REST (GET, POST). Indispensable 
                               pour communiquer avec des serveurs web classiques ou 
                               envoyer des ordres ponctuels aux ESP32.
    web_socket_channel           : Gestion des connexions bidirectionnelles en temps réel (ws://). 
                               Crucial pour recevoir le flux continu de la caméra thermique 
                               de l'ESP32 (port 81) sans surcharger le réseau.

3. [STOCKAGE LOCAL & SYSTÈME]
    shared_preferences           : Permet d'écrire des données légères directement sur le 
                               disque dur/mémoire de l'appareil (format clé-valeur). 
                               Utilisé pour sauvegarder la mémoire des ESP32, les pièces, 
                               les scénarios et le profil utilisateur après redémarrage.
    image_picker                 : Autorise l'application à accéder à la galerie photo ou à 
                               l'appareil photo natif du téléphone. Utilisé pour 
                               personnaliser l'avatar du profil utilisateur.
    flutter_local_notifications  : Interagit avec le centre de notifications du système 
                               d'exploitation (Android/iOS). Utilisé pour afficher les 
                               alertes critiques en temps réel (chutes/hausses de température).
## 📊 Composition du Code

- **Dart** : 76.3% (Cœur de l'application)
- **C++/CMake** : ~21% (Configurations natives)
- **Autres** : Swift, HTML, C (Supports plateformes)
