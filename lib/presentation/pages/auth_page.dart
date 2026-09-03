import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/app_localizations.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'home_page.dart';
import 'privacy_policy_page.dart'; // Import ajouté
import 'forgot_password_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _showForgotEmailDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc?.get('forgot_email_title') ?? 'Email oublié ?'),
        content: Text(
          loc?.get('forgot_email_content') ??
              'Instructions pour retrouver votre email...',
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
            child: Text(
              loc?.get('contact_support_button') ?? 'Contacter le support',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport() async {
    final String subject = Uri.encodeComponent(
      "[TicketScan] Aide Connexion / Identifiant oublié",
    );
    final String body = Uri.encodeComponent(
      "Bonjour, je n'arrive pas à retrouver mon identifiant TicketScan. Voici mes informations (Nom, justificatif de paiement si Premium, etc.) : ",
    );
    final Uri emailLaunchUri = Uri.parse(
      "mailto:ticketscan1.help@outlook.froutlook.fr?subject=$subject&body=$body",
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Impossible d\'ouvrir l\'application email';
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez envoyer un mail à ticketscan1.help@outlook.froutlook.fr',
            ),
          ),
        );
    }
  }

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _mapAuthError(String errorMessage, AppLocalizations? loc) {
    final msg = errorMessage.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return loc?.get('error_invalid_credentials') ??
          'Email ou mot de passe incorrect.';
    }
    if (msg.contains('email not confirmed') ||
        msg.contains('email_not_confirmed')) {
      return loc?.get('error_email_not_confirmed') ??
          'Votre email n\'a pas été confirmé.';
    }
    if (msg.contains('user not found') || msg.contains('user_not_found')) {
      return loc?.get('error_user_not_found') ??
          'Aucun compte trouvé avec cette adresse.';
    }
    if (msg.contains('weak password') || msg.contains('weak_password')) {
      return loc?.get('error_weak_password') ??
          'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (msg.contains('already registered') ||
        msg.contains('user_already_exists') ||
        msg.contains('already been registered')) {
      return loc?.get('error_email_taken') ??
          'Un compte existe déjà avec cette adresse.';
    }
    if (msg.contains('rate limit') ||
        msg.contains('too many requests') ||
        msg.contains('over_request_rate_limit')) {
      return loc?.get('error_too_many_requests') ??
          'Trop de tentatives. Veuillez patienter.';
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection')) {
      return loc?.get('error_network') ?? 'Erreur de connexion réseau.';
    }
    return loc?.get('error_generic') ?? 'Une erreur est survenue.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final loc = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        final response = await SupabaseService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (response.session != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else if (mounted) {
          _showInfoDialog(
            title:
                loc?.get('success_email_not_confirmed_title') ??
                'Email non confirmé',
            message:
                loc?.get('success_email_not_confirmed_msg') ??
                'Veuillez vérifier votre boîte mail.',
          );
        }
      } else {
        await SupabaseService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          _showInfoDialog(
            title: loc?.get('success_account_created_title') ?? 'Compte créé !',
            message:
                loc?.get('success_account_created_msg') ??
                'Un email de confirmation vous a été envoyé.',
            onConfirm: () => setState(() => _isLogin = true),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorTitle = _isLogin
            ? (loc?.get('error_title') ?? 'Erreur de connexion')
            : (loc?.get('error_signup_title') ?? 'Erreur d\'inscription');
        _showErrorDialog(
          title: errorTitle,
          message: _mapAuthError(e.toString(), loc),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showInfoDialog({
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.check_circle_outline,
          color: Colors.green.shade600,
          size: 48,
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(AppLocalizations.of(context)?.get('ok') ?? 'OK'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(AppLocalizations.of(context)?.get('ok') ?? 'OK'),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAuthMode() {
    setState(() => _isLogin = !_isLogin);
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // Logo
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'TicketScan',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      CustomTextField(
                        controller: _emailController,
                        label: loc?.get('email') ?? 'Email',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        label: loc?.get('password') ?? 'Mot de passe',
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: _isLogin
                            ? (loc?.get('sign_in') ?? 'Se connecter')
                            : (loc?.get('sign_up') ?? 'S\'inscrire'),
                        onPressed: _submit,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: _toggleAuthMode,
                          child: Text(
                            _isLogin
                                ? 'Pas encore de compte ? S\'inscrire'
                                : 'Déjà un compte ? Se connecter',
                          ),
                        ),
                      ),
                      if (_isLogin) ...[
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordPage(),
                              ),
                            ),
                            child: Text(
                              loc?.get('forgot_password') ??
                                  'Mot de passe oublié ?',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                      // LIEN LÉGAL OBLIGATOIRE
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyPage(),
                            ),
                          ),
                          child: Text(
                            loc?.get('privacy_policy') ??
                                'Politique de confidentialité',
                            style: const TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
