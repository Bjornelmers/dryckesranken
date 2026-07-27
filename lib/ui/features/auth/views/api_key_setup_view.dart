import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_view_model.dart';
import '../../../core/theme.dart';

class ApiKeySetupView extends StatefulWidget {
  const ApiKeySetupView({super.key});

  @override
  State<ApiKeySetupView> createState() => _ApiKeySetupViewState();
}

class _ApiKeySetupViewState extends State<ApiKeySetupView> {
  late TextEditingController _apiKeyController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AppViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF0B0F19),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon header
                  const Icon(
                    Icons.psychology,
                    color: AppTheme.accentGold,
                    size: 70,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aktivera AI-Skanner',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Skanna med Google Gemini AI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'För att kunna fotografera och automatiskt identifiera dryckesetiketter behöver du lägga in din egen kostnadsfria Gemini API-nyckel. Nyckeln sparas säkert och lokalt i din egen webbläsare.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _apiKeyController,
                            obscureText: _obscureKey,
                            decoration: InputDecoration(
                              labelText: 'Ange Gemini API-nyckel',
                              hintText: 'AIzaSy...',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureKey ? Icons.visibility : Icons.visibility_off,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureKey = !_obscureKey;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
                                  ),
                                  onPressed: () {
                                    viewModel.skipApiKeySetup();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Appen körs nu i demo-läge (slumpad dryckesdata).'),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Hoppa över',
                                    style: TextStyle(color: AppTheme.textPrimary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  onPressed: viewModel.isLoading
                                      ? null
                                      : () async {
                                          final text = _apiKeyController.text.trim();
                                          if (text.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Vänligen fyll i en API-nyckel eller välj Hoppa över.'),
                                                backgroundColor: AppTheme.ratingRed,
                                              ),
                                            );
                                            return;
                                          }
                                          await viewModel.saveApiKey(text);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('API-nyckel sparad! Skannern är nu aktiv.'),
                                                backgroundColor: AppTheme.ratingGreen,
                                              ),
                                            );
                                          }
                                        },
                                  child: viewModel.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Spara nyckel'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: () {
                              // We open Google AI Studio in a new tab
                              // Since we don't have url_launcher, we can print it or let user copy it.
                            },
                            child: const Text(
                              'Hämta en gratis Gemini API-nyckel från Google AI Studio',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.accentGold,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
