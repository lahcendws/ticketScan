import 'package:flutter/material.dart';
import '../../core/services/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isFr = loc?.locale.languageCode == 'fr';

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.get('privacy_policy') ?? 'Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: isFr ? '1. Collecte des données' : '1. Data Collection',
              content: isFr 
                ? 'Nous collectons uniquement votre email pour la gestion de votre compte et les photos de tickets que vous choisissez de numériser.' 
                : 'We only collect your email for account management and the ticket photos you choose to digitize.',
            ),
            _buildSection(
              title: isFr ? '2. Traitement des informations' : '2. Data Processing',
              content: isFr 
                ? 'Les images sont traitées par nos algorithmes de reconnaissance de texte afin d\'extraire automatiquement les dates et garanties.' 
                : 'Images are processed by our text recognition algorithms to automatically extract dates and warranties.',
            ),
            _buildSection(
              title: isFr ? '3. Sécurité et Stockage' : '3. Security and Storage',
              content: isFr 
                ? 'Vos données sont stockées sur des serveurs sécurisés et cryptés. Vos photos sont privées et accessibles uniquement via votre compte.' 
                : 'Your data is stored on secure, encrypted servers. Your photos are private and accessible only through your account.',
            ),
            _buildSection(
              title: isFr ? '4. Vos Droits' : '4. Your Rights',
              content: isFr 
                ? 'Conformément aux lois sur la protection des données, vous pouvez supprimer vos tickets ou votre compte intégralement à tout moment.' 
                : 'In accordance with data protection laws, you can delete your tickets or your entire account at any time.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'TicketScan - 2024',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
