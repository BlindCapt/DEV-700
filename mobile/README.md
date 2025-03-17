# DEV-700 Mobile

Application mobile pour le projet DEV-700, permettant la gestion des produits et le paiement via PayPal.

## Architecture du projet

Le projet est organisé selon une architecture modulaire et évolutive :

```
lib/
  ├── core/                # Composants fondamentaux
  │   ├── constants/       # Constantes de l'application
  │   ├── theme/           # Thèmes et styles
  │   ├── utils/           # Utilitaires
  │   └── widgets/         # Widgets réutilisables
  │
  ├── features/            # Fonctionnalités (architecture par domaine)
  │   ├── auth/            # Authentification
  │   │   ├── data/        # Sources de données
  │   │   ├── domain/      # Logique métier et modèles
  │   │   └── presentation/# UI (écrans, widgets, etc.)
  │   │
  │   ├── cart/            # Gestion du panier
  │   │   ├── data/
  │   │   ├── domain/
  │   │   └── presentation/
  │   │
  │   ├── payment/         # Paiements
  │   │   ├── data/
  │   │   ├── domain/
  │   │   └── presentation/
  │   │
  │   ├── products/        # Gestion des produits
  │   │   ├── data/
  │   │   ├── domain/
  │   │   └── presentation/
  │   │
  │   └── profile/         # Profil utilisateur
  │       ├── data/
  │       ├── domain/
  │       └── presentation/
  │
  ├── providers/           # Providers Riverpod
  │
  └── services/            # Services partagés (API, etc.)
```

## Technologies utilisées

- **Flutter**: Framework pour le développement d'applications multi-plateformes
- **Riverpod**: Gestion d'état réactive
- **Flutter Hooks**: Simplification de la gestion d'état local
- **Hive**: Base de données NoSQL locale pour le stockage du panier
- **Flutter PayPal**: Intégration des paiements PayPal
- **Dio**: Client HTTP pour les requêtes API

## Commandes d'installation

Pour initialiser le projet :

```bash
# Créer le projet Flutter
flutter create --org com.yourcompany mobile

# Naviguer vers le dossier du projet
cd mobile

# Installer les dépendances
flutter pub add flutter_riverpod hooks_riverpod flutter_hooks
flutter pub add hive hive_flutter path_provider
flutter pub add flutter_paypal_checkout dio
flutter pub add flutter_lints
```

## Configuration Hive

Pour utiliser Hive avec des classes personnalisées, il faut générer des adaptateurs. Après avoir annoté vos modèles avec `@HiveType` et `@HiveField`, exécutez :

```bash
# Ajouter les dépendances de développement
flutter pub add --dev build_runner hive_generator

# Générer les adaptateurs
flutter pub run build_runner build
```

## Démarrage de l'application

```bash
flutter run
```

## Architecture des fonctionnalités

Chaque fonctionnalité suit une architecture en couches :

- **Data**: Repositories, sources de données, DTOs
- **Domain**: Modèles, entités, cas d'utilisation
- **Presentation**: Pages, widgets, contrôleurs d'état

Cette séparation favorise la testabilité et la maintenabilité du code.

## État du projet

Ce projet est initialisé avec une architecture modulaire et des outils modernes, prêt pour l'implémentation des fonctionnalités spécifiques.
