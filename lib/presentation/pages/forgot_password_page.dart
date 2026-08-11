import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/app_localizations.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final loc = AppLocalizations.of(context);
    try {
      final redirectUrl = 'ticketscan://login-callback';
      await SupabaseService.resetPassword(_emailController.text.trim(), redirectTo: redirectUrl);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(loc?.get('reset_password') ?? 'Réinitialiser le mot de passe'),
            content: Text(
              loc?.get('reset_link_sent') ??
                  'Un lien de réinitialisation a été envoyé à votre adresse email.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // return to auth_page
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotEmailDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc?.get('forgot_email_title') ?? 'Email oublié ?'),
        content: Text(
          loc?.get('forgot_email_content') ?? 'Instructions pour retrouver votre email...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc?.get('cancel') ?? 'Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _contactSupport();
            },
            child: Text(loc?.get('contact_support_button') ?? 'Contacter le support'),
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport() async {
    final String subject = Uri.encodeComponent("[TicketScan] Aide Connexion / Identifiant oublié");
    final String body = Uri.encodeComponent("Bonjour, je n'arrive pas à retrouver mon identifiant TicketScan. Voici mes informations (Nom, justificatif de paiement si Premium, etc.) : ");
    final Uri emailLaunchUri = Uri.parse("mailto:lahcen.boukkoutti@outlook.fr?subject=$subject&body=$body");

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Impossible d\'ouvrir l\'application email';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez envoyer un mail à lahcen.boukkoutti@outlook.fr')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.get('reset_password') ?? 'Réinitialiser le mot de passe'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  loc?.get('reset_password') ?? 'Réinitialiser le mot de passe',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  loc?.get('limit_reached_sub') ??
                      'Entrez votre e-mail pour recevoir un lien de réinitialisation.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  controller: _emailController,
                  label: loc?.get('email') ?? 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre adresse email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                      return 'Veuillez entrer une adresse email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: loc?.get('send_reset_link') ?? 'Envoyer le lien',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: _showForgotEmailDialog,
                    child: Text(
                      loc?.get('forgot_email') ?? 'Identifiant / Email oublié ?',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
