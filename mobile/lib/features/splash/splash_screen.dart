import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Vérifier l'authentification après l'initialisation du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  Future<void> _checkAuthentication() async {
    debugPrint('==== DÉBUT _checkAuthentication() ====');
    // Attendre un court instant pour que l'écran de démarrage soit affiché
    await Future.delayed(const Duration(seconds: 2));
    
    // IMPORTANT: Attendre explicitement que la vérification du token soit terminée
    final authNotifier = ref.read(authProvider.notifier);
    
    // Attendre que la restauration de la session soit terminée
    debugPrint('Appel de restoreUserSession() depuis SplashScreen');
    await authNotifier.restoreUserSession();
    
    // Vérifier l'état d'authentification après la restauration
    final authState = ref.read(authProvider);
    debugPrint('État d\'authentification après restauration: ${authState.isAuthenticated}');
    
    if (authState.isAuthenticated) {
      // Si l'utilisateur est authentifié, rediriger vers l'écran d'accueil
      debugPrint('Utilisateur authentifié, redirection vers /home');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      // Sinon, rediriger vers l'écran de connexion
      debugPrint('Utilisateur non authentifié, redirection vers /login');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
    debugPrint('==== FIN _checkAuthentication() ====');
  }

  @override
  Widget build(BuildContext context) {
    // Observer l'état d'authentification
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou nom de l'application
              Icon(
                Icons.shopping_cart,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                'DEV-700 Mobile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              // Indicateur de chargement
              if (authState.isLoading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              const SizedBox(height: 20),
              // Message de statut
              Text(
                authState.isLoading 
                    ? 'Vérification de la session...'
                    : 'Bienvenue !',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 