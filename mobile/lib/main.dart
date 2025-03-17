import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de Hive pour le stockage local
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDirectory.path);
  
  // Ouvrir les boîtes Hive
  try {
    await Hive.openBox(AppConstants.cartBoxName);
    await Hive.openBox(AppConstants.userBoxName);
    await Hive.openBox(AppConstants.settingsBoxName);
    debugPrint('Hive boxes initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Hive boxes: $e');
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DEV-700 Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(), // Thème clair
      darkTheme: AppTheme.darkTheme(), // Thème sombre
      themeMode: ThemeMode.dark, // Forcer le thème sombre
      initialRoute: '/login', // Route initiale
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DEV-700 Mobile'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Projet initialisé avec succès!\nArchitecture modulaire mise en place.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('L\'application fonctionne correctement sur votre appareil!'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('Tester l\'application'),
            ),
          ],
        ),
      ),
    );
  }
}
