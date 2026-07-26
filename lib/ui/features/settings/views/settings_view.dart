import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_view_model.dart';
import '../../../core/theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _apiKeyController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<AppViewModel>(context, listen: false);
    _apiKeyController = TextEditingController(text: viewModel.apiKey ?? '');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inställningar'),
      ),
      body: Consumer<AppViewModel>(
        builder: (context, viewModel, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Konfiguration',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hantera dina API-nycklar och appdata.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Gemini API Key card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.psychology, color: AppTheme.accentGold, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  'Gemini AI Skanner',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'För att automatiskt läsa av dryckesflaskor och burkar med kameran används Google Gemini AI. Lägg in din egen API-nyckel här. Nyckeln sparas bara lokalt i din webbläsare.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _apiKeyController,
                              obscureText: _obscureKey,
                              decoration: InputDecoration(
                                labelText: 'Gemini API-nyckel',
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
                            const SizedBox(height: 16),
                            if (!viewModel.hasApiKey)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentCyan.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, color: AppTheme.accentCyan, size: 20),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Ingen API-nyckel angiven. Appen körs i Demo-läge och genererar slumpmässig dryckesinformation vid skanning.',
                                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _apiKeyController.clear();
                                      viewModel.deleteApiKey();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('API-nyckel borttagen')),
                                      );
                                    },
                                    child: const Text('Rensa nyckel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: viewModel.isLoading
                                        ? null
                                        : () async {
                                            final messenger = ScaffoldMessenger.of(context);
                                            await viewModel.saveApiKey(_apiKeyController.text);
                                            messenger.showSnackBar(
                                              const SnackBar(content: Text('API-nyckeln har sparats!')),
                                            );
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
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () {
                                // Direct web link to Google AI Studio API Keys page
                                // Note: In Flutter Web, url_launcher is usually used, but we can also use html window if needed.
                                // Since we don't have url_launcher, we can print it or let user copy it.
                              },
                              child: const Text(
                                'Hämta en gratis Gemini API-nyckel från Google AI Studio',
                                style: TextStyle(
                                  color: AppTheme.accentGold,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Backup & Restore Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.backup, color: AppTheme.accentCyan, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  'Spara & Ladda Backup',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Exportera alla dina recensioner till en JSON-fil på din dator för säker lagring, eller ladda in en tidigare sparad backup-fil.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                      side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
                                    ),
                                    onPressed: () => _exportBackup(viewModel),
                                    icon: const Icon(Icons.download, size: 20),
                                    label: const Text('Exportera fil'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                    ),
                                    onPressed: () => _importBackup(viewModel),
                                    icon: const Icon(Icons.upload, size: 20),
                                    label: const Text('Importera fil'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reset Data card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  'Återställ Appdata',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Detta tar bort alla dina rankade drycker och rensar det lokala biblioteket permanent. Denna åtgärd går inte att ångra.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                                side: BorderSide(color: Theme.of(context).colorScheme.error.withOpacity(0.5), width: 1.5),
                              ),
                              onPressed: () => _confirmReset(context, viewModel),
                              child: const Text('Rensa all data'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmReset(BuildContext context, AppViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Är du helt säker?'),
          content: const Text('Detta kommer att radera alla sparade drycker och betyg permanent från din webbläsare.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Avbryt'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: AppTheme.textPrimary,
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                await viewModel.clearDatabase();
                _apiKeyController.clear();
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('All data har raderats.')),
                );
              },
              child: const Text('Ja, radera allt'),
            ),
          ],
        );
      },
    );
  }

  void _exportBackup(AppViewModel viewModel) {
    try {
      final jsonString = viewModel.exportBackupJson();
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      html.AnchorElement(href: url)
        ..setAttribute("download", "dryckesranken_backup_$dateStr.json")
        ..click();

      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup-filen har sparats till din dator!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fel vid export: $e')),
      );
    }
  }

  void _importBackup(AppViewModel viewModel) {
    try {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = '.json';
      uploadInput.click();
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsText(files[0]);
          reader.onLoadEnd.listen((e) {
            final String? resultText = reader.result as String?;
            if (resultText != null) {
              _processImport(viewModel, resultText);
            }
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunde inte läsa filen: $e')),
      );
    }
  }

  void _processImport(AppViewModel viewModel, String jsonString) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final importedCount = await viewModel.importBackupJson(jsonString);
      messenger.showSnackBar(
        SnackBar(content: Text('$importedCount drycker har importerats till ditt lokala bibliotek!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Fel vid import av backup: $e')),
      );
    }
  }
}
