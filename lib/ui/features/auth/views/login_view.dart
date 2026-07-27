import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_view_model.dart';
import '../../../core/theme.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  Future<void> _handleGoogleLogin(BuildContext context, AppViewModel viewModel) async {
    try {
      await viewModel.signInWithGoogle();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Välkommen, ${viewModel.currentUser!.displayName ?? "inloggad"}!'),
            backgroundColor: AppTheme.ratingGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        String displayError = e.toString();
        if (displayError.contains('unauthorized-domain')) {
          displayError = 'Denna domän är inte godkänd i Firebase Console. Lägg till dryckesranken.vercel.app under Authorized Domains i Authentication-inställningarna.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inloggning misslyckades: $displayError'),
            backgroundColor: AppTheme.ratingRed,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AppViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0x000b0f19), // Match theme background
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
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo & Branding
                  const Icon(
                    Icons.sports_bar,
                    color: AppTheme.accentGold,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DryckesRanken',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      color: AppTheme.textPrimary,
                      shadows: [
                        Shadow(
                          color: Color(0x80FFB020),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ranka, recensera och skanna med AI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Google login card
                  Card(
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Molnsynkronisering',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Spara dina dryckesrankningar i molnet så du kan nå och redigera dem från vilken mobil eller dator som helst.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(52),
                              elevation: 2,
                            ),
                            onPressed: viewModel.isLoading
                                ? null
                                : () => _handleGoogleLogin(context, viewModel),
                            icon: viewModel.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                    height: 20,
                                    width: 20,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.login),
                                  ),
                            label: const Text(
                              'Logga in med Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Offline mode card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Kör offline lokalt',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Datan sparas då endast lokalt i din nuvarande webbläsare. Varning: Din data kan försvinna om du byter enhet eller rensar cache.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
                            ),
                            onPressed: () {
                              viewModel.setOfflineMode(true);
                            },
                            child: const Text(
                              'Fortsätt utan konto',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
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
