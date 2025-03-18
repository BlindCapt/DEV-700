import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/features/auth/data/api/auth_api_service.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    
    void logout() {
      ref.read(authProvider.notifier).logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
    
    // Fonction pour afficher la boîte de dialogue de mise à jour d'URL ngrok
    void _showNgrokUpdateDialog() {
      final TextEditingController ngrokUrlController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mettre à jour l\'URL ngrok'),
          content: TextField(
            controller: ngrokUrlController,
            decoration: const InputDecoration(
              labelText: 'Nouvelle URL ngrok',
              hintText: 'https://votre-url.ngrok.io'
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                if (ngrokUrlController.text.isNotEmpty) {
                  // Mise à jour de l'URL
                  AuthApiService().updateNgrokUrl(ngrokUrlController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('URL ngrok mise à jour: ${ngrokUrlController.text}'))
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DEV-700 Mobile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Déconnexion',
          ),
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Configurer URL ngrok',
            onPressed: _showNgrokUpdateDialog,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Connexion réussie !',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bienvenue, ${authState.user?.firstName} ${authState.user?.lastName}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            
            // Indicateur de mode hors ligne
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: authState.isOfflineMode 
                    ? Colors.orange.withOpacity(0.2) 
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        authState.isOfflineMode ? Icons.cloud_off : Icons.cloud_done,
                        color: authState.isOfflineMode ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        authState.isOfflineMode 
                            ? 'Mode hors ligne activé' 
                            : 'Connecté au serveur',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: authState.isOfflineMode ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: authState.isOfflineMode,
                    activeColor: Colors.orange,
                    onChanged: (value) {
                      ref.read(authProvider.notifier).toggleOfflineMode(value);
                    },
                  ),
                ],
              ),
            ),
            
            // Contenu supplémentaire
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Cette application est en cours de développement',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité à venir !'),
                            ),
                          );
                        },
                        child: const Text('Explorer l\'application'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 