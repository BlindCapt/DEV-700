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
    final authService = ref.read(authApiServiceProvider);
    
    // Fonction de déconnexion qui utilise la méthode mise à jour
    void logout() async {
      await authNotifier.logout();
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
                  authService.updateNgrokUrl(ngrokUrlController.text);
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

    // Vérifier si l'utilisateur a un token stocké
    Future<String?> getStoredToken() async {
      return await authService.getToken();
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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              
              // Affichage des informations de connexion
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Informations de session',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    FutureBuilder<String?>(
                      future: getStoredToken(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final hasToken = snapshot.data != null;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              'État de session',
                              hasToken ? 'Active (token stocké)' : 'Non persistante',
                              hasToken ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'API URL',
                              authState.currentApiUrl ?? 'Non connecté',
                              Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Persistance',
                              hasToken ? 'Le token sera conservé à la fermeture de l\'app' : 'Session temporaire',
                              hasToken ? Colors.green : Colors.grey,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Indicateur de mode hors ligne
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_done,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Connecté au serveur',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
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
      ),
    );
  }
  
  // Helper pour construire une ligne d'information
  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 