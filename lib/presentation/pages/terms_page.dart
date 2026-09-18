import 'package:flutter/material.dart';
import '../../core/services/app_localizations.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isFr = localizations?.locale.languageCode == 'fr';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations?.get('terms_of_service') ?? "Conditions d'utilisation",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: isFr ? '1. Objet' : '1. Purpose',
              content: isFr
                  ? 'Les présentes conditions régissent l\'utilisation de l\'application TicketScan, qui vous permet de numériser, stocker et gérer vos tickets de caisse et leurs garanties.'
                  : 'These terms govern the use of the TicketScan app, which allows you to scan, store and manage your receipts and their warranties.',
            ),
            _buildSection(
              title: isFr ? '2. Compte utilisateur' : '2. User Account',
              content: isFr
                  ? 'L\'accès au service nécessite la création d\'un compte avec une adresse email valide. Vous êtes responsable de la confidentialité de vos identifiants et de l\'exactitude des informations fournies.'
                  : 'Access to the service requires creating an account with a valid email address. You are responsible for keeping your credentials confidential and for the accuracy of the information you provide.',
            ),
            _buildSection(
              title: isFr ? '3. Abonnement Premium' : '3. Premium Subscription',
              content: isFr
                  ? 'L\'offre Premium est proposée par abonnement mensuel ou annuel. Vous pouvez gérer ou résilier votre abonnement à tout moment depuis votre compte ; la résiliation prend effet à la fin de la période en cours.'
                  : 'The Premium offer is available as a monthly or yearly subscription. You can manage or cancel your subscription at any time from your account; cancellation takes effect at the end of the current period.',
            ),
            _buildSection(
              title: isFr
                  ? '4. Utilisation du service'
                  : '4. Use of the Service',
              content: isFr
                  ? 'Vous vous engagez à utiliser TicketScan uniquement à des fins personnelles et licites. Il est interdit de tenter d\'accéder aux données d\'autres utilisateurs ou de perturber le fonctionnement du service.'
                  : 'You agree to use TicketScan for personal and lawful purposes only. Attempting to access other users\' data or disrupt the service is prohibited.',
            ),
            _buildSection(
              title: isFr
                  ? '5. Responsabilité et résiliation du compte'
                  : '5. Liability and Account Termination',
              content: isFr
                  ? 'TicketScan est fourni « en l\'état » sans garantie de résultat. Nous nous réservons le droit de suspendre un compte en cas de non-respect des présentes conditions. Vous pouvez supprimer votre compte à tout moment depuis les paramètres de votre profil.'
                  : 'TicketScan is provided "as is" without warranty of outcome. We reserve the right to suspend an account in case of breach of these terms. You can delete your account at any time from your profile settings.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                isFr
                    ? 'Dernière mise à jour : Avril 2024'
                    : 'Last updated: April 2024',
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
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
