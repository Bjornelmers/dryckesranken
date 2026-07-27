import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/services/storage_service.dart';
import 'data/services/gemini_service.dart';
import 'ui/core/theme.dart';
import 'ui/features/app_view_model.dart';
import 'ui/features/dashboard/views/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final storageService = StorageService();
  final geminiService = GeminiService();
  
  final viewModel = AppViewModel(storageService, geminiService);
  
  // Initialize Hive and settings
  await viewModel.init();

  runApp(
    ChangeNotifierProvider<AppViewModel>.value(
      value: viewModel,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DryckesRanken',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardView(),
    );
  }
}
