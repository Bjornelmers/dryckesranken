import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/services/storage_service.dart';
import 'data/services/gemini_service.dart';
import 'ui/core/theme.dart';
import 'ui/features/app_view_model.dart';
import 'ui/features/dashboard/views/dashboard_view.dart';
import 'ui/features/auth/views/login_view.dart';
import 'ui/features/auth/views/api_key_setup_view.dart';

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
      home: const AppHomeSelector(),
    );
  }
}

class AppHomeSelector extends StatelessWidget {
  const AppHomeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            ),
          );
        }

        // Redirect to LoginView if not logged in AND not opted for offline local mode
        if (!viewModel.isLoggedIn && !viewModel.useOfflineMode) {
          return const LoginView();
        }

        // Redirect to ApiKeySetupView if no API Key is saved and setup hasn't been skipped
        if (!viewModel.hasApiKey && !viewModel.skippedApiKeySetup) {
          return const ApiKeySetupView();
        }

        return const DashboardView();
      },
    );
  }
}
