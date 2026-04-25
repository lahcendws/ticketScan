import 'package:flutter/material.dart';
import '../../core/services/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isFr = localizations?.locale.languageCode == 'fr';

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('privacy_policy') ?? 'Confidentialité'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: isFr ? '1. Collecte des données' : '1. Data Collection',
              content: isFr 
                ? 'Nous collectons uniquement les données nécessaires au bon fonctionnement du service : votre adresse email pour votre compte, et les photos des tickets que vous scannez.'
                : 'We only collect data necessary for the proper functioning of the service: your email address for your account, and photos of the receipts you scan.',
            ),
            _buildSection(
              title: isFr ? '2. Utilisation des données' : '2. Data Usage',
              content: isFr 
                ? 'Les photos de vos tickets sont analysées par nos algorithmes de traitement pour extraire les informations de garantie. Ces données sont stockées de manière sécurisée sur nos serveurs Cloud.'
                : 'Photos of your receipts are analyzed by our processing algorithms to extract warranty information. This data is securely stored on our Cloud servers.',
            ),
            _buildSection(
              title: isFr ? '3. Stockage et Sécurité' : '3. Storage and Security',
              content: isFr 
                ? 'Vos données sont hébergées sur des infrastructures sécurisées respectant les standards de l\'industrie. Vos images sont stockées dans un espace privé accessible uniquement par vous.'
                : 'Your data is hosted on secure infrastructures respecting industry standards. Your images are stored in a private space accessible only by you.',
            ),
            _buildSection(
              title: isFr ? '4. Vos Droits (RGPD)' : '4. Your Rights (GDPR)',
              content: isFr 
                ? 'Conformément au RGPD, vous disposez d\'un droit d\'accès, de modification et de suppression de vos données. Vous pouvez supprimer n\'importe quel ticket à tout moment.'
                : 'In accordance with GDPR, you have the right to access, modify, and delete your data. You can delete any receipt at any time.',
            ),
            _buildSection(
              title: isFr ? '5. Suppression du compte' : '5. Account Deletion',
              content: isFr 
                ? 'Vous pouvez demander la suppression définitive de votre compte et de toutes les données associées (emails, tickets, images) directement depuis les paramètres de votre profil. Cette action est irréversible.'
                : 'You can request the permanent deletion of your account and all associated data (emails, receipts, images) directly from your profile settings. This action is irreversible.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                isFr ? 'Dernière mise à jour : Avril 2024' : 'Last updated: April 2024',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
