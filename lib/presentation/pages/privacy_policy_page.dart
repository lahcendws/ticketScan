import 'package:flutter/material.dart';
import '../../core/services/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

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
              title: '1. Collecte des données',
              content: 'Nous collectons uniquement les données nécessaires au bon fonctionnement du service : votre adresse email pour votre compte, et les photos des tickets que vous scannez.',
            ),
            _buildSection(
              title: '2. Utilisation des données',
              content: 'Les photos de vos tickets sont analysées par une intelligence artificielle (OpenAI) pour extraire les informations de garantie. Ces données sont stockées de manière sécurisée sur nos serveurs Cloud (Supabase).',
            ),
            _buildSection(
              title: '3. Stockage et Sécurité',
              content: 'Vos données sont hébergées sur Supabase, une plateforme sécurisée respectant les standards de l\'industrie. Vos images sont stockées dans un espace privé accessible uniquement par vous.',
            ),
            _buildSection(
              title: '4. Vos Droits (RGPD)',
              content: 'Conformément au RGPD, vous disposez d\'un droit d\'accès, de modification et de suppression de vos données. Vous pouvez supprimer n\'importe quel ticket à tout moment.',
            ),
            _buildSection(
              title: '5. Suppression du compte',
              content: 'Vous pouvez demander la suppression définitive de votre compte et de toutes les données associées (emails, tickets, images) directement depuis les paramètres de votre profil. Cette action est irréversible.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Dernière mise à jour : Avril 2024',
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
