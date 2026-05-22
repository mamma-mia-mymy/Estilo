import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'router.dart';

// Web Firebase configuration
// Note: For production, add your web app in Firebase Console and use those values
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDmmNR96kwlvC4nMVyh1Ke09k845HpSiJM",
        authDomain: "ternova-b502c.firebaseapp.com",
        projectId: "ternova-b502c",
        storageBucket: "ternova-b502c.firebasestorage.app",
        messagingSenderId: "1040357558256",
        appId: "1:1040357558256:web:45deca37b17930e86b3f35"
      ),
    );
  } catch (e) {
    // If Firebase initialization fails (e.g., config mismatch), continue without it
    print('Firebase initialization warning: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await _initializeFirebase();
  
  runApp(const ProviderScope(child: EstiloApp()));
}

class EstiloApp extends ConsumerWidget {
  const EstiloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Estilo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1814),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFC8C4BE),
      ),
      routerConfig: router,
    );
  }
}
